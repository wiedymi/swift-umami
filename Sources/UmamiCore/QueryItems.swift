import Foundation

public enum UmamiUnit: String, Sendable, Codable, CaseIterable {
    case year
    case month
    case hour
    case day
    case minute
}

public enum UmamiMetricType: String, Sendable, Codable, CaseIterable {
    case browser
    case os
    case device
    case screen
    case language
    case country
    case city
    case region
    case path
    case entry
    case exit
    case referrer
    case domain
    case title
    case query
    case event
    case tag
    case hostname
    case channel
}

public enum UmamiFieldType: String, Sendable, Codable, CaseIterable {
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
}

public enum UmamiEventType: Int, Sendable, Codable, CaseIterable {
    case pageView = 1
    case customEvent = 2
    case linkEvent = 3
    case pixelEvent = 4
}

public enum UmamiCompareWindow: String, Sendable, Codable, CaseIterable {
    case prev
}

public struct UmamiDateRange: Sendable, Codable, Equatable {
    public var startAt: Date?
    public var endAt: Date?
    public var startDate: Date?
    public var endDate: Date?
    public var timezone: String?
    public var unit: UmamiUnit?
    public var compare: UmamiCompareWindow?

    public init(
        startAt: Date? = nil,
        endAt: Date? = nil,
        startDate: Date? = nil,
        endDate: Date? = nil,
        timezone: String? = nil,
        unit: UmamiUnit? = nil,
        compare: UmamiCompareWindow? = nil
    ) {
        self.startAt = startAt
        self.endAt = endAt
        self.startDate = startDate
        self.endDate = endDate
        self.timezone = timezone
        self.unit = unit
        self.compare = compare
    }
}

public struct UmamiFilterSet: Sendable, Codable, Equatable {
    public var path: String?
    public var referrer: String?
    public var title: String?
    public var query: String?
    public var os: String?
    public var browser: String?
    public var device: String?
    public var country: String?
    public var region: String?
    public var city: String?
    public var tag: String?
    public var hostname: String?
    public var language: String?
    public var event: String?
    public var segment: UUID?
    public var cohort: UUID?
    public var eventType: UmamiEventType?

    public init(
        path: String? = nil,
        referrer: String? = nil,
        title: String? = nil,
        query: String? = nil,
        os: String? = nil,
        browser: String? = nil,
        device: String? = nil,
        country: String? = nil,
        region: String? = nil,
        city: String? = nil,
        tag: String? = nil,
        hostname: String? = nil,
        language: String? = nil,
        event: String? = nil,
        segment: UUID? = nil,
        cohort: UUID? = nil,
        eventType: UmamiEventType? = nil
    ) {
        self.path = path
        self.referrer = referrer
        self.title = title
        self.query = query
        self.os = os
        self.browser = browser
        self.device = device
        self.country = country
        self.region = region
        self.city = city
        self.tag = tag
        self.hostname = hostname
        self.language = language
        self.event = event
        self.segment = segment
        self.cohort = cohort
        self.eventType = eventType
    }
}

public struct UmamiPagination: Sendable, Codable, Equatable {
    public var page: Int?
    public var pageSize: Int?
    public var orderBy: String?
    public var sortDescending: Bool?

    public init(page: Int? = nil, pageSize: Int? = nil, orderBy: String? = nil, sortDescending: Bool? = nil) {
        self.page = page
        self.pageSize = pageSize
        self.orderBy = orderBy
        self.sortDescending = sortDescending
    }
}

public enum UmamiQueryItems {
    public static func make(_ builder: (inout [URLQueryItem]) -> Void) -> [URLQueryItem] {
        var items: [URLQueryItem] = []
        builder(&items)
        return items
    }

    public static func append(_ items: inout [URLQueryItem], name: String, value: String?) {
        guard let value else { return }
        items.append(URLQueryItem(name: name, value: value))
    }

    public static func append(_ items: inout [URLQueryItem], name: String, value: Int?) {
        guard let value else { return }
        items.append(URLQueryItem(name: name, value: String(value)))
    }

    public static func append(_ items: inout [URLQueryItem], name: String, value: Bool?) {
        guard let value else { return }
        items.append(URLQueryItem(name: name, value: value ? "true" : "false"))
    }

    public static func append(_ items: inout [URLQueryItem], name: String, value: Double?) {
        guard let value else { return }
        items.append(URLQueryItem(name: name, value: String(value)))
    }

    public static func append(_ items: inout [URLQueryItem], name: String, value: UUID?) {
        guard let value else { return }
        items.append(URLQueryItem(name: name, value: value.uuidString.lowercased()))
    }

    public static func appendMilliseconds(_ items: inout [URLQueryItem], name: String, value: Date?) {
        guard let value else { return }
        items.append(URLQueryItem(name: name, value: String(Int64(value.timeIntervalSince1970 * 1000.0))))
    }

    public static func appendISO8601(_ items: inout [URLQueryItem], name: String, value: Date?) {
        guard let value else { return }
        items.append(URLQueryItem(name: name, value: umamiISO8601String(from: value)))
    }

    public static func appendDateRange(_ items: inout [URLQueryItem], range: UmamiDateRange?) {
        guard let range else { return }
        appendMilliseconds(&items, name: "startAt", value: range.startAt)
        appendMilliseconds(&items, name: "endAt", value: range.endAt)
        appendISO8601(&items, name: "startDate", value: range.startDate)
        appendISO8601(&items, name: "endDate", value: range.endDate)
        append(&items, name: "timezone", value: range.timezone)
        append(&items, name: "unit", value: range.unit?.rawValue)
        append(&items, name: "compare", value: range.compare?.rawValue)
    }

    public static func appendFilters(_ items: inout [URLQueryItem], filters: UmamiFilterSet?) {
        guard let filters else { return }
        append(&items, name: "path", value: filters.path)
        append(&items, name: "referrer", value: filters.referrer)
        append(&items, name: "title", value: filters.title)
        append(&items, name: "query", value: filters.query)
        append(&items, name: "os", value: filters.os)
        append(&items, name: "browser", value: filters.browser)
        append(&items, name: "device", value: filters.device)
        append(&items, name: "country", value: filters.country)
        append(&items, name: "region", value: filters.region)
        append(&items, name: "city", value: filters.city)
        append(&items, name: "tag", value: filters.tag)
        append(&items, name: "hostname", value: filters.hostname)
        append(&items, name: "language", value: filters.language)
        append(&items, name: "event", value: filters.event)
        append(&items, name: "segment", value: filters.segment)
        append(&items, name: "cohort", value: filters.cohort)
        append(&items, name: "eventType", value: filters.eventType?.rawValue)
    }

    public static func appendPagination(_ items: inout [URLQueryItem], pagination: UmamiPagination?) {
        guard let pagination else { return }
        append(&items, name: "page", value: pagination.page)
        append(&items, name: "pageSize", value: pagination.pageSize)
        append(&items, name: "orderBy", value: pagination.orderBy)
        append(&items, name: "sortDescending", value: pagination.sortDescending)
    }
}
