import Foundation

public enum UmamiAuth: Sendable, Equatable {
    case none
    case bearerToken(String)
    case shareToken(String)

    func apply(to request: inout URLRequest) {
        switch self {
        case .none:
            break
        case .bearerToken(let token):
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        case .shareToken(let token):
            request.setValue(token, forHTTPHeaderField: "x-umami-share-token")
        }
    }
}
