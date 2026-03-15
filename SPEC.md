# Umami Specification

## Status

Draft 0.1

## Reference Source

This SDK is specified against the upstream Umami source checked in as a git submodule at `refs/umami`.

- Upstream repository: `https://github.com/umami-software/umami`
- Submodule path: `refs/umami`
- Observed upstream branch: `master`
- Observed upstream commit: `0a838649b773122cc68cbd0c3df78d4251b981c5`
- Observed upstream commit date: `2026-03-04`

The upstream source is the canonical reference for request shapes, auth behavior, and route inventory because Umami does not expose a complete OpenAPI specification in-repo.

## Problem

We want a Swift SDK for Umami that can:

- talk to the authenticated Umami REST API for account, website, and analytics access
- eventually send tracking and identity events from Apple apps to Umami ingestion endpoints
- stay aligned with upstream route behavior without guessing from incomplete public docs

## Goals

- Ship as a Swift Package Manager package.
- Use native Swift concurrency (`async`/`await`) as the primary API.
- Support typed access to the most important Umami API areas first.
- Keep a raw request escape hatch for upstream endpoints not yet modeled.
- Separate management API concerns from tracking concerns.
- Make auth explicit: bearer token auth and share token auth are distinct modes.
- Optimize first for Apple app code, especially an iOS/macOS dashboard client.

## Non-Goals

- Mirror every upstream route in the first implementation.
- Reproduce the JavaScript tracker feature-for-feature in v1.
- Implement cookie or browser session behavior exactly as a web tracker does.
- Depend on generated code from OpenAPI.
- Hide upstream inconsistencies in HTTP semantics. If Umami uses `POST` for update routes, the SDK should model that honestly.

## Upstream API Observations

Based on `refs/umami/src/app/api`:

- Most API routes require `Authorization: Bearer <token>`.
- Shared website access uses `x-umami-share-token`.
- Auth starts with `POST /api/auth/login`.
- Token verification is `POST /api/auth/verify`.
- Logout is `POST /api/auth/logout`.
- Tracking ingestion is split across:
  - `POST /api/send`
  - `POST /api/batch`
- Tracking responses return a cache token that should be sent back via `x-umami-cache`.
- The API error envelope is consistently JSON shaped as:
  - `{"error":{"message": "...", "code": "...", "status": 400}}`
- Date handling is mixed:
  - many analytics reads use query params such as `startAt` and `endAt` in epoch milliseconds
  - report payloads use JSON date fields parsed as dates by the server
- The route surface is broad and includes:
  - auth and account
  - websites
  - analytics reads
  - reports
  - teams
  - users
  - links
  - pixels
  - admin-only endpoints

## Product Shape

The package should expose two primary SDK surfaces:

1. `UmamiAPI`
   A typed client for authenticated REST API access. This is the primary v1 surface and the first implementation priority.

2. `UmamiTracker`
   A client for event and identity ingestion against `/api/send` and `/api/batch`. This is intentionally the last implementation phase.

Both should share a transport and model core:

- `UmamiCore`
  - HTTP transport
  - configuration
  - auth state
  - request building
  - error mapping
  - shared model primitives

## Initial Package Layout

```text
Package.swift
Sources/
  UmamiCore/
  UmamiAPI/
  UmamiTracker/
Tests/
  UmamiCoreTests/
  UmamiAPITests/
  UmamiTrackerTests/
refs/
  umami/   # upstream submodule
```

## Supported Platforms

Initial target assumption:

- Swift 6 mode
- iOS 15+
- macOS 12+
- tvOS 15+
- watchOS 8+
- visionOS 1+

Rationale:

- `async`/`await` is a hard requirement for the public API.
- Foundation-based networking fits the Apple-only target well.
- Initial support is explicitly limited to Apple platforms.
- Linux and other non-Apple platforms are out of scope for the first public release.

## Configuration

```swift
public struct UmamiConfiguration: Sendable {
    public var baseURL: URL
    public var session: URLSession
    public var jsonEncoder: JSONEncoder
    public var jsonDecoder: JSONDecoder
    public var userAgent: String?
}
```

Defaults:

- `baseURL` is the root Umami origin, for example `https://analytics.example.com`
- requests build paths relative to `baseURL`
- JSON decoder should tolerate snake_case payloads where needed, but model coding keys should be explicit instead of relying on global magic

## Authentication Model

We should model auth explicitly rather than hide it in ambient state.

```swift
public enum UmamiAuth: Sendable {
    case none
    case bearerToken(String)
    case shareToken(String)
}
```

Rules:

- `bearerToken` maps to `Authorization: Bearer <token>`
- `shareToken` maps to `x-umami-share-token: <token>`
- some endpoints are unauthenticated (`/api/config`, `/api/heartbeat`, `/api/send`, `/api/batch`, `/api/share/{shareId}`)
- `UmamiAPI` should reject tracker-only endpoints at the type layer where practical

## Core Transport

`UmamiCore` should provide:

- a request builder that knows how to encode:
  - query items
  - JSON bodies
  - headers
- a response pipeline that:
  - validates status codes
  - decodes typed success payloads
  - decodes Umami error payloads
  - returns raw data when callers opt into untyped access

Suggested types:

```swift
public protocol UmamiTransport: Sendable {
    func send<Value: Decodable>(_ request: UmamiRequest<Value>) async throws -> Value
    func send(_ request: UmamiRawRequest) async throws -> UmamiRawResponse
}
```

## Error Model

```swift
public struct UmamiAPIErrorEnvelope: Decodable, Sendable {
    public let error: UmamiAPIErrorBody
}

public struct UmamiAPIErrorBody: Decodable, Error, Sendable {
    public let message: String
    public let code: String
    public let status: Int
}
```

SDK-specific wrapper errors:

- invalid base URL
- request encoding failure
- response decoding failure
- transport failure
- API error envelope
- unexpected empty response

## Public API Surface

### `UmamiAPI`

Proposed entry point:

```swift
public struct UmamiAPIClient: Sendable {
    public init(configuration: UmamiConfiguration, auth: UmamiAuth = .none)

    public var auth: AuthAPI { get }
    public var system: SystemAPI { get }
    public var account: AccountAPI { get }
    public var websites: WebsitesAPI { get }
    public var analytics: AnalyticsAPI { get }
    public var raw: RawAPI { get }
}
```

### `UmamiTracker`

Proposed entry point:

```swift
public actor UmamiTrackerClient {
    public init(configuration: UmamiConfiguration)

    public func track(_ event: TrackEventRequest) async throws -> TrackEventResponse
    public func identify(_ request: IdentifyRequest) async throws -> TrackEventResponse
    public func flush(_ requests: [TrackingEnvelope]) async throws -> BatchTrackResponse
}
```

The tracker should own the upstream cache token returned from `/api/send` and `/api/batch`, and replay it through `x-umami-cache`.

## MVP Scope

The first implementation should be intentionally smaller than the full upstream route inventory and should prioritize the API surface needed to build an iOS/macOS dashboard app.

### Phase 1: Foundation

- `UmamiCore`
- request/response pipeline
- auth header injection
- error decoding
- raw request escape hatch
- date/query encoding helpers

### Phase 2: Auth and Account

Supported endpoints:

- `POST /api/auth/login`
- `POST /api/auth/verify`
- `POST /api/auth/logout`
- `GET /api/me`
- `POST /api/me/password`
- `GET /api/config`
- `GET /api/heartbeat`
- `GET /api/share/{shareId}`

Public capabilities:

- login with username/password and get token + user payload
- verify an existing bearer token
- logout
- fetch current auth/account context
- change current user password
- fetch server config
- fetch share token for a website share ID

### Phase 3: Website Management

Supported endpoints:

- `GET /api/websites`
- `POST /api/websites`
- `GET /api/websites/{websiteId}`
- `POST /api/websites/{websiteId}`
- `DELETE /api/websites/{websiteId}`

Public capabilities:

- list websites
- create website
- fetch website
- update website name/domain/share ID
- delete website

### Phase 4: Analytics Reads

Supported endpoints:

- `GET /api/realtime/{websiteId}`
- `GET /api/websites/{websiteId}/stats`
- `GET /api/websites/{websiteId}/metrics`
- `GET /api/websites/{websiteId}/metrics/expanded`
- `GET /api/websites/{websiteId}/pageviews`
- `GET /api/websites/{websiteId}/events`
- `GET /api/websites/{websiteId}/events/series`
- `GET /api/websites/{websiteId}/sessions`
- `GET /api/websites/{websiteId}/sessions/stats`
- `GET /api/websites/{websiteId}/sessions/weekly`
- `GET /api/websites/{websiteId}/sessions/{sessionId}`
- `GET /api/websites/{websiteId}/sessions/{sessionId}/activity`
- `GET /api/websites/{websiteId}/sessions/{sessionId}/properties`
- `GET /api/websites/{websiteId}/values`
- `GET /api/websites/{websiteId}/daterange`

Phase 4A event/session metadata:

- `GET /api/websites/{websiteId}/event-data/stats`
- `GET /api/websites/{websiteId}/event-data/events`
- `GET /api/websites/{websiteId}/event-data/fields`
- `GET /api/websites/{websiteId}/event-data/properties`
- `GET /api/websites/{websiteId}/event-data/values`
- `GET /api/websites/{websiteId}/event-data/{eventId}`
- `GET /api/websites/{websiteId}/session-data/properties`
- `GET /api/websites/{websiteId}/session-data/values`

Public capabilities:

- retrieve overview stats
- query metrics by supported dimension type
- enumerate sessions and events
- inspect session detail and activity
- enumerate filter values used by the dashboard UI
- inspect event and session property catalogs

This phase is the main product goal for the first release.

### Phase 5: Tracking

Supported endpoints:

- `POST /api/send`
- `POST /api/batch`

Public capabilities:

- send pageview-like events
- send custom events
- send identify payloads
- batch multiple tracking payloads
- manage upstream cache token

The SDK should not attempt to auto-derive browser metadata that only makes sense on the web. Instead, the public tracking models should expose optional fields and let callers provide app-relevant values.

Tracking is explicitly the last implementation step, after the dashboard-focused API client is stable.

## Deferred Scope

These areas exist upstream but should not block the initial SDK:

- teams
- team membership management
- links
- pixels
- users and admin users
- admin website listing
- saved report CRUD
- advanced report execution endpoints
- website reset/transfer/export
- SSO auth

Reason:

- the route surface is large
- several response shapes need route-by-route study
- the first implementation should validate the transport, model, and auth architecture before expanding coverage

## Raw API Escape Hatch

Because upstream evolves quickly, the SDK needs a typed core and an untyped fallback.

```swift
public struct RawAPI: Sendable {
    public func get(path: String, query: [URLQueryItem] = []) async throws -> UmamiRawResponse
    public func post<Body: Encodable>(path: String, body: Body) async throws -> UmamiRawResponse
    public func delete(path: String) async throws -> UmamiRawResponse
}
```

This is important for:

- early adopters of upstream endpoints not yet modeled
- comparing typed SDK calls against live server behavior
- reducing pressure to over-model every route before the package is useful

## Modeling Strategy

Principles:

- Prefer small, route-scoped request and response types.
- Avoid giant umbrella DTOs that try to represent every analytics payload.
- Make enums for server-known constrained values when stable:
  - report type
  - metric type
  - tracker event type
  - user role
- Preserve unknown fields with additive evolution in mind when it materially helps compatibility.

Specific concern:

Upstream analytics endpoints often return dashboard-oriented payloads whose shape varies by route. We should model them individually rather than forcing them into a single generic chart protocol on day one.

## Query and Date Encoding

We need explicit helpers because Umami mixes query and JSON date styles.

Requirements:

- analytics date range helpers must support:
  - `startAt`
  - `endAt`
  - `startDate`
  - `endDate`
  - `timezone`
  - `unit`
  - `compare`
- epoch timestamps in query strings should be encoded in milliseconds
- JSON date fields used in report-style payloads should use a documented encoder strategy and be tested against a live Umami instance

The implementation should not assume one global date encoding policy for all routes.

## Concurrency and Thread Safety

- `UmamiAPIClient` should be `Sendable`.
- `UmamiTrackerClient` should be an `actor`.
- Mutable auth state should not be hidden behind unsynchronized globals.
- If we later add token refresh or persistent tracker storage, those flows must stay actor-isolated.

## Testing Strategy

The implementation phase should include:

- unit tests for request construction
- unit tests for auth header injection
- unit tests for error decoding
- fixture-based decoding tests for each typed route
- integration tests against a local Umami instance, gated behind environment variables

Suggested integration setup later:

- boot Umami via Docker Compose from the upstream submodule or an SDK-local fixture
- seed a test user and website
- run authenticated API smoke tests
- run tracking ingestion smoke tests after the tracker phase begins

## Versioning Strategy

- SDK semantic versioning should reflect the Swift package surface, not upstream Umami version numbers.
- We should record the upstream commit used for validation in release notes.
- Minor SDK releases may add new upstream endpoint coverage.
- Breaking changes in upstream payloads should be handled conservatively and documented with the upstream commit that triggered the change.

## Decisions

- The package name is `Umami`.
- The first product target is an Apple-platform dashboard client, centered on iOS and macOS.
- Initial platform support is Apple-only.
- Tracking support is part of the SDK plan, but it comes after the dashboard API client is implemented.
- Do we want report execution in the initial release, or only the core analytics endpoints listed above?

## Recommended Implementation Order

1. Create `Package.swift` and module skeletons.
2. Implement `UmamiCore` transport, auth, and error handling.
3. Implement auth/account endpoints.
4. Implement website CRUD.
5. Implement a small analytics slice (`stats`, `metrics`, `sessions`, `events`).
6. Implement tracker `/api/send` and `/api/batch`.
7. Add integration tests against a local Umami instance.
8. Expand endpoint coverage after the architecture proves out.
