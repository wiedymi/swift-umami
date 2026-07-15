import Foundation

public enum UmamiAuth: Sendable, Equatable {
    case none
    case bearerToken(String)
    case apiKey(String)
    case shareToken(String)

    func apply(to request: inout URLRequest) {
        switch self {
        case .none:
            break
        case .bearerToken(let token):
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        case .apiKey(let key):
            request.setValue(key, forHTTPHeaderField: "x-umami-api-key")
        case .shareToken(let token):
            request.setValue(token, forHTTPHeaderField: "x-umami-share-token")
        }
    }
}
