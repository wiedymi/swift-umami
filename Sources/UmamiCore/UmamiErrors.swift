import Foundation

public struct UmamiAPIErrorEnvelope: Decodable, Sendable, Equatable {
    public let error: UmamiAPIErrorBody

    public init(error: UmamiAPIErrorBody) {
        self.error = error
    }
}

public struct UmamiAPIErrorBody: Decodable, Error, Sendable, Equatable {
    public let message: String
    public let code: String
    public let status: Int

    public init(message: String, code: String, status: Int) {
        self.message = message
        self.code = code
        self.status = status
    }
}

public enum UmamiTransportError: Error, Sendable, Equatable {
    case invalidURL(String)
    case invalidResponse
    case missingBody
    case decodingFailure(String)
    case encodingFailure(String)
    case api(UmamiAPIErrorBody)
    case unexpectedStatus(Int)
}
