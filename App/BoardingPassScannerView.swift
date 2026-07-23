import SwiftUI
import AVFoundation
import UIKit

struct BoardingPassScannerView: UIViewControllerRepresentable {
    var onCodeScanned: (String) -> Void
    var onError: (String) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onCodeScanned: onCodeScanned, onError: onError)
    }

    func makeUIViewController(context: Context) -> ScannerViewController {
        let viewController = ScannerViewController()
        viewController.delegate = context.coordinator
        return viewController
    }

    func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {}

    final class Coordinator: NSObject, ScannerViewControllerDelegate {
        private let onCodeScanned: (String) -> Void
        private let onError: (String) -> Void

        init(onCodeScanned: @escaping (String) -> Void, onError: @escaping (String) -> Void) {
            self.onCodeScanned = onCodeScanned
            self.onError = onError
        }

        func scannerViewController(_ controller: ScannerViewController, didScan code: String) {
            onCodeScanned(code)
        }

        func scannerViewController(_ controller: ScannerViewController, didFail message: String) {
            onError(message)
        }
    }
}

protocol ScannerViewControllerDelegate: AnyObject {
    func scannerViewController(_ controller: ScannerViewController, didScan code: String)
    func scannerViewController(_ controller: ScannerViewController, didFail message: String)
}

final class ScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    weak var delegate: ScannerViewControllerDelegate?

    private let session = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var metadataOutput: AVCaptureMetadataOutput?
    private var didCaptureCode = false
    private let guideContainer = UIView()
    private let guideBox = UIView()
    private let guideLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        ensureCameraAccessAndConfigureSession()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
        layoutGuideOverlay()
        updateRectOfInterest()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !session.isRunning {
            session.startRunning()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if session.isRunning {
            session.stopRunning()
        }
    }

    private func ensureCameraAccessAndConfigureSession() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            configureCaptureSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    guard let self else { return }
                    if granted {
                        self.configureCaptureSession()
                    } else {
                        self.delegate?.scannerViewController(self, didFail: "Camera permission denied. Enable camera access in Settings.")
                    }
                }
            }
        case .denied, .restricted:
            delegate?.scannerViewController(self, didFail: "Camera permission denied. Enable camera access in Settings.")
        @unknown default:
            delegate?.scannerViewController(self, didFail: "Unable to determine camera permission state")
        }
    }

    private func configureCaptureSession() {
        guard !session.isRunning else { return }

        guard let videoDevice = AVCaptureDevice.default(for: .video) else {
            delegate?.scannerViewController(self, didFail: "Camera is not available on this device")
            return
        }

        do {
            let videoInput = try AVCaptureDeviceInput(device: videoDevice)
            guard session.canAddInput(videoInput) else {
                delegate?.scannerViewController(self, didFail: "Unable to access camera input")
                return
            }
            session.addInput(videoInput)
        } catch {
            delegate?.scannerViewController(self, didFail: "Camera setup failed: \(error.localizedDescription)")
            return
        }

        let metadataOutput = AVCaptureMetadataOutput()
        guard session.canAddOutput(metadataOutput) else {
            delegate?.scannerViewController(self, didFail: "Unable to read barcode metadata")
            return
        }

        session.addOutput(metadataOutput)
        self.metadataOutput = metadataOutput
        metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        metadataOutput.metadataObjectTypes = [
            .qr,
            .pdf417,
            .aztec,
            .code128,
            .code39,
            .dataMatrix,
            .ean13,
            .ean8,
            .upce
        ]

        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        preview.frame = view.bounds
        view.layer.addSublayer(preview)
        previewLayer = preview
        configureGuideOverlay()
        layoutGuideOverlay()
        updateRectOfInterest()

        session.startRunning()
    }

    private func configureGuideOverlay() {
        guideContainer.backgroundColor = .clear
        guideContainer.isUserInteractionEnabled = false
        if guideContainer.superview == nil {
            view.addSubview(guideContainer)
        }

        guideBox.backgroundColor = .clear
        guideBox.layer.borderColor = UIColor.systemGreen.cgColor
        guideBox.layer.borderWidth = 3
        guideBox.layer.cornerRadius = 14
        guideBox.layer.shadowColor = UIColor.black.cgColor
        guideBox.layer.shadowOpacity = 0.25
        guideBox.layer.shadowRadius = 6
        guideBox.layer.shadowOffset = CGSize(width: 0, height: 2)
        if guideBox.superview == nil {
            guideContainer.addSubview(guideBox)
        }

        guideLabel.text = "Align boarding pass barcode inside the frame"
        guideLabel.textAlignment = .center
        guideLabel.textColor = .white
        guideLabel.backgroundColor = UIColor.black.withAlphaComponent(0.45)
        guideLabel.layer.cornerRadius = 8
        guideLabel.layer.masksToBounds = true
        guideLabel.font = .systemFont(ofSize: 14, weight: .medium)
        guideLabel.numberOfLines = 2
        if guideLabel.superview == nil {
            guideContainer.addSubview(guideLabel)
        }
    }

    private func layoutGuideOverlay() {
        guideContainer.frame = view.bounds

        let horizontalPadding: CGFloat = 24
        let width = max(220, view.bounds.width - (horizontalPadding * 2))
        let height: CGFloat = min(170, max(120, width * 0.38))
        let originX = (view.bounds.width - width) / 2
        let originY = (view.bounds.height - height) / 2 - 30

        guideBox.frame = CGRect(x: originX, y: originY, width: width, height: height)

        let labelHeight: CGFloat = 44
        guideLabel.frame = CGRect(
            x: originX,
            y: guideBox.frame.maxY + 12,
            width: width,
            height: labelHeight
        )
    }

    private func updateRectOfInterest() {
        guard let metadataOutput else { return }
        // Keep the overlay as a visual guide only. A full-frame rect is more reliable
        // across devices/orientations and avoids over-restricting detection.
        metadataOutput.rectOfInterest = CGRect(x: 0, y: 0, width: 1, height: 1)
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard !didCaptureCode else { return }

        let readableObjects = metadataObjects
            .compactMap { $0 as? AVMetadataMachineReadableCodeObject }
            .sorted { lhs, rhs in
                barcodePriority(lhs.type) < barcodePriority(rhs.type)
            }

        let payload = readableObjects
            .compactMap { $0.stringValue }
            .first { !$0.isEmpty }

        guard let payload else {
            return
        }

        didCaptureCode = true
        session.stopRunning()
        delegate?.scannerViewController(self, didScan: payload)
    }

    private func barcodePriority(_ type: AVMetadataObject.ObjectType) -> Int {
        switch type {
        case .pdf417:
            return 0
        case .aztec:
            return 1
        case .qr:
            return 2
        case .code128:
            return 3
        case .code39:
            return 4
        default:
            return 10
        }
    }
}
