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
        XCTAssertNil(json["shareId"] ?? "not-nil")
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
