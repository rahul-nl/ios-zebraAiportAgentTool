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

        guard let data = zpl.data(using: .utf8) else {
            throw AppError.printing("Unable to encode ZPL as UTF-8")
        }

        do {
            try ZebraPrinterBridge.printZpl(data, printerSerial: printerSerial)
        } catch {
            throw AppError.printing(error.localizedDescription)
        }
    }
}
