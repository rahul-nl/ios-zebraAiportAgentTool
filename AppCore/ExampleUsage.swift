import Foundation

final class ExampleUsage {
    static func buildCoordinator() throws -> PrintCoordinator {
        let bundledConfig = try RuntimeConfig.loadFromBundle()
        let configStore = RuntimeConfigStore()
        let config = configStore.mergedConfig(from: bundledConfig)

        let authService = AuthService(config: config)
        let zplService = ZplService(config: config)
        let printerClient = ZebraPrinterClient()

        return PrintCoordinator(
            authService: authService,
            zplService: zplService,
            printerClient: printerClient
        )
    }

    // Call this from your UI action after scan/manual entry.
    static func onPnrCaptured(_ pnr: String, printerSerial: String) {
        Task {
            let coordinator = try buildCoordinator()
            _ = await coordinator.processPNR(pnr: pnr, printerSerial: printerSerial)
        }
    }
}
