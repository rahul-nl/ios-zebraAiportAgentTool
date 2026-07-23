import Foundation

private struct AnyStringMap: Encodable {
    let values: [String: String]

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: DynamicCodingKey.self)
        for (key, value) in values {
            try container.encode(value, forKey: DynamicCodingKey(stringValue: key))
        }
    }

    struct DynamicCodingKey: CodingKey {
        var stringValue: String
        init?(stringValue: String) { self.stringValue = stringValue }
        var intValue: Int? { nil }
        init?(intValue: Int) { nil }
    }
}

final class AuthService {
    private let config: RuntimeConfig
    private let httpClient: HTTPClient

    init(config: RuntimeConfig, httpClient: HTTPClient = HTTPClient()) {
        self.config = config
        self.httpClient = httpClient
    }

    func fetchAccessToken() async throws -> String {
        guard let url = URL(string: config.authBaseUrl + config.authTokenPath) else {
            throw AppError.config("Invalid auth URL")
        }

        let body = AnyStringMap(values: config.authBodyTemplate)
        let response: TokenResponse = try await httpClient.send(
            url: url,
            method: config.authMethod,
            headers: config.authHeaders,
            body: body,
            timeoutSeconds: config.requestTimeoutSeconds,
            responseType: TokenResponse.self
        )

        guard !response.access_token.isEmpty else {
            throw AppError.network("Token API returned empty access_token")
        }

        return response.access_token
    }
}
