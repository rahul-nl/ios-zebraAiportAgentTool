import Foundation

final class ZplService {
    private let config: RuntimeConfig
    private let httpClient: HTTPClient

    init(config: RuntimeConfig, httpClient: HTTPClient = HTTPClient()) {
        self.config = config
        self.httpClient = httpClient
    }

    func fetchZpl(accessToken: String, pnr: String, stationCode: String? = nil, deviceId: String? = nil) async throws -> ZplResponse {
        guard let url = URL(string: config.zplBaseUrl + config.zplPath) else {
            throw AppError.config("Invalid ZPL API URL")
        }

        var headers = config.zplHeaders
        headers["Authorization"] = "Bearer \(accessToken)"

        let request = ZplRequest(
            pnr: pnr,
            stationCode: stationCode ?? config.defaultStationCode,
            deviceId: deviceId ?? config.defaultDeviceId
        )

        return try await httpClient.send(
            url: url,
            method: config.zplMethod,
            headers: headers,
            body: request,
            timeoutSeconds: config.requestTimeoutSeconds,
            responseType: ZplResponse.self
        )
    }
}
