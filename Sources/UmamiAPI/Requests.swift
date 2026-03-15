import Foundation
import UmamiCore

public struct UmamiListQuery: Sendable, Equatable {
    public var search: String?
    public var pagination: UmamiPagination?

    public init(search: String? = nil, pagination: UmamiPagination? = nil) {
        self.search = search
        self.pagination = pagination
    }
}

public struct UmamiWebsiteListQuery: Sendable, Equatable {
    public var includeTeams: Bool?
    public var search: String?
    public var pagination: UmamiPagination?

    public init(includeTeams: Bool? = nil, search: String? = nil, pagination: UmamiPagination? = nil) {
        self.includeTeams = includeTeams
        self.search = search
        self.pagination = pagination
    }
}

public struct UmamiCreateWebsiteRequest: Sendable, Encodable {
    public let id: String?
    public let name: String
    public let domain: String
    public let shareId: String?
    public let teamId: String?

    public init(id: String? = nil, name: String, domain: String, shareId: String? = nil, teamId: String? = nil) {
        self.id = id
        self.name = name
        self.domain = domain
        self.shareId = shareId
        self.teamId = teamId
    }
}

public struct UmamiUpdateWebsiteRequest: Sendable, Encodable {
    public let name: String?
    public let domain: String?
    public let shareId: String?
    public let clearShareID: Bool

    enum CodingKeys: String, CodingKey {
        case name
        case domain
        case shareId
    }

    public init(name: String? = nil, domain: String? = nil, shareId: String? = nil, clearShareID: Bool = false) {
        self.name = name
        self.domain = domain
        self.shareId = shareId
        self.clearShareID = clearShareID
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(name, forKey: .name)
        try container.encodeIfPresent(domain, forKey: .domain)

        if clearShareID {
            try container.encodeNil(forKey: .shareId)
        } else {
            try container.encodeIfPresent(shareId, forKey: .shareId)
        }
    }
}

public struct UmamiAnalyticsQuery: Sendable, Equatable {
    public var range: UmamiDateRange?
    public var filters: UmamiFilterSet?
    public var search: String?
    public var pagination: UmamiPagination?

    public init(
        range: UmamiDateRange? = nil,
        filters: UmamiFilterSet? = nil,
        search: String? = nil,
        pagination: UmamiPagination? = nil
    ) {
        self.range = range
        self.filters = filters
        self.search = search
        self.pagination = pagination
    }
}

public struct UmamiMetricsQuery: Sendable, Equatable {
    public var type: UmamiMetricType
    public var range: UmamiDateRange?
    public var filters: UmamiFilterSet?
    public var search: String?
    public var limit: Int?
    public var offset: Int?

    public init(
        type: UmamiMetricType,
        range: UmamiDateRange? = nil,
        filters: UmamiFilterSet? = nil,
        search: String? = nil,
        limit: Int? = nil,
        offset: Int? = nil
    ) {
        self.type = type
        self.range = range
        self.filters = filters
        self.search = search
        self.limit = limit
        self.offset = offset
    }
}

public enum UmamiValuesType: String, Sendable, Codable, CaseIterable {
    case path
    case referrer
    case title
    case query
    case os
    case browser
    case device
    case country
    case region
    case city
    case tag
    case hostname
    case language
    case event
    case segment
    case cohort
}

public struct UmamiValuesQuery: Sendable, Equatable {
    public var type: UmamiValuesType
    public var range: UmamiDateRange?
    public var search: String?

    public init(type: UmamiValuesType, range: UmamiDateRange? = nil, search: String? = nil) {
        self.type = type
        self.range = range
        self.search = search
    }
}

public struct UmamiPropertyValuesQuery: Sendable, Equatable {
    public var range: UmamiDateRange?
    public var filters: UmamiFilterSet?
    public var propertyName: String
    public var event: String?

    public init(range: UmamiDateRange? = nil, filters: UmamiFilterSet? = nil, propertyName: String, event: String? = nil) {
        self.range = range
        self.filters = filters
        self.propertyName = propertyName
        self.event = event
    }
}

public struct UmamiPropertyQuery: Sendable, Equatable {
    public var range: UmamiDateRange?
    public var filters: UmamiFilterSet?
    public var propertyName: String?

    public init(range: UmamiDateRange? = nil, filters: UmamiFilterSet? = nil, propertyName: String? = nil) {
        self.range = range
        self.filters = filters
        self.propertyName = propertyName
    }
}

extension UmamiListQuery {
    func queryItems() -> [URLQueryItem] {
        UmamiQueryItems.make { items in
            UmamiQueryItems.append(&items, name: "search", value: search)
            UmamiQueryItems.appendPagination(&items, pagination: pagination)
        }
    }
}

extension UmamiWebsiteListQuery {
    func queryItems() -> [URLQueryItem] {
        UmamiQueryItems.make { items in
            UmamiQueryItems.append(&items, name: "includeTeams", value: includeTeams)
            UmamiQueryItems.append(&items, name: "search", value: search)
            UmamiQueryItems.appendPagination(&items, pagination: pagination)
        }
    }
}

extension UmamiAnalyticsQuery {
    func queryItems() -> [URLQueryItem] {
        UmamiQueryItems.make { items in
            UmamiQueryItems.appendDateRange(&items, range: range)
            UmamiQueryItems.appendFilters(&items, filters: filters)
            UmamiQueryItems.append(&items, name: "search", value: search)
            UmamiQueryItems.appendPagination(&items, pagination: pagination)
        }
    }
}

extension UmamiMetricsQuery {
    func queryItems() -> [URLQueryItem] {
        UmamiQueryItems.make { items in
            UmamiQueryItems.append(&items, name: "type", value: type.rawValue)
            UmamiQueryItems.appendDateRange(&items, range: range)
            UmamiQueryItems.appendFilters(&items, filters: filters)
            UmamiQueryItems.append(&items, name: "search", value: search)
            UmamiQueryItems.append(&items, name: "limit", value: limit)
            UmamiQueryItems.append(&items, name: "offset", value: offset)
        }
    }
}

extension UmamiValuesQuery {
    func queryItems() -> [URLQueryItem] {
        UmamiQueryItems.make { items in
            UmamiQueryItems.append(&items, name: "type", value: type.rawValue)
            UmamiQueryItems.appendDateRange(&items, range: range)
            UmamiQueryItems.append(&items, name: "search", value: search)
        }
    }
}

extension UmamiPropertyValuesQuery {
    func queryItems() -> [URLQueryItem] {
        UmamiQueryItems.make { items in
            UmamiQueryItems.appendDateRange(&items, range: range)
            UmamiQueryItems.appendFilters(&items, filters: filters)
            UmamiQueryItems.append(&items, name: "propertyName", value: propertyName)
            UmamiQueryItems.append(&items, name: "event", value: event)
        }
    }
}

extension UmamiPropertyQuery {
    func queryItems() -> [URLQueryItem] {
        UmamiQueryItems.make { items in
            UmamiQueryItems.appendDateRange(&items, range: range)
            UmamiQueryItems.appendFilters(&items, filters: filters)
            UmamiQueryItems.append(&items, name: "propertyName", value: propertyName)
        }
    }
}
