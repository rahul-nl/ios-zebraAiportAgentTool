import Foundation
#if canImport(ZSDK_API)
import ZSDK_API
#endif

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

        #if canImport(ZSDK_API)
        let connection = MfiBtPrinterConnection(serialNumber: printerSerial)

        guard connection.open() else {
            throw AppError.printing("Unable to open Zebra Bluetooth connection for serial: \(printerSerial)")
        }

        defer { connection.close() }

        var writeError: NSError?
        _ = connection.write(data, error: &writeError)

        if let writeError {
            throw AppError.printing("Zebra print write failed: \(writeError.localizedDescription)")
        }
        #else
        throw AppError.printing("Zebra SDK is not linked. Add ZSDK_API.xcframework to your Xcode target.")
        #endif
    }
}
