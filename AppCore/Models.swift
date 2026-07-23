import Foundation

struct RuntimeConfig: Codable {
    let authBaseUrl: String
    let authTokenPath: String
    let authMethod: String
    let authHeaders: [String: String]
    let authBodyTemplate: [String: String]

    let zplBaseUrl: String
    let zplPath: String
    let zplMethod: String
    let zplHeaders: [String: String]
    let zplRequiresBearerAuth: Bool?

    let defaultStationCode: String
    let defaultDeviceId: String
    let requestTimeoutSeconds: Int

    static func loadFromBundle(fileName: String = "runtime-config") throws -> RuntimeConfig {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "json") else {
            throw AppError.config("Missing \(fileName).json in app bundle")
        }

        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(RuntimeConfig.self, from: data)
    }
}

struct TokenResponse: Decodable {
    let access_token: String
    let token_type: String?
    let expires_in: Int?
}

struct ZplRequest: Encodable {
    let pnr: String
}

struct ZplResponse: Decodable {
    let jobId: String?
    let zpl: String
}

enum PrintStatus: String {
    case accepted
    case printed
    case failed
}

struct PrintResult {
    let status: PrintStatus
    let message: String
    let jobId: String?
}

enum AppError: Error, LocalizedError {
    case config(String)
    case network(String)
    case parsing(String)
    case printing(String)

    var errorDescription: String? {
        switch self {
        case .config(let message), .network(let message), .parsing(let message), .printing(let message):
            return message
        }
    }
}
