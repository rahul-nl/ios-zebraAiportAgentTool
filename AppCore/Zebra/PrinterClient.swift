import Foundation

protocol PrinterClient {
    func printZpl(_ zpl: String, printerSerial: String) async throws
}

final class ZebraPrinterClient: PrinterClient {
    func printZpl(_ zpl: String, printerSerial: String) async throws {
        guard !zpl.isEmpty else {
            throw AppError.printing("Cannot print empty ZPL")
        }

        guard !printerSerial.isEmpty else {
            throw AppError.printing("Printer serial is required")
        }

        // Integrate actual Zebra SDK invocation in this method from your iOS target.
        // This starter keeps the API boundary clean while you wire native SDK import settings in Xcode.
        // Example SDK class to use: MfiBtPrinterConnection

        throw AppError.printing("Zebra SDK call not wired yet. Open ZebraPrinterClient and implement MfiBtPrinterConnection write flow.")
    }
}
