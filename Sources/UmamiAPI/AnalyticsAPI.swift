import Foundation
import UmamiCore

public struct AnalyticsAPI: Sendable {
    let context: UmamiAPIContext

    public func realtime(websiteId: String, query: UmamiAnalyticsQuery = .init()) async throws -> UmamiRealtimeResponse {
        try await context.transport.send(
            .json(
                method: "GET",
                path: "/api/realtime/\(websiteId)",
                auth: context.auth,
                queryItems: query.queryItems()
            )
        )
    }

    public func stats(websiteId: String, query: UmamiAnalyticsQuery = .init()) async throws -> UmamiWebsiteStatsResponse {
        try await context.transport.send(
            .json(
                method: "GET",
                path: "/api/websites/\(websiteId)/stats",
                auth: context.auth,
                queryItems: query.queryItems()
            )
        )
    }

    public func metrics(websiteId: String, query: UmamiMetricsQuery) async throws -> [UmamiMetricBreakdownEntry] {
        try await context.transport.send(
            .json(
                method: "GET",
                path: "/api/websites/\(websiteId)/metrics",
                auth: context.auth,
                queryItems: query.queryItems()
            )
        )
    }

    public func expandedMetrics(websiteId: String, query: UmamiMetricsQuery) async throws -> [UmamiExpandedMetricEntry] {
        try await context.transport.send(
            .json(
                method: "GET",
                path: "/api/websites/\(websiteId)/metrics/expanded",
                auth: context.auth,
                queryItems: query.queryItems()
            )
        )
    }

    public func pageviews(websiteId: String, query: UmamiAnalyticsQuery = .init()) async throws -> UmamiPageviewsResponse {
        try await context.transport.send(
            .json(
                method: "GET",
                path: "/api/websites/\(websiteId)/pageviews",
                auth: context.auth,
                queryItems: query.queryItems()
            )
        )
    }

    public func events(websiteId: String, query: UmamiAnalyticsQuery = .init()) async throws -> UmamiPage<UmamiWebsiteEvent> {
        try await context.transport.send(
            .json(
                method: "GET",
                path: "/api/websites/\(websiteId)/events",
                auth: context.auth,
                queryItems: query.queryItems()
            )
        )
    }

    public func eventSeries(websiteId: String, query: UmamiAnalyticsQuery = .init()) async throws -> [UmamiEventSeriesPoint] {
        try await context.transport.send(
            .json(
                method: "GET",
                path: "/api/websites/\(websiteId)/events/series",
                auth: context.auth,
                queryItems: query.queryItems()
            )
        )
    }

    public func sessions(websiteId: String, query: UmamiAnalyticsQuery = .init()) async throws -> UmamiPage<UmamiSession> {
        try await context.transport.send(
            .json(
                method: "GET",
                path: "/api/websites/\(websiteId)/sessions",
                auth: context.auth,
                queryItems: query.queryItems()
            )
        )
    }

    public func sessionStats(websiteId: String, query: UmamiAnalyticsQuery) async throws -> UmamiSessionStatsResponse {
        try await context.transport.send(
            .json(
                method: "GET",
                path: "/api/websites/\(websiteId)/sessions/stats",
                auth: context.auth,
                queryItems: query.queryItems()
            )
        )
    }

    public func weeklySessions(websiteId: String, query: UmamiAnalyticsQuery = .init()) async throws -> [UmamiMetricPoint] {
        try await context.transport.send(
            .json(
                method: "GET",
                path: "/api/websites/\(websiteId)/sessions/weekly",
                auth: context.auth,
                queryItems: query.queryItems()
            )
        )
    }

    public func session(websiteId: String, sessionId: String) async throws -> UmamiSession {
        try await context.transport.send(
            .json(
                method: "GET",
                path: "/api/websites/\(websiteId)/sessions/\(sessionId)",
                auth: context.auth
            )
        )
    }

    public func sessionActivity(websiteId: String, sessionId: String, query: UmamiAnalyticsQuery) async throws -> [UmamiSessionActivityEntry] {
        try await context.transport.send(
            .json(
                method: "GET",
                path: "/api/websites/\(websiteId)/sessions/\(sessionId)/activity",
                auth: context.auth,
                queryItems: query.queryItems()
            )
        )
    }

    public func sessionProperties(websiteId: String, sessionId: String) async throws -> [UmamiSessionDataEntry] {
        try await context.transport.send(
            .json(
                method: "GET",
                path: "/api/websites/\(websiteId)/sessions/\(sessionId)/properties",
                auth: context.auth
            )
        )
    }

    public func values(websiteId: String, query: UmamiValuesQuery) async throws -> [UmamiValueSummary] {
        try await context.transport.send(
            .json(
                method: "GET",
                path: "/api/websites/\(websiteId)/values",
                auth: context.auth,
                queryItems: query.queryItems()
            )
        )
    }

    public func dateRange(websiteId: String) async throws -> UmamiDateRangeResponse {
        try await context.transport.send(
            .json(method: "GET", path: "/api/websites/\(websiteId)/daterange", auth: context.auth)
        )
    }

    public func eventDataStats(websiteId: String, query: UmamiAnalyticsQuery = .init()) async throws -> UmamiEventDataStatsResponse {
        try await context.transport.send(
            .json(
                method: "GET",
                path: "/api/websites/\(websiteId)/event-data/stats",
                auth: context.auth,
                queryItems: query.queryItems()
            )
        )
    }

    public func eventDataEvents(websiteId: String, query: UmamiAnalyticsQuery = .init()) async throws -> [UmamiEventDataSummary] {
        try await context.transport.send(
            .json(
                method: "GET",
                path: "/api/websites/\(websiteId)/event-data/events",
                auth: context.auth,
                queryItems: query.queryItems()
            )
        )
    }

    public func eventDataFields(websiteId: String, query: UmamiAnalyticsQuery = .init()) async throws -> [UmamiEventFieldSummary] {
        try await context.transport.send(
            .json(
                method: "GET",
                path: "/api/websites/\(websiteId)/event-data/fields",
                auth: context.auth,
                queryItems: query.queryItems()
            )
        )
    }

    public func eventDataProperties(websiteId: String, query: UmamiPropertyQuery = .init()) async throws -> [UmamiEventPropertySummary] {
        try await context.transport.send(
            .json(
                method: "GET",
                path: "/api/websites/\(websiteId)/event-data/properties",
                auth: context.auth,
                queryItems: query.queryItems()
            )
        )
    }

    public func eventDataValues(websiteId: String, query: UmamiPropertyValuesQuery) async throws -> [UmamiValueSummary] {
        try await context.transport.send(
            .json(
                method: "GET",
                path: "/api/websites/\(websiteId)/event-data/values",
                auth: context.auth,
                queryItems: query.queryItems()
            )
        )
    }

    public func eventData(websiteId: String, eventId: String) async throws -> [UmamiEventDataEntry] {
        try await context.transport.send(
            .json(
                method: "GET",
                path: "/api/websites/\(websiteId)/event-data/\(eventId)",
                auth: context.auth
            )
        )
    }

    public func sessionDataProperties(websiteId: String, query: UmamiAnalyticsQuery = .init()) async throws -> [UmamiPropertySummary] {
        try await context.transport.send(
            .json(
                method: "GET",
                path: "/api/websites/\(websiteId)/session-data/properties",
                auth: context.auth,
                queryItems: query.queryItems()
            )
        )
    }

    public func sessionDataValues(websiteId: String, query: UmamiPropertyValuesQuery) async throws -> [UmamiValueSummary] {
        try await context.transport.send(
            .json(
                method: "GET",
                path: "/api/websites/\(websiteId)/session-data/values",
                auth: context.auth,
                queryItems: query.queryItems()
            )
        )
    }
}
