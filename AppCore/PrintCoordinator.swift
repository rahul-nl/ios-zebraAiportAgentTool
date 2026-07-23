import Foundation

final class PrintCoordinator {
    private let authService: AuthService
    private let zplService: ZplService
    private let printerClient: PrinterClient
    private let notificationService: NotificationService

    init(
        authService: AuthService,
        zplService: ZplService,
        printerClient: PrinterClient,
        notificationService: NotificationService = NotificationService()
    ) {
        self.authService = authService
        self.zplService = zplService
        self.printerClient = printerClient
        self.notificationService = notificationService
    }

    func processPNR(pnr: String, printerSerial: String, stationCode: String? = nil, deviceId: String? = nil) async -> PrintResult {
        do {
            let requiresBearerAuth = zplService.requiresBearerAuth
            let token = requiresBearerAuth ? try await authService.fetchAccessToken() : nil
            _ = stationCode
            _ = deviceId

            let zplResponse = try await zplService.fetchZpl(
                accessToken: token,
                pnr: pnr
            )

            try await printerClient.printZpl(zplResponse.zpl, printerSerial: printerSerial)

            notificationService.show(
                title: "Boarding Label Printed",
                body: "PNR \(pnr) printed successfully."
            )

            return PrintResult(
                status: .printed,
                message: "Printed successfully",
                jobId: zplResponse.jobId
            )
        } catch {
            notificationService.show(
                title: "Print Failed",
                body: error.localizedDescription
            )

            return PrintResult(
                status: .failed,
                message: error.localizedDescription,
                jobId: nil
            )
        }
    }
}
