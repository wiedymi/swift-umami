import Foundation

public struct UmamiConfiguration: Sendable {
    public var baseURL: URL
    public var userAgent: String?
    public var executor: UmamiHTTPExecutor
    public var decoderFactory: @Sendable () -> JSONDecoder
    public var encoderFactory: @Sendable () -> JSONEncoder

    public init(
        baseURL: URL,
        userAgent: String? = nil,
        executor: UmamiHTTPExecutor = .urlSession(.shared),
        decoderFactory: @escaping @Sendable () -> JSONDecoder = { JSONDecoder.umamiDefault() },
        encoderFactory: @escaping @Sendable () -> JSONEncoder = { JSONEncoder.umamiDefault() }
    ) {
        self.baseURL = baseURL
        self.userAgent = userAgent
        self.executor = executor
        self.decoderFactory = decoderFactory
        self.encoderFactory = encoderFactory
    }
}

public struct UmamiHTTPExecutor: Sendable {
    public var execute: @Sendable (URLRequest) async throws -> (Data, HTTPURLResponse)

    public init(execute: @escaping @Sendable (URLRequest) async throws -> (Data, HTTPURLResponse)) {
        self.execute = execute
    }

    public static func urlSession(_ session: URLSession = .shared) -> Self {
        Self { request in
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw UmamiTransportError.invalidResponse
            }

            return (data, httpResponse)
        }
    }
}

extension JSONDecoder {
    public static func umamiDefault() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()

            if let timestamp = try? container.decode(Double.self) {
                return umamiDate(fromTimestamp: timestamp)
            }

            let string = try container.decode(String.self)

            if let date = umamiParseDate(string)
            {
                return date
            }

            if let timestamp = Double(string) {
                return umamiDate(fromTimestamp: timestamp)
            }

            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unsupported Umami date value: \(string)"
            )
        }
        return decoder
    }
}

func umamiDate(fromTimestamp timestamp: Double) -> Date {
    let absolute = abs(timestamp)
    let seconds = absolute >= 1_000_000_000_000 ? timestamp / 1000.0 : timestamp
    return Date(timeIntervalSince1970: seconds)
}

extension JSONEncoder {
    public static func umamiDefault() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

func umamiParseDate(_ string: String) -> Date? {
    let fractional = ISO8601DateFormatter()
    fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

    if let date = fractional.date(from: string) {
        return date
    }

    let basic = ISO8601DateFormatter()
    basic.formatOptions = [.withInternetDateTime]
    return basic.date(from: string)
}

func umamiISO8601String(from date: Date) -> String {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime]
    return formatter.string(from: date)
}
