import Foundation
import UmamiCore

public struct SystemAPI: Sendable {
    let context: UmamiAPIContext

    public func config() async throws -> UmamiConfigResponse {
        try await context.transport.send(.json(method: "GET", path: "/api/config"))
    }

    public func heartbeat() async throws -> UmamiOKResponse {
        try await context.transport.send(.json(method: "GET", path: "/api/heartbeat"))
    }

    public func shareToken(for shareId: String) async throws -> UmamiShareTokenResponse {
        try await context.transport.send(.json(method: "GET", path: "/api/share/\(shareId)"))
    }
}
