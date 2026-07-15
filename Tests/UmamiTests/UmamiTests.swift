import Foundation
import XCTest
import Umami

final class UmamiTests: XCTestCase {
    func testDecoderHandlesMillisecondEpochs() throws {
        struct Payload: Decodable {
            let timestamp: Date
        }

        let payload = try JSONDecoder.umamiDefault().decode(
            Payload.self,
            from: #"{"timestamp":1712345678901}"#.data(using: .utf8)!
        )

        XCTAssertEqual(Int(payload.timestamp.timeIntervalSince1970), 1_712_345_678)
    }

    func testTransportInjectsBearerTokenUserAgentQueryAndBody() async throws {
        let recorder = RequestRecorder()
        let configuration = makeConfiguration(userAgent: "UmamiTests/1.0", recorder: recorder) { _ in
            Self.response(
                statusCode: 200,
                body: """
                {
                  "id":"website-1",
                  "name":"Docs",
                  "domain":"docs.example.com",
                  "shareId":"share123"
                }
                """
            )
        }

        let client = UmamiAPIClient(
            configuration: configuration,
            auth: .bearerToken("secret-token")
        )

        _ = try await client.websites.create(
            .init(name: "Docs", domain: "docs.example.com", shareId: "share123")
        )

        let request = await recorder.request(at: 0)
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer secret-token")
        XCTAssertEqual(request.value(forHTTPHeaderField: "User-Agent"), "UmamiTests/1.0")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
        XCTAssertEqual(request.url?.path, "/api/websites")

        let body = try XCTUnwrap(request.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])
        XCTAssertEqual(json["name"] as? String, "Docs")
        XCTAssertEqual(json["domain"] as? String, "docs.example.com")
        XCTAssertEqual(json["shareId"] as? String, "share123")
    }

    func testCloudConfigurationRoutesThroughV1AndInjectsAPIKey() async throws {
        let recorder = RequestRecorder()
        let executor = UmamiHTTPExecutor { request in
            await recorder.append(request)
            return Self.response(
                statusCode: 200,
                body: #"{"data":[],"count":0,"page":1,"pageSize":20}"#
            )
        }
        let client = UmamiAPIClient(
            configuration: .init(
                baseURL: URL(string: "https://api.umami.is")!,
                apiPath: "/v1",
                executor: executor
            ),
            auth: .apiKey("cloud-key")
        )

        _ = try await client.websites.list()

        let request = await recorder.request(at: 0)
        XCTAssertEqual(request.url?.absoluteString, "https://api.umami.is/v1/websites")
        XCTAssertEqual(request.value(forHTTPHeaderField: "x-umami-api-key"), "cloud-key")
        XCTAssertNil(request.value(forHTTPHeaderField: "Authorization"))
    }

    func testAPIErrorEnvelopeIsMapped() async throws {
        let configuration = makeConfiguration { _ in
            Self.response(
                statusCode: 401,
                body: """
                {
                  "error": {
                    "message": "Unauthorized",
                    "code": "unauthorized",
                    "status": 401
                  }
                }
                """
            )
        }

        let client = UmamiAPIClient(configuration: configuration, auth: .bearerToken("bad-token"))

        do {
            _ = try await client.auth.verify()
            XCTFail("Expected verify() to throw")
        } catch let error as UmamiTransportError {
            guard case .api(let body) = error else {
                return XCTFail("Expected API error, got \(error)")
            }

            XCTAssertEqual(body.code, "unauthorized")
            XCTAssertEqual(body.status, 401)
        }
    }

    func testWebsiteListEncodesQueryItems() async throws {
        let recorder = RequestRecorder()
        let configuration = makeConfiguration(recorder: recorder) { _ in
            Self.response(
                statusCode: 200,
                body: """
                {
                  "data": [],
                  "count": 0,
                  "page": 2,
                  "pageSize": 10,
                  "orderBy": "name",
                  "search": "prod"
                }
                """
            )
        }

        let client = UmamiAPIClient(configuration: configuration, auth: .bearerToken("token"))

        _ = try await client.websites.list(
            .init(
                includeTeams: true,
                search: "prod",
                pagination: .init(page: 2, pageSize: 10, orderBy: "name", sortDescending: true)
            )
        )

        let request = await recorder.request(at: 0)
        let components = try XCTUnwrap(URLComponents(url: try XCTUnwrap(request.url), resolvingAgainstBaseURL: false))
        let query = Dictionary(uniqueKeysWithValues: (components.queryItems ?? []).map { ($0.name, $0.value ?? "") })

        XCTAssertEqual(query["includeTeams"], "true")
        XCTAssertEqual(query["search"], "prod")
        XCTAssertEqual(query["page"], "2")
        XCTAssertEqual(query["pageSize"], "10")
        XCTAssertEqual(query["orderBy"], "name")
        XCTAssertEqual(query["sortDescending"], "true")
    }

    func testUpdateWebsiteCanClearShareID() async throws {
        let recorder = RequestRecorder()
        let configuration = makeConfiguration(recorder: recorder) { _ in
            Self.response(
                statusCode: 200,
                body: """
                {
                  "id":"website-1",
                  "name":"Docs",
                  "domain":"docs.example.com",
                  "shareId":null
                }
                """
            )
        }

        let client = UmamiAPIClient(configuration: configuration, auth: .bearerToken("token"))

        _ = try await client.websites.update(
            websiteId: "website-1",
            request: .init(clearShareID: true)
        )

        let request = await recorder.request(at: 0)
        let body = try XCTUnwrap(request.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any?])
        XCTAssertTrue(json.keys.contains("shareId"))
        XCTAssertTrue((json["shareId"] ?? nil) is NSNull)
    }

    func testStatsResponseDecodesComparison() async throws {
        let configuration = makeConfiguration { _ in
            Self.response(
                statusCode: 200,
                body: """
                {
                  "pageviews": 10,
                  "visitors": 5,
                  "visits": 7,
                  "bounces": 2,
                  "totaltime": 120,
                  "comparison": {
                    "pageviews": 8,
                    "visitors": 4,
                    "visits": 6,
                    "bounces": 1,
                    "totaltime": 90
                  }
                }
                """
            )
        }

        let client = UmamiAPIClient(configuration: configuration, auth: .bearerToken("token"))
        let response = try await client.analytics.stats(websiteId: "website-1")

        XCTAssertEqual(response.pageviews, 10)
        XCTAssertEqual(response.comparison?.pageviews, 8)
        XCTAssertEqual(response.summary.visitors, 5)
    }

    func testActiveVisitorsAndEventStatsUseTypedAnalyticsRoutes() async throws {
        let recorder = RequestRecorder()
        let configuration = makeConfiguration(recorder: recorder) { request in
            switch request.url?.path {
            case "/api/websites/website-1/active":
                return Self.response(statusCode: 200, body: #"{"visitors":5}"#)
            case "/api/websites/website-1/events/stats":
                return Self.response(
                    statusCode: 200,
                    body: #"{"data":{"events":12,"visitors":8,"visits":9,"uniqueEvents":3,"comparison":{"events":10,"visitors":7,"visits":8,"uniqueEvents":2}}}"#
                )
            default:
                return Self.response(statusCode: 404, body: "{}")
            }
        }
        let client = UmamiAPIClient(configuration: configuration, auth: .bearerToken("token"))

        let active = try await client.analytics.activeVisitors(websiteId: "website-1")
        let stats = try await client.analytics.eventStats(
            websiteId: "website-1",
            query: .init(range: .init(startAt: Date(timeIntervalSince1970: 1)))
        )

        XCTAssertEqual(active.visitors, 5)
        XCTAssertEqual(stats.data.events, 12)
        XCTAssertEqual(stats.data.comparison?.uniqueEvents, 2)
        let activeRequest = await recorder.request(at: 0)
        XCTAssertEqual(activeRequest.url?.path, "/api/websites/website-1/active")
        let statsRequest = await recorder.request(at: 1)
        XCTAssertEqual(statsRequest.url?.path, "/api/websites/website-1/events/stats")
        XCTAssertTrue(statsRequest.url?.query?.contains("startAt=1000") == true)
    }

    func testReportsListAndRunOwnRoutesAndPayloads() async throws {
        struct GoalResponse: Decodable, Sendable {
            let num: Int
            let total: Int
        }

        let recorder = RequestRecorder()
        let configuration = makeConfiguration(recorder: recorder) { request in
            switch (request.httpMethod, request.url?.path) {
            case ("GET", "/api/reports"):
                return Self.response(
                    statusCode: 200,
                    body: #"{"data":[{"id":"report-1","websiteId":"website-1","type":"goal","name":"Signup","parameters":{"type":"event","value":"signup"}}],"count":1,"page":2,"pageSize":20}"#
                )
            case ("POST", "/api/reports/goal"):
                return Self.response(statusCode: 200, body: #"{"num":4,"total":20}"#)
            default:
                return Self.response(statusCode: 404, body: "{}")
            }
        }
        let client = UmamiAPIClient(configuration: configuration, auth: .bearerToken("token"))

        let reports = try await client.reports.list(
            .init(
                websiteId: "website-1",
                type: "goal",
                pagination: .init(page: 2, pageSize: 20)
            )
        )
        let goal = try await client.reports.run(
            "goal",
            request: .init(
                websiteId: "website-1",
                type: "goal",
                parameters: [
                    "type": JSONValue.string("event"),
                    "value": JSONValue.string("signup"),
                ]
            ),
            as: GoalResponse.self
        )

        XCTAssertEqual(reports.data.first?.id, "report-1")
        XCTAssertEqual(
            try XCTUnwrap(reports.data.first?.parameters?["value"]),
            JSONValue.string("signup")
        )
        XCTAssertEqual(goal.num, 4)
        XCTAssertEqual(goal.total, 20)

        let listRequest = await recorder.request(at: 0)
        let listComponents = try XCTUnwrap(
            URLComponents(url: try XCTUnwrap(listRequest.url), resolvingAgainstBaseURL: false)
        )
        let query = Dictionary(
            uniqueKeysWithValues: (listComponents.queryItems ?? []).map { ($0.name, $0.value ?? "") }
        )
        XCTAssertEqual(query["websiteId"], "website-1")
        XCTAssertEqual(query["type"], "goal")
        XCTAssertEqual(query["page"], "2")
        XCTAssertEqual(query["pageSize"], "20")

        let runRequest = await recorder.request(at: 1)
        XCTAssertEqual(runRequest.url?.path, "/api/reports/goal")
        let body = try XCTUnwrap(runRequest.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])
        XCTAssertEqual(json["websiteId"] as? String, "website-1")
        XCTAssertEqual(json["type"] as? String, "goal")
    }

    func testDateQueryClampsExtremeMillisecondsWithoutOverflowing() async throws {
        let recorder = RequestRecorder()
        let configuration = makeConfiguration(recorder: recorder) { _ in
            Self.response(
                statusCode: 200,
                body: #"{"pageviews":0,"visitors":0,"visits":0,"bounces":0,"totaltime":0}"#
            )
        }
        let client = UmamiAPIClient(configuration: configuration)

        _ = try await client.analytics.stats(
            websiteId: "website-1",
            query: .init(range: .init(startAt: .distantFuture, endAt: .distantPast))
        )

        let request = await recorder.request(at: 0)
        let components = try XCTUnwrap(URLComponents(url: try XCTUnwrap(request.url), resolvingAgainstBaseURL: false))
        let query = Dictionary(uniqueKeysWithValues: (components.queryItems ?? []).map { ($0.name, $0.value ?? "") })
        XCTAssertNotNil(Int64(query["startAt"] ?? ""))
        XCTAssertNotNil(Int64(query["endAt"] ?? ""))
    }

    func testTrackerReusesCacheTokenAcrossRequests() async throws {
        let recorder = RequestRecorder()
        let configuration = makeConfiguration(recorder: recorder) { request in
            switch request.url?.path {
            case "/api/send":
                if request.value(forHTTPHeaderField: "x-umami-cache") == nil {
                    return Self.response(
                        statusCode: 200,
                        body: #"{"cache":"cache-1","sessionId":"session-1","visitId":"visit-1"}"#
                    )
                }

                return Self.response(
                    statusCode: 200,
                    body: #"{"cache":"cache-2","sessionId":"session-1","visitId":"visit-1"}"#
                )
            default:
                return Self.response(statusCode: 500, body: "{}")
            }
        }

        let tracker = UmamiTrackerClient(configuration: configuration)

        _ = try await tracker.track(.init(source: .website("website-1"), url: "/home"))
        _ = try await tracker.identify(.init(source: .website("website-1"), data: ["plan": .string("pro")]))

        let first = await recorder.request(at: 0)
        let second = await recorder.request(at: 1)
        let cacheToken = await tracker.currentCacheToken()

        XCTAssertNil(first.value(forHTTPHeaderField: "x-umami-cache"))
        XCTAssertEqual(second.value(forHTTPHeaderField: "x-umami-cache"), "cache-1")
        XCTAssertEqual(cacheToken, "cache-2")
    }

    func testTrackerBatchUsesExistingCacheTokenAndUpdatesIt() async throws {
        let recorder = RequestRecorder()
        let configuration = makeConfiguration(recorder: recorder) { request in
            switch request.url?.path {
            case "/api/send":
                return Self.response(
                    statusCode: 200,
                    body: #"{"cache":"cache-1","sessionId":"session-1","visitId":"visit-1"}"#
                )
            case "/api/batch":
                return Self.response(
                    statusCode: 200,
                    body: """
                    {
                      "size": 2,
                      "processed": 2,
                      "errors": 0,
                      "details": [],
                      "cache": "cache-3"
                    }
                    """
                )
            default:
                return Self.response(statusCode: 500, body: "{}")
            }
        }

        let tracker = UmamiTrackerClient(configuration: configuration)
        _ = try await tracker.track(.init(source: .website("website-1"), url: "/home"))

        let response = try await tracker.flush([
            .event(.init(source: .website("website-1"), url: "/pricing", name: "cta")),
            .identify(.init(source: .website("website-1"), data: ["tier": .string("team")]))
        ])

        let batchRequest = await recorder.request(at: 1)
        let cacheToken = await tracker.currentCacheToken()
        XCTAssertEqual(batchRequest.value(forHTTPHeaderField: "x-umami-cache"), "cache-1")
        XCTAssertEqual(response.cache, "cache-3")
        XCTAssertEqual(cacheToken, "cache-3")
    }

    private func makeConfiguration(
        userAgent: String? = nil,
        recorder: RequestRecorder? = nil,
        responder: @escaping @Sendable (URLRequest) throws -> (Data, HTTPURLResponse)
    ) -> UmamiConfiguration {
        let executor = UmamiHTTPExecutor { request in
            if let recorder {
                await recorder.append(request)
            }

            return try responder(request)
        }

        return UmamiConfiguration(
            baseURL: URL(string: "https://analytics.example.com")!,
            userAgent: userAgent,
            executor: executor
        )
    }

    private static func response(statusCode: Int, body: String) -> (Data, HTTPURLResponse) {
        let url = URL(string: "https://analytics.example.com")!
        let response = HTTPURLResponse(
            url: url,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )!
        return (Data(body.utf8), response)
    }
}

actor RequestRecorder {
    private var requests: [URLRequest] = []

    func append(_ request: URLRequest) {
        requests.append(request)
    }

    func request(at index: Int) -> URLRequest {
        requests[index]
    }
}
