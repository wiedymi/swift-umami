import Foundation

public struct UmamiRequest<Response> {
    public let method: String
    public let path: String
    public let auth: UmamiAuth
    public let queryItems: [URLQueryItem]
    public let headers: [String: String]
    public let body: UmamiRequestBody?
    let decode: (Data, HTTPURLResponse, JSONDecoder) throws -> Response

    public init(
        method: String,
        path: String,
        auth: UmamiAuth = .none,
        queryItems: [URLQueryItem] = [],
        headers: [String: String] = [:],
        body: UmamiRequestBody? = nil,
        decode: @escaping (Data, HTTPURLResponse, JSONDecoder) throws -> Response
    ) {
        self.method = method
        self.path = path
        self.auth = auth
        self.queryItems = queryItems
        self.headers = headers
        self.body = body
        self.decode = decode
    }
}

public struct UmamiRequestBody {
    public let contentType: String
    let encode: (JSONEncoder) throws -> Data

    public init(contentType: String, encode: @escaping (JSONEncoder) throws -> Data) {
        self.contentType = contentType
        self.encode = encode
    }

    public static func json<Value: Encodable & Sendable>(_ value: Value) -> Self {
        Self(contentType: "application/json") { encoder in
            try encoder.encode(value)
        }
    }
}

public struct UmamiRawResponse: Sendable, Equatable {
    public let statusCode: Int
    public let headers: [String: String]
    public let body: Data

    public init(statusCode: Int, headers: [String: String], body: Data) {
        self.statusCode = statusCode
        self.headers = headers
        self.body = body
    }

    public func decodeJSON(using decoder: JSONDecoder = .umamiDefault()) throws -> JSONValue {
        try decoder.decode(JSONValue.self, from: body)
    }
}

public struct UmamiOKResponse: Decodable, Sendable, Equatable {
    public let ok: Bool

    public init(ok: Bool) {
        self.ok = ok
    }
}

extension UmamiRequest where Response: Decodable {
    public static func json(
        method: String,
        path: String,
        auth: UmamiAuth = .none,
        queryItems: [URLQueryItem] = [],
        headers: [String: String] = [:],
        body: UmamiRequestBody? = nil
    ) -> Self {
        Self(
            method: method,
            path: path,
            auth: auth,
            queryItems: queryItems,
            headers: headers,
            body: body
        ) { data, _, decoder in
            guard !data.isEmpty else {
                throw UmamiTransportError.missingBody
            }
            do {
                return try decoder.decode(Response.self, from: data)
            } catch {
                throw UmamiTransportError.decodingFailure(String(describing: error))
            }
        }
    }
}

extension UmamiRequest where Response == UmamiRawResponse {
    public static func raw(
        method: String,
        path: String,
        auth: UmamiAuth = .none,
        queryItems: [URLQueryItem] = [],
        headers: [String: String] = [:],
        body: UmamiRequestBody? = nil
    ) -> Self {
        Self(
            method: method,
            path: path,
            auth: auth,
            queryItems: queryItems,
            headers: headers,
            body: body
        ) { data, response, _ in
            UmamiRawResponse(
                statusCode: response.statusCode,
                headers: response.allHeaderFields.reduce(into: [:]) { partialResult, entry in
                    partialResult[String(describing: entry.key)] = String(describing: entry.value)
                },
                body: data
            )
        }
    }
}
