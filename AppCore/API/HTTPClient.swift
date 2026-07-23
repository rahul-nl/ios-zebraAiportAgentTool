import Foundation

final class HTTPClient {
    func send<Request: Encodable, Response: Decodable>(
        url: URL,
        method: String,
        headers: [String: String],
        body: Request?,
        timeoutSeconds: Int,
        responseType: Response.Type
    ) async throws -> Response {
        var request = URLRequest(url: url, timeoutInterval: TimeInterval(timeoutSeconds))
        request.httpMethod = method.uppercased()

        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }

        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppError.network("Invalid HTTP response")
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let serverMessage = String(data: data, encoding: .utf8) ?? "No error body"
            throw AppError.network("HTTP \(httpResponse.statusCode): \(serverMessage)")
        }

        do {
            return try JSONDecoder().decode(Response.self, from: data)
        } catch {
            let bodyText = String(data: data, encoding: .utf8) ?? "<non-utf8 body>"
            throw AppError.parsing("Decoding failed: \(error.localizedDescription). Body: \(bodyText)")
        }
    }
}
