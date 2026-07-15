import Foundation
import UmamiCore

public struct ReportsAPI: Sendable {
    let context: UmamiAPIContext

    public func list(_ query: UmamiReportListQuery) async throws -> UmamiPage<UmamiReport> {
        try await context.transport.send(
            .json(
                method: "GET",
                path: "/api/reports",
                auth: context.auth,
                queryItems: query.queryItems()
            )
        )
    }

    public func run<Response: Decodable & Sendable>(
        _ type: String,
        request: UmamiReportRequest,
        as responseType: Response.Type
    ) async throws -> Response {
        try await context.transport.send(
            .json(
                method: "POST",
                path: "/api/reports/\(type)",
                auth: context.auth,
                body: .json(request)
            )
        )
    }
}

public struct UmamiReportListQuery: Sendable, Equatable {
    public var websiteId: String
    public var type: String?
    public var pagination: UmamiPagination

    public init(
        websiteId: String,
        type: String? = nil,
        pagination: UmamiPagination = .init()
    ) {
        self.websiteId = websiteId
        self.type = type
        self.pagination = pagination
    }

    func queryItems() -> [URLQueryItem] {
        UmamiQueryItems.make { items in
            UmamiQueryItems.append(&items, name: "websiteId", value: websiteId)
            UmamiQueryItems.append(&items, name: "type", value: type)
            UmamiQueryItems.appendPagination(&items, pagination: pagination)
        }
    }
}

public struct UmamiReportRequest: Sendable, Encodable {
    public let websiteId: String
    public let type: String
    public let filters: [String: JSONValue]
    public let parameters: [String: JSONValue]

    public init(
        websiteId: String,
        type: String,
        filters: [String: JSONValue] = [:],
        parameters: [String: JSONValue]
    ) {
        self.websiteId = websiteId
        self.type = type
        self.filters = filters
        self.parameters = parameters
    }
}

public struct UmamiReport: Sendable, Codable {
    public let id: String
    public let websiteId: String
    public let type: String
    public let name: String
    public let description: String?
    public let parameters: [String: JSONValue]?
    public let filters: [String: JSONValue]?
    public let createdAt: Date?
    public let updatedAt: Date?
}
