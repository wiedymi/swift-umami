import Foundation
import UmamiCore

public actor UmamiTrackerClient {
    private let transport: any UmamiTransport
    private var cacheToken: String?

    public init(
        configuration: UmamiConfiguration,
        transport: (any UmamiTransport)? = nil
    ) {
        self.transport = transport ?? DefaultUmamiTransport(configuration: configuration)
        self.cacheToken = nil
    }

    public func currentCacheToken() -> String? {
        cacheToken
    }

    public func resetCacheToken() {
        cacheToken = nil
    }

    public func setCacheToken(_ token: String?) {
        cacheToken = token
    }

    public func track(_ event: TrackEventRequest) async throws -> TrackEventResponse {
        let payload = TrackingPayload(
            source: event.source,
            data: event.data,
            hostname: event.hostname,
            language: event.language,
            referrer: event.referrer,
            screen: event.screen,
            title: event.title,
            url: event.url,
            name: event.name,
            tag: event.tag,
            ip: event.ip,
            userAgent: event.userAgent,
            timestamp: event.timestamp,
            id: event.id,
            browser: event.browser,
            os: event.os,
            device: event.device
        )

        let response: TrackEventResponse = try await transport.send(
            .json(
                method: "POST",
                path: "/api/send",
                headers: trackingHeaders(),
                body: .json(TrackingEnvelopeBody(type: "event", payload: payload))
            )
        )
        cacheToken = response.cache
        return response
    }

    public func identify(_ request: IdentifyRequest) async throws -> TrackEventResponse {
        let payload = TrackingPayload(
            source: request.source,
            data: request.data,
            hostname: request.hostname,
            language: request.language,
            referrer: nil,
            screen: request.screen,
            title: nil,
            url: nil,
            name: nil,
            tag: nil,
            ip: request.ip,
            userAgent: request.userAgent,
            timestamp: request.timestamp,
            id: request.id,
            browser: request.browser,
            os: request.os,
            device: request.device
        )

        let response: TrackEventResponse = try await transport.send(
            .json(
                method: "POST",
                path: "/api/send",
                headers: trackingHeaders(),
                body: .json(TrackingEnvelopeBody(type: "identify", payload: payload))
            )
        )
        cacheToken = response.cache
        return response
    }

    public func flush(_ requests: [TrackingEnvelope]) async throws -> BatchTrackResponse {
        let batchPayload = requests.map { envelope -> TrackingEnvelopeBody in
            switch envelope {
            case .event(let event):
                return TrackingEnvelopeBody(
                    type: "event",
                    payload: TrackingPayload(
                        source: event.source,
                        data: event.data,
                        hostname: event.hostname,
                        language: event.language,
                        referrer: event.referrer,
                        screen: event.screen,
                        title: event.title,
                        url: event.url,
                        name: event.name,
                        tag: event.tag,
                        ip: event.ip,
                        userAgent: event.userAgent,
                        timestamp: event.timestamp,
                        id: event.id,
                        browser: event.browser,
                        os: event.os,
                        device: event.device
                    )
                )
            case .identify(let identify):
                return TrackingEnvelopeBody(
                    type: "identify",
                    payload: TrackingPayload(
                        source: identify.source,
                        data: identify.data,
                        hostname: identify.hostname,
                        language: identify.language,
                        referrer: nil,
                        screen: identify.screen,
                        title: nil,
                        url: nil,
                        name: nil,
                        tag: nil,
                        ip: identify.ip,
                        userAgent: identify.userAgent,
                        timestamp: identify.timestamp,
                        id: identify.id,
                        browser: identify.browser,
                        os: identify.os,
                        device: identify.device
                    )
                )
            }
        }

        let response: BatchTrackResponse = try await transport.send(
            .json(
                method: "POST",
                path: "/api/batch",
                headers: trackingHeaders(),
                body: .json(batchPayload)
            )
        )
        cacheToken = response.cache
        return response
    }

    private func trackingHeaders() -> [String: String] {
        guard let cacheToken else { return [:] }
        return ["x-umami-cache": cacheToken]
    }
}
