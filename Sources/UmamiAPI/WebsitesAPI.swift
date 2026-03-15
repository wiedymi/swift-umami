import Foundation
import UmamiCore

public struct WebsitesAPI: Sendable {
    let context: UmamiAPIContext

    public func list(_ query: UmamiWebsiteListQuery = .init()) async throws -> UmamiPage<UmamiWebsite> {
        try await context.transport.send(
            .json(method: "GET", path: "/api/websites", auth: context.auth, queryItems: query.queryItems())
        )
    }

    public func create(_ request: UmamiCreateWebsiteRequest) async throws -> UmamiWebsite {
        try await context.transport.send(
            .json(method: "POST", path: "/api/websites", auth: context.auth, body: .json(request))
        )
    }

    public func get(websiteId: String) async throws -> UmamiWebsite {
        try await context.transport.send(
            .json(method: "GET", path: "/api/websites/\(websiteId)", auth: context.auth)
        )
    }

    public func update(websiteId: String, request: UmamiUpdateWebsiteRequest) async throws -> UmamiWebsite {
        try await context.transport.send(
            .json(
                method: "POST",
                path: "/api/websites/\(websiteId)",
                auth: context.auth,
                body: .json(request)
            )
        )
    }

    public func delete(websiteId: String) async throws -> UmamiOKResponse {
        try await context.transport.send(
            .json(method: "DELETE", path: "/api/websites/\(websiteId)", auth: context.auth)
        )
    }
}
