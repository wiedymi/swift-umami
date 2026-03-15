import Foundation
import UmamiCore

public struct UmamiRole: RawRepresentable, Sendable, Codable, Hashable, ExpressibleByStringLiteral {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(stringLiteral value: StringLiteralType) {
        self.rawValue = value
    }

    public static let admin: Self = "admin"
    public static let user: Self = "user"
    public static let viewOnly: Self = "view-only"
    public static let teamOwner: Self = "team-owner"
    public static let teamManager: Self = "team-manager"
    public static let teamMember: Self = "team-member"
    public static let teamViewOnly: Self = "team-view-only"
}

public struct UmamiUserReference: Sendable, Codable {
    public let id: String
    public let username: String?

    public init(id: String, username: String? = nil) {
        self.id = id
        self.username = username
    }
}

public struct UmamiTeam: Sendable, Codable {
    public let id: String
    public let name: String?
    public let role: UmamiRole?
    public let createdAt: Date?
    public let updatedAt: Date?

    public init(
        id: String,
        name: String? = nil,
        role: UmamiRole? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.role = role
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public struct UmamiUser: Sendable, Codable {
    public let id: String
    public let username: String?
    public let role: UmamiRole?
    public let createdAt: Date?
    public let updatedAt: Date?
    public let isAdmin: Bool?
    public let teams: [UmamiTeam]?

    public init(
        id: String,
        username: String? = nil,
        role: UmamiRole? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil,
        isAdmin: Bool? = nil,
        teams: [UmamiTeam]? = nil
    ) {
        self.id = id
        self.username = username
        self.role = role
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isAdmin = isAdmin
        self.teams = teams
    }
}

public struct UmamiLoginResponse: Sendable, Codable {
    public let token: String
    public let user: UmamiUser

    public init(token: String, user: UmamiUser) {
        self.token = token
        self.user = user
    }
}

public struct UmamiAuthContextResponse: Sendable, Codable {
    public let token: String?
    public let authKey: String?
    public let shareToken: JSONValue?
    public let user: UmamiUser?

    public init(token: String? = nil, authKey: String? = nil, shareToken: JSONValue? = nil, user: UmamiUser? = nil) {
        self.token = token
        self.authKey = authKey
        self.shareToken = shareToken
        self.user = user
    }
}

public struct UmamiConfigResponse: Sendable, Codable {
    public let cloudMode: Bool
    public let faviconURL: String?
    public let linksURL: String?
    public let pixelsURL: String?
    public let privateMode: Bool
    public let telemetryDisabled: Bool
    public let trackerScriptName: String?
    public let updatesDisabled: Bool

    enum CodingKeys: String, CodingKey {
        case cloudMode
        case faviconURL = "faviconUrl"
        case linksURL = "linksUrl"
        case pixelsURL = "pixelsUrl"
        case privateMode
        case telemetryDisabled
        case trackerScriptName
        case updatesDisabled
    }
}

public struct UmamiShareTokenResponse: Sendable, Codable {
    public let websiteId: String
    public let token: String

    public init(websiteId: String, token: String) {
        self.websiteId = websiteId
        self.token = token
    }
}

public struct UmamiPage<Item: Sendable & Codable>: Sendable, Codable {
    public let data: [Item]
    public let count: Int
    public let page: Int
    public let pageSize: Int
    public let orderBy: String?
    public let search: String?

    public init(data: [Item], count: Int, page: Int, pageSize: Int, orderBy: String? = nil, search: String? = nil) {
        self.data = data
        self.count = count
        self.page = page
        self.pageSize = pageSize
        self.orderBy = orderBy
        self.search = search
    }
}

public struct UmamiWebsite: Sendable, Codable {
    public let id: String
    public let name: String
    public let domain: String
    public let shareId: String?
    public let userId: String?
    public let teamId: String?
    public let createdAt: Date?
    public let updatedAt: Date?
    public let resetAt: Date?
    public let deletedAt: Date?
    public let createdBy: String?
    public let user: UmamiUserReference?
    public let createUser: UmamiUserReference?
}

public struct UmamiWebsiteStatsSummary: Sendable, Codable {
    public let pageviews: Int
    public let visitors: Int
    public let visits: Int
    public let bounces: Int
    public let totaltime: Int

    public init(pageviews: Int, visitors: Int, visits: Int, bounces: Int, totaltime: Int) {
        self.pageviews = pageviews
        self.visitors = visitors
        self.visits = visits
        self.bounces = bounces
        self.totaltime = totaltime
    }
}

public struct UmamiWebsiteStatsResponse: Sendable, Codable {
    public let pageviews: Int
    public let visitors: Int
    public let visits: Int
    public let bounces: Int
    public let totaltime: Int
    public let comparison: UmamiWebsiteStatsSummary?

    public var summary: UmamiWebsiteStatsSummary {
        .init(pageviews: pageviews, visitors: visitors, visits: visits, bounces: bounces, totaltime: totaltime)
    }
}

public struct UmamiMetricPoint: Sendable, Codable {
    public let x: String
    public let y: Int

    public init(x: String, y: Int) {
        self.x = x
        self.y = y
    }
}

public struct UmamiEventSeriesPoint: Sendable, Codable {
    public let x: String
    public let t: String
    public let y: Int

    public init(x: String, t: String, y: Int) {
        self.x = x
        self.t = t
        self.y = y
    }
}

public struct UmamiPageviewsComparison: Sendable, Codable {
    public let pageviews: [UmamiMetricPoint]
    public let sessions: [UmamiMetricPoint]
    public let startDate: Date?
    public let endDate: Date?
}

public struct UmamiPageviewsResponse: Sendable, Codable {
    public let pageviews: [UmamiMetricPoint]
    public let sessions: [UmamiMetricPoint]
    public let startDate: Date?
    public let endDate: Date?
    public let compare: UmamiPageviewsComparison?
}

public struct UmamiMetricBreakdownEntry: Sendable, Codable {
    public let x: String
    public let y: Int
    public let country: String?

    public init(x: String, y: Int, country: String? = nil) {
        self.x = x
        self.y = y
        self.country = country
    }
}

public struct UmamiExpandedMetricEntry: Sendable, Codable {
    public let name: String
    public let country: String?
    public let pageviews: Int
    public let visitors: Int
    public let visits: Int
    public let bounces: Int
    public let totaltime: Int

    public init(
        name: String,
        country: String? = nil,
        pageviews: Int,
        visitors: Int,
        visits: Int,
        bounces: Int,
        totaltime: Int
    ) {
        self.name = name
        self.country = country
        self.pageviews = pageviews
        self.visitors = visitors
        self.visits = visits
        self.bounces = bounces
        self.totaltime = totaltime
    }
}

public struct UmamiAnalyticsMetricValue: Sendable, Codable {
    public let value: Int

    public init(value: Int) {
        self.value = value
    }
}

public struct UmamiSessionStatsResponse: Sendable, Codable {
    public let pageviews: UmamiAnalyticsMetricValue
    public let visitors: UmamiAnalyticsMetricValue
    public let visits: UmamiAnalyticsMetricValue
    public let countries: UmamiAnalyticsMetricValue
    public let events: UmamiAnalyticsMetricValue
}

public struct UmamiRealtimeEvent: Sendable, Codable {
    public enum Kind: String, Sendable, Codable {
        case session
        case event
        case pageview
    }

    public let kind: Kind
    public let sessionId: String
    public let urlPath: String?
    public let referrerDomain: String?
    public let country: String?
    public let eventName: String?

    enum CodingKeys: String, CodingKey {
        case kind = "__type"
        case sessionId
        case urlPath
        case referrerDomain
        case country
        case eventName
    }
}

public struct UmamiRealtimeSeries: Sendable, Codable {
    public let views: [UmamiMetricPoint]
    public let visitors: [UmamiMetricPoint]
}

public struct UmamiRealtimeTotals: Sendable, Codable {
    public let views: Int
    public let visitors: Int
    public let events: Int
    public let countries: Int
}

public struct UmamiRealtimeResponse: Sendable, Codable {
    public let countries: [String: Int]
    public let urls: [String: Int]
    public let referrers: [String: Int]
    public let events: [UmamiRealtimeEvent]
    public let series: UmamiRealtimeSeries
    public let totals: UmamiRealtimeTotals
    public let timestamp: Date
}

public struct UmamiSession: Sendable, Codable {
    public let id: String
    public let websiteId: String
    public let distinctId: String?
    public let hostname: String?
    public let browser: String?
    public let os: String?
    public let device: String?
    public let screen: String?
    public let language: String?
    public let country: String?
    public let region: String?
    public let city: String?
    public let firstAt: Date?
    public let lastAt: Date?
    public let visits: Int
    public let views: Int
    public let events: Int?
    public let totaltime: Int?
    public let createdAt: Date?
}

public struct UmamiWebsiteEvent: Sendable, Codable {
    public let id: String
    public let websiteId: String
    public let sessionId: String
    public let createdAt: Date
    public let hostname: String?
    public let urlPath: String?
    public let urlQuery: String?
    public let referrerPath: String?
    public let referrerQuery: String?
    public let referrerDomain: String?
    public let country: String?
    public let city: String?
    public let device: String?
    public let os: String?
    public let browser: String?
    public let pageTitle: String?
    public let eventType: Int
    public let eventName: String?
    public let hasData: Bool
}

public struct UmamiSessionActivityEntry: Sendable, Codable {
    public let createdAt: Date
    public let urlPath: String?
    public let urlQuery: String?
    public let referrerDomain: String?
    public let eventId: String
    public let eventType: Int
    public let eventName: String?
    public let visitId: String
    public let hasData: Bool
}

public struct UmamiSessionDataEntry: Sendable, Codable {
    public let websiteId: String
    public let sessionId: String
    public let dataKey: String
    public let dataType: Int
    public let stringValue: String?
    public let numberValue: Double?
    public let dateValue: Date?
    public let createdAt: Date
}

public struct UmamiEventDataEntry: Sendable, Codable {
    public let websiteId: String
    public let eventId: String
    public let eventName: String?
    public let dataKey: String
    public let stringValue: String?
    public let numberValue: Double?
    public let dateValue: Date?
    public let dataType: Int
    public let createdAt: Date
}

public struct UmamiEventDataStatsResponse: Sendable, Codable {
    public let events: Int
    public let properties: Int
    public let records: Int
}

public struct UmamiEventDataSummary: Sendable, Codable {
    public let eventName: String?
    public let propertyName: String
    public let dataType: Int
    public let propertyValue: String?
    public let total: Int
}

public struct UmamiEventFieldSummary: Sendable, Codable {
    public let propertyName: String
    public let dataType: Int
    public let value: String
    public let total: Int
}

public struct UmamiEventPropertySummary: Sendable, Codable {
    public let eventName: String
    public let propertyName: String
    public let total: Int
}

public struct UmamiPropertySummary: Sendable, Codable {
    public let propertyName: String
    public let total: Int
}

public struct UmamiValueSummary: Sendable, Codable {
    public let value: String
    public let total: Int
}

public struct UmamiDateRangeResponse: Sendable, Codable {
    public let startDate: Date?
    public let endDate: Date?
}
