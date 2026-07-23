import Foundation
import Combine
import ExternalAccessory
#if canImport(UIKit)
import UIKit
#endif

struct ZebraAccessory: Identifiable, Equatable {
    let id: String
    let name: String
    let manufacturer: String
    let serialNumber: String

    init(accessory: EAAccessory) {
        let fallbackName = accessory.name.isEmpty ? "Unknown Zebra Device" : accessory.name
        let fallbackSerial = accessory.serialNumber.isEmpty ? "unknown-serial" : accessory.serialNumber

        id = "\(fallbackSerial)-\(accessory.connectionID)"
        name = fallbackName
        manufacturer = accessory.manufacturer
        serialNumber = fallbackSerial
    }
}

@MainActor
final class PrintViewModel: ObservableObject {
    @Published var pnr: String = ""
    @Published var printerSerial: String = ""
    @Published var connectedDevices: [ZebraAccessory] = []
    @Published var selectedDeviceSerial: String = "" {
        didSet {
            guard !selectedDeviceSerial.isEmpty else { return }
            printerSerial = selectedDeviceSerial
        }
    }
    @Published var isSearchingDevices: Bool = false
    @Published var isPrinting: Bool = false
    @Published var statusMessage: String = "Ready"

    private let coordinatorFactory: () throws -> PrintCoordinator
    private var cancellables: Set<AnyCancellable> = []
    private var didStartAccessoryMonitoring = false
    private let zebraProtocol = "com.zebra.rawport"

    init(coordinatorFactory: @escaping () throws -> PrintCoordinator = ExampleUsage.buildCoordinator) {
        self.coordinatorFactory = coordinatorFactory
    }

    func applyScannedPayload(_ payload: String) {
        let raw = payload.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty else {
            statusMessage = "Scan returned empty data"
            return
        }

        if let resolvedPnr = extractLikelyPnr(from: raw) {
            pnr = resolvedPnr
            statusMessage = "PNR captured from scan"
        } else {
            statusMessage = "Barcode scanned, but PNR could not be isolated. Enter or edit the PNR manually."
        }
    }

    private func extractLikelyPnr(from text: String) -> String? {
        let uppercased = text
            .uppercased()
            .replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "\r", with: "")

        // Try IATA BCBP fixed-format extraction first (common PDF417 boarding pass).
        // Format:
        // 0: "M", 1: legs, 2...21: passenger name (20), 22: e-ticket indicator,
        // 23...29: operating carrier PNR (7 chars)
        if let bcbpPnr = extractBcbpPnr(from: uppercased) {
            return bcbpPnr
        }

        // Fallback for payloads containing explicit PNR labels.
        let labeledPattern = #"(?:PNR|RECORD\s*LOCATOR|BOOKING\s*REF)\s*[:=\-]?\s*([A-Z0-9]{5,8})"#
        if let regex = try? NSRegularExpression(pattern: labeledPattern),
           let match = regex.firstMatch(
            in: uppercased,
            options: [],
            range: NSRange(uppercased.startIndex..<uppercased.endIndex, in: uppercased)
           ),
           match.numberOfRanges > 1,
           let range = Range(match.range(at: 1), in: uppercased) {
            return String(uppercased[range])
        }

        let tokenPattern = #"[A-Z0-9]{5,8}"#
        let regex = try? NSRegularExpression(pattern: tokenPattern)
        let fullRange = NSRange(uppercased.startIndex..<uppercased.endIndex, in: uppercased)
        let matches = regex?.matches(in: uppercased, options: [], range: fullRange) ?? []

        let scoredCandidates: [(token: String, score: Int)] = matches.compactMap { match in
            guard let range = Range(match.range, in: uppercased) else { return nil }
            let token = String(uppercased[range])
            let location = match.range.location
            var score = 0

            if token.count == 6 || token.count == 7 {
                score += 3
            }

            if token.rangeOfCharacter(from: .letters) != nil && token.rangeOfCharacter(from: .decimalDigits) != nil {
                score += 2
            } else if token.rangeOfCharacter(from: .letters) != nil {
                score += 1
            }

            if uppercased.first == "M" && location >= 23 && location <= 30 {
                score += 5
            } else if location < 40 {
                score += 1
            }

            return (token, score)
        }

        return scoredCandidates
            .sorted {
                if $0.score == $1.score {
                    return $0.token.count > $1.token.count
                }
                return $0.score > $1.score
            }
            .first(where: { $0.score > 0 })?
            .token
    }

    private func extractBcbpPnr(from payload: String) -> String? {
        guard payload.count >= 30, payload.first == "M" else {
            return nil
        }

        let start = payload.index(payload.startIndex, offsetBy: 23)
        let end = payload.index(start, offsetBy: 7)
        let rawPnr = payload[start..<end]
            .filter { $0.isLetter || $0.isNumber }

        guard rawPnr.range(of: #"^[A-Z0-9]{5,8}$"#, options: .regularExpression) != nil else {
            return nil
        }

        return String(rawPnr)
    }

    func startAccessoryMonitoringIfNeeded() {
        guard !didStartAccessoryMonitoring else { return }
        didStartAccessoryMonitoring = true

        EAAccessoryManager.shared().registerForLocalNotifications()

        NotificationCenter.default.publisher(for: .EAAccessoryDidConnect)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.refreshConnectedDevices()
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .EAAccessoryDidDisconnect)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.refreshConnectedDevices()
            }
            .store(in: &cancellables)

        refreshConnectedDevices()
    }

    func refreshConnectedDevices() {
        let devices = EAAccessoryManager.shared().connectedAccessories
            .filter { $0.protocolStrings.contains(zebraProtocol) }
            .map { ZebraAccessory(accessory: $0) }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }

        connectedDevices = devices

        if let selected = devices.first(where: { $0.serialNumber == selectedDeviceSerial }) {
            selectedDeviceSerial = selected.serialNumber
            return
        }

        if let first = devices.first {
            selectedDeviceSerial = first.serialNumber
            printerSerial = first.serialNumber
        }
    }

    func searchForNewDevices() async {
        guard !isSearchingDevices else { return }

        isSearchingDevices = true
        statusMessage = "Searching for nearby Zebra devices..."

        defer { isSearchingDevices = false }

        do {
            try await showAccessoryPicker()
            refreshConnectedDevices()

            if connectedDevices.isEmpty {
                statusMessage = "No Zebra device selected. Turn on the printer and try again."
            } else {
                statusMessage = "Device list refreshed. Select a printer and print."
            }
        } catch {
            let nsError = error as NSError
            refreshConnectedDevices()

            if nsError.domain == "EABluetoothAccessoryPickerErrorDomain" {
                switch nsError.code {
                case 1:
                    if connectedDevices.isEmpty {
                        statusMessage = "Printer is already connected, but no Zebra rawport device was found in the app list. Confirm the printer supports com.zebra.rawport."
                    } else {
                        statusMessage = "Printer is already connected. Select it from the connected devices list."
                    }
                case 2:
                    if connectedDevices.isEmpty {
                        statusMessage = "No discoverable Zebra printer found. Turn the printer on, enable pairing mode, and try Search New Devices again."
                    } else {
                        statusMessage = "No new printer found. Use the already connected printer from the list below."
                    }
                case 3:
                    statusMessage = "Device search cancelled"
                default:
                    statusMessage = "Device search failed. Check that the printer is nearby, awake, and in pairing mode."
                }
            } else {
                statusMessage = "Device search failed: \(error.localizedDescription)"
            }
        }
    }

    private func showAccessoryPicker() async throws {
        #if canImport(UIKit)
        let hasActiveScene = UIApplication.shared.connectedScenes.contains { scene in
            guard let windowScene = scene as? UIWindowScene else { return false }
            return windowScene.activationState == .foregroundActive && windowScene.session.role == .windowApplication
        }

        guard hasActiveScene else {
            throw AppError.printing("Bring the app to the foreground before searching for printers.")
        }
        #endif

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            DispatchQueue.main.async {
                EAAccessoryManager.shared().showBluetoothAccessoryPicker(withNameFilter: nil) { error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: ())
                    }
                }
            }
        }
    }

    func printLabel() async {
        let trimmedPnr = pnr.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedSerial = printerSerial.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedPnr.isEmpty else {
            statusMessage = "Enter a valid PNR"
            return
        }

        guard !trimmedSerial.isEmpty else {
            statusMessage = "Enter Zebra printer serial"
            return
        }

        isPrinting = true
        statusMessage = "Printing in progress..."

        do {
            let coordinator = try coordinatorFactory()
            let result = await coordinator.processPNR(
                pnr: trimmedPnr,
                printerSerial: trimmedSerial
            )

            switch result.status {
            case .printed:
                if let jobId = result.jobId, !jobId.isEmpty {
                    statusMessage = "Printed. Job: \(jobId)"
                } else {
                    statusMessage = "Printed successfully"
                }
            case .accepted:
                statusMessage = result.message
            case .failed:
                statusMessage = "Failed: \(result.message)"
            }
        } catch {
            statusMessage = "Setup failed: \(error.localizedDescription)"
        }

        isPrinting = false
    }
}
