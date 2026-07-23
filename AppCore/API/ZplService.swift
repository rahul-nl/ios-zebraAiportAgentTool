import Foundation

final class ZplService {
    private let config: RuntimeConfig
    private let httpClient: HTTPClient

    var requiresBearerAuth: Bool {
        config.zplRequiresBearerAuth ?? true
    }

    init(config: RuntimeConfig, httpClient: HTTPClient = HTTPClient()) {
        self.config = config
        self.httpClient = httpClient
    }

    func fetchZpl(accessToken: String?, pnr: String) async throws -> ZplResponse {
        guard let url = URL(string: config.zplBaseUrl + config.zplPath) else {
            throw AppError.config("Invalid ZPL API URL")
        }

        var headers = config.zplHeaders
        if config.zplRequiresBearerAuth ?? true {
            guard let accessToken, !accessToken.isEmpty else {
                throw AppError.config("ZPL API requires bearer token but no token was provided")
            }

            headers["Authorization"] = "Bearer \(accessToken)"
        }

        let request = ZplRequest(pnr: pnr)

        let data = try await httpClient.sendData(
            url: url,
            method: config.zplMethod,
            headers: headers,
            body: request,
            timeoutSeconds: config.requestTimeoutSeconds
        )

        if let decoded = try? JSONDecoder().decode(ZplResponse.self, from: data) {
            return decoded
        }

        if let bodyText = String(data: data, encoding: .utf8) {
            let trimmed = bodyText.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                return ZplResponse(jobId: nil, zpl: trimmed)
            }
        }

        throw AppError.parsing("ZPL API returned an empty or unreadable response body")
    }
}
