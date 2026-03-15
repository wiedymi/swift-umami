import Foundation
import UmamiCore

public struct AccountAPI: Sendable {
    let context: UmamiAPIContext

    public func me() async throws -> UmamiAuthContextResponse {
        try await context.transport.send(.json(method: "GET", path: "/api/me", auth: context.auth))
    }

    public func changePassword(currentPassword: String, newPassword: String) async throws -> UmamiUser {
        struct Body: Sendable, Encodable {
            let currentPassword: String
            let newPassword: String
        }

        return try await context.transport.send(
            .json(
                method: "POST",
                path: "/api/me/password",
                auth: context.auth,
                body: .json(Body(currentPassword: currentPassword, newPassword: newPassword))
            )
        )
    }
}
