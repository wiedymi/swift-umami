import Foundation
import UmamiCore

public struct AuthAPI: Sendable {
    let context: UmamiAPIContext

    public func login(username: String, password: String) async throws -> UmamiLoginResponse {
        struct Body: Sendable, Encodable {
            let username: String
            let password: String
        }

        return try await context.transport.send(
            .json(
                method: "POST",
                path: "/api/auth/login",
                body: .json(Body(username: username, password: password))
            )
        )
    }

    public func verify() async throws -> UmamiUser {
        try await context.transport.send(
            .json(method: "POST", path: "/api/auth/verify", auth: context.auth)
        )
    }

    public func logout() async throws -> UmamiOKResponse {
        try await context.transport.send(
            .json(method: "POST", path: "/api/auth/logout", auth: context.auth)
        )
    }
}
