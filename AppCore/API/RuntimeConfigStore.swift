import Foundation

final class RuntimeConfigStore {
    private let userDefaults: UserDefaults

    private enum Keys {
        static let authBaseUrl = "api.authBaseUrl"
        static let authTokenPath = "api.authTokenPath"
        static let zplBaseUrl = "api.zplBaseUrl"
        static let zplPath = "api.zplPath"
    }

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func mergedConfig(from bundled: RuntimeConfig) -> RuntimeConfig {
        RuntimeConfig(
            authBaseUrl: userDefaults.string(forKey: Keys.authBaseUrl) ?? bundled.authBaseUrl,
            authTokenPath: userDefaults.string(forKey: Keys.authTokenPath) ?? bundled.authTokenPath,
            authMethod: bundled.authMethod,
            authHeaders: bundled.authHeaders,
            authBodyTemplate: bundled.authBodyTemplate,
            zplBaseUrl: userDefaults.string(forKey: Keys.zplBaseUrl) ?? bundled.zplBaseUrl,
            zplPath: userDefaults.string(forKey: Keys.zplPath) ?? bundled.zplPath,
            zplMethod: bundled.zplMethod,
            zplHeaders: bundled.zplHeaders,
            zplRequiresBearerAuth: bundled.zplRequiresBearerAuth,
            defaultStationCode: bundled.defaultStationCode,
            defaultDeviceId: bundled.defaultDeviceId,
            requestTimeoutSeconds: bundled.requestTimeoutSeconds
        )
    }

    func setAuthBaseUrl(_ value: String) { userDefaults.set(value, forKey: Keys.authBaseUrl) }
    func setAuthTokenPath(_ value: String) { userDefaults.set(value, forKey: Keys.authTokenPath) }
    func setZplBaseUrl(_ value: String) { userDefaults.set(value, forKey: Keys.zplBaseUrl) }
    func setZplPath(_ value: String) { userDefaults.set(value, forKey: Keys.zplPath) }
}
