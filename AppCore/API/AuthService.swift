import Foundation

final class AuthService {
    private let config: RuntimeConfig

    init(config: RuntimeConfig) {
        self.config = config
    }

    func fetchAccessToken() async throws -> String {
        guard let url = URL(string: config.authBaseUrl + config.authTokenPath) else {
            throw AppError.config("Invalid auth URL")
        }

        var request = URLRequest(url: url, timeoutInterval: TimeInterval(config.requestTimeoutSeconds))
        request.httpMethod = config.authMethod.uppercased()

        config.authHeaders.forEach { request.setValue($1, forHTTPHeaderField: $0) }

        let contentType = config.authHeaders["Content-Type"]?.lowercased() ?? "application/json"
        if contentType.contains("application/x-www-form-urlencoded") {
            request.httpBody = formEncodedData(from: config.authBodyTemplate)
        } else {
            request.httpBody = try JSONEncoder().encode(config.authBodyTemplate)
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppError.network("Invalid HTTP response from token API")
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let bodyText = String(data: data, encoding: .utf8) ?? "<non-utf8 body>"
            throw AppError.network("Token API HTTP \(httpResponse.statusCode): \(bodyText)")
        }

        let responseBody: TokenResponse
        do {
            responseBody = try JSONDecoder().decode(TokenResponse.self, from: data)
        } catch {
            let bodyText = String(data: data, encoding: .utf8) ?? "<non-utf8 body>"
            throw AppError.parsing("Token decode failed: \(error.localizedDescription). Body: \(bodyText)")
        }

        guard !responseBody.access_token.isEmpty else {
            throw AppError.network("Token API returned empty access_token")
        }

        return responseBody.access_token
    }

    private func formEncodedData(from values: [String: String]) -> Data {
        let body = values
            .map { key, value in
                "\(percentEncode(key))=\(percentEncode(value))"
            }
            .joined(separator: "&")

        return Data(body.utf8)
    }

    private func percentEncode(_ value: String) -> String {
        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: ":#[]@!$&'()*+,;=")
        return value.addingPercentEncoding(withAllowedCharacters: allowed) ?? value
    }
}
