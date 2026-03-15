import Foundation
import UmamiCore

public enum UmamiTrackingSource: Sendable, Codable, Equatable {
    case website(String)
    case link(String)
    case pixel(String)

    enum CodingKeys: String, CodingKey {
        case website
        case link
        case pixel
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .website(let value):
            try container.encode(value, forKey: .website)
        case .link(let value):
            try container.encode(value, forKey: .link)
        case .pixel(let value):
            try container.encode(value, forKey: .pixel)
        }
    }
}

public struct TrackEventRequest: Sendable, Equatable {
    public let source: UmamiTrackingSource
    public let data: [String: JSONValue]?
    public let hostname: String?
    public let language: String?
    public let referrer: String?
    public let screen: String?
    public let title: String?
    public let url: String?
    public let name: String?
    public let tag: String?
    public let ip: String?
    public let userAgent: String?
    public let timestamp: Date?
    public let id: String?
    public let browser: String?
    public let os: String?
    public let device: String?

    public init(
        source: UmamiTrackingSource,
        data: [String: JSONValue]? = nil,
        hostname: String? = nil,
        language: String? = nil,
        referrer: String? = nil,
        screen: String? = nil,
        title: String? = nil,
        url: String? = nil,
        name: String? = nil,
        tag: String? = nil,
        ip: String? = nil,
        userAgent: String? = nil,
        timestamp: Date? = nil,
        id: String? = nil,
        browser: String? = nil,
        os: String? = nil,
        device: String? = nil
    ) {
        self.source = source
        self.data = data
        self.hostname = hostname
        self.language = language
        self.referrer = referrer
        self.screen = screen
        self.title = title
        self.url = url
        self.name = name
        self.tag = tag
        self.ip = ip
        self.userAgent = userAgent
        self.timestamp = timestamp
        self.id = id
        self.browser = browser
        self.os = os
        self.device = device
    }
}

public struct IdentifyRequest: Sendable, Equatable {
    public let source: UmamiTrackingSource
    public let data: [String: JSONValue]?
    public let hostname: String?
    public let language: String?
    public let screen: String?
    public let ip: String?
    public let userAgent: String?
    public let timestamp: Date?
    public let id: String?
    public let browser: String?
    public let os: String?
    public let device: String?

    public init(
        source: UmamiTrackingSource,
        data: [String: JSONValue]? = nil,
        hostname: String? = nil,
        language: String? = nil,
        screen: String? = nil,
        ip: String? = nil,
        userAgent: String? = nil,
        timestamp: Date? = nil,
        id: String? = nil,
        browser: String? = nil,
        os: String? = nil,
        device: String? = nil
    ) {
        self.source = source
        self.data = data
        self.hostname = hostname
        self.language = language
        self.screen = screen
        self.ip = ip
        self.userAgent = userAgent
        self.timestamp = timestamp
        self.id = id
        self.browser = browser
        self.os = os
        self.device = device
    }
}

public struct TrackEventResponse: Sendable, Codable {
    public let cache: String
    public let sessionId: String
    public let visitId: String
}

public struct BatchTrackFailure: Sendable, Codable {
    public let index: Int
    public let response: JSONValue
}

public struct BatchTrackResponse: Sendable, Codable {
    public let size: Int
    public let processed: Int
    public let errors: Int
    public let details: [BatchTrackFailure]
    public let cache: String?
}

public enum TrackingEnvelope: Sendable, Equatable {
    case event(TrackEventRequest)
    case identify(IdentifyRequest)
}

struct TrackingPayload: Sendable, Encodable {
    let website: String?
    let link: String?
    let pixel: String?
    let data: [String: JSONValue]?
    let hostname: String?
    let language: String?
    let referrer: String?
    let screen: String?
    let title: String?
    let url: String?
    let name: String?
    let tag: String?
    let ip: String?
    let userAgent: String?
    let timestamp: Int?
    let id: String?
    let browser: String?
    let os: String?
    let device: String?

    init(source: UmamiTrackingSource, data: [String: JSONValue]?, hostname: String?, language: String?, referrer: String?, screen: String?, title: String?, url: String?, name: String?, tag: String?, ip: String?, userAgent: String?, timestamp: Date?, id: String?, browser: String?, os: String?, device: String?) {
        switch source {
        case .website(let value):
            website = value
            link = nil
            pixel = nil
        case .link(let value):
            website = nil
            link = value
            pixel = nil
        case .pixel(let value):
            website = nil
            link = nil
            pixel = value
        }

        self.data = data
        self.hostname = hostname
        self.language = language
        self.referrer = referrer
        self.screen = screen
        self.title = title
        self.url = url
        self.name = name
        self.tag = tag
        self.ip = ip
        self.userAgent = userAgent
        self.timestamp = timestamp.map { Int($0.timeIntervalSince1970) }
        self.id = id
        self.browser = browser
        self.os = os
        self.device = device
    }
}

struct TrackingEnvelopeBody: Sendable, Encodable {
    let type: String
    let payload: TrackingPayload
}
