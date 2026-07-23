import SwiftUI

@main
struct ZebraAirportAgentApp: App {
    init() {
        AppTheme.bootstrap()
        AppTheme.validateFontRegistration()

        Task {
            await NotificationService().requestPermission()
        }
    }

    var body: some Scene {
        WindowGroup {
            PrintScreen(viewModel: PrintViewModel())
        }
    }
}
