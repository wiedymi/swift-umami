# Umami

[![GitHub](https://img.shields.io/badge/-GitHub-181717?style=flat-square&logo=github&logoColor=white)](https://github.com/wiedymi)
[![Twitter](https://img.shields.io/badge/-Twitter-1DA1F2?style=flat-square&logo=twitter&logoColor=white)](https://x.com/wiedymi)
[![Email](https://img.shields.io/badge/-Email-EA4335?style=flat-square&logo=gmail&logoColor=white)](mailto:contact@wiedymi.com)
[![Discord](https://img.shields.io/badge/-Discord-5865F2?style=flat-square&logo=discord&logoColor=white)](https://discord.gg/zemMZtrkSb)
[![Support me](https://img.shields.io/badge/-Support%20me-ff69b4?style=flat-square&logo=githubsponsors&logoColor=white)](https://github.com/sponsors/vivy-company)

Swift SDK for the Umami API, focused first on Apple-platform dashboard apps.

Use it to build native iOS/macOS analytics dashboards against a self-hosted or managed Umami instance, with tracker ingestion support included for `/api/send` and `/api/batch`.

## Features

- Apple-only Swift Package with Swift Concurrency-first API
- Public `import Umami` surface with split modules underneath:
  - `UmamiCore`
  - `UmamiAPI`
  - `UmamiTracker`
- Auth and account APIs:
  - login
  - verify
  - logout
  - `me`
  - password change
  - config
  - heartbeat
  - share token lookup
- Website APIs:
  - list
  - create
  - get
  - update
  - delete
- Dashboard analytics APIs:
  - realtime
  - stats
  - metrics
  - expanded metrics
  - pageviews
  - events
  - event series
  - sessions
  - session stats
  - weekly sessions
  - session detail
  - session activity
  - session properties
  - values
  - daterange
  - event-data routes
  - session-data routes
- Tracker support:
  - `POST /api/send`
  - `POST /api/batch`
  - upstream `x-umami-cache` token reuse
- Raw API escape hatch for upstream routes not yet wrapped

## Platforms

- iOS 15+
- macOS 12+
- tvOS 15+
- watchOS 8+
- visionOS 1+
- Swift tools 6.0+

## Installation

Add to `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/wiedymi/Umami.git", from: "0.1.0")
]
```

Then add the library target:

```swift
.target(
    name: "YourApp",
    dependencies: [
        .product(name: "Umami", package: "Umami")
    ]
)
```

## Quick Start

### Dashboard client

```swift
import Foundation
import Umami

let configuration = UmamiConfiguration(
    baseURL: URL(string: "https://analytics.example.com")!,
    userAgent: "MyDashboard/1.0"
)

let anonymous = UmamiAPIClient(configuration: configuration)
let login = try await anonymous.auth.login(username: "admin", password: "password")

let client = anonymous.withAuth(.bearerToken(login.token))

let websites = try await client.websites.list(
    .init(
        includeTeams: true,
        pagination: .init(page: 1, pageSize: 20, orderBy: "name")
    )
)

let stats = try await client.analytics.stats(
    websiteId: websites.data[0].id,
    query: .init(
        range: .init(
            startAt: Calendar.current.date(byAdding: .day, value: -30, to: Date()),
            endAt: Date(),
            timezone: "Asia/Shanghai",
            unit: .day
        )
    )
)

print(stats.pageviews)
```

### Tracker client

```swift
import Foundation
import Umami

let tracker = UmamiTrackerClient(
    configuration: .init(baseURL: URL(string: "https://analytics.example.com")!)
)

try await tracker.track(
    .init(
        source: .website("your-website-id"),
        url: "/pricing",
        title: "Pricing",
        name: "cta-click",
        data: ["plan": .string("team")]
    )
)
```

## Development

```bash
swift build
swift test
```

## Docs

- `SPEC.md` - SDK scope and implementation plan
- `refs/umami` - upstream Umami source included as a git submodule for reference

## Notes

- `baseURL` should be the Umami server origin, for example `https://analytics.example.com`.
- Query timestamps are encoded in milliseconds where Umami expects them.
- Response decoding accepts ISO-8601 strings and numeric timestamps, including millisecond epochs used by realtime payloads.
- Shared website auth is supported with `UmamiAuth.shareToken`.

## License

MIT
