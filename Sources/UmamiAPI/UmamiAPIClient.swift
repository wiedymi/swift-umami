import Foundation
import UmamiCore

public struct UmamiAPIClient: Sendable {
    let context: UmamiAPIContext

    public init(
        configuration: UmamiConfiguration,
        auth: UmamiAuth = .none,
        transport: (any UmamiTransport)? = nil
    ) {
        let resolvedTransport = transport ?? DefaultUmamiTransport(configuration: configuration)
        self.context = UmamiAPIContext(transport: resolvedTransport, auth: auth)
    }

    init(context: UmamiAPIContext) {
        self.context = context
    }

    public func withAuth(_ auth: UmamiAuth) -> Self {
        Self(context: context.withAuth(auth))
    }

    public var auth: AuthAPI { AuthAPI(context: context) }
    public var system: SystemAPI { SystemAPI(context: context) }
    public var account: AccountAPI { AccountAPI(context: context) }
    public var websites: WebsitesAPI { WebsitesAPI(context: context) }
    public var analytics: AnalyticsAPI { AnalyticsAPI(context: context) }
    public var raw: RawAPI { RawAPI(context: context) }
}

public struct RawAPI: Sendable {
    let context: UmamiAPIContext

    public func get(path: String, queryItems: [URLQueryItem] = [], auth: UmamiAuth? = nil) async throws -> UmamiRawResponse {
        try await context.transport.send(
            .raw(method: "GET", path: path, auth: auth ?? context.auth, queryItems: queryItems)
        )
    }

    public func post<Body: Encodable & Sendable>(
        path: String,
        body: Body,
        auth: UmamiAuth? = nil
    ) async throws -> UmamiRawResponse {
        try await context.transport.send(
            .raw(method: "POST", path: path, auth: auth ?? context.auth, body: .json(body))
        )
    }

    public func delete(path: String, auth: UmamiAuth? = nil) async throws -> UmamiRawResponse {
        try await context.transport.send(
            .raw(method: "DELETE", path: path, auth: auth ?? context.auth)
        )
    }
}
