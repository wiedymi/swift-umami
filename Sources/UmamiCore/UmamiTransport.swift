import Foundation

public protocol UmamiTransport: Sendable {
    func send<Response>(_ request: UmamiRequest<Response>) async throws -> Response
}

public struct DefaultUmamiTransport: UmamiTransport, Sendable {
    public let configuration: UmamiConfiguration

    public init(configuration: UmamiConfiguration) {
        self.configuration = configuration
    }

    public func send<Response>(_ request: UmamiRequest<Response>) async throws -> Response {
        let urlRequest = try makeURLRequest(from: request)
        let (data, response) = try await configuration.executor.execute(urlRequest)

        if !(200..<300).contains(response.statusCode) {
            let decoder = configuration.decoderFactory()

            if let apiError = try? decoder.decode(UmamiAPIErrorEnvelope.self, from: data) {
                throw UmamiTransportError.api(apiError.error)
            }

            throw UmamiTransportError.unexpectedStatus(response.statusCode)
        }

        return try request.decode(data, response, configuration.decoderFactory())
    }

    private func makeURLRequest<Response>(from request: UmamiRequest<Response>) throws -> URLRequest {
        guard let url = URL(string: request.path, relativeTo: configuration.baseURL) else {
            throw UmamiTransportError.invalidURL(request.path)
        }

        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            throw UmamiTransportError.invalidURL(request.path)
        }

        if !request.queryItems.isEmpty {
            components.queryItems = request.queryItems
        }

        guard let finalURL = components.url else {
            throw UmamiTransportError.invalidURL(request.path)
        }

        var urlRequest = URLRequest(url: finalURL)
        urlRequest.httpMethod = request.method
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")

        if let userAgent = configuration.userAgent {
            urlRequest.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        }

        request.auth.apply(to: &urlRequest)

        for (header, value) in request.headers {
            urlRequest.setValue(value, forHTTPHeaderField: header)
        }

        if let body = request.body {
            let encoder = configuration.encoderFactory()
            do {
                urlRequest.httpBody = try body.encode(encoder)
            } catch {
                throw UmamiTransportError.encodingFailure(String(describing: error))
            }
            urlRequest.setValue(body.contentType, forHTTPHeaderField: "Content-Type")
        }

        return urlRequest
    }
}
