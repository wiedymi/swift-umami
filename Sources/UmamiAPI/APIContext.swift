import Foundation
import UmamiCore

struct UmamiAPIContext: Sendable {
    let transport: any UmamiTransport
    let auth: UmamiAuth

    func withAuth(_ auth: UmamiAuth) -> Self {
        Self(transport: transport, auth: auth)
    }
}
