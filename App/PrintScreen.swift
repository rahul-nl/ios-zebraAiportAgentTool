import SwiftUI

struct PrintScreen: View {
    @StateObject private var viewModel: PrintViewModel
    @State private var isScannerPresented = false

    init(viewModel: PrintViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("Boarding Label Print")
                    .appFont(.title)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Printer Discovery")
                        .appFont(.body)

                    HStack(spacing: 10) {
                        Button {
                            Task {
                                await viewModel.searchForNewDevices()
                            }
                        } label: {
                            Text(viewModel.isSearchingDevices ? "Searching..." : "Search New Devices")
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(viewModel.isSearchingDevices || viewModel.isPrinting)

                        Button {
                            viewModel.refreshConnectedDevices()
                        } label: {
                            Text("Refresh")
                        }
                        .buttonStyle(.bordered)
                        .disabled(viewModel.isSearchingDevices || viewModel.isPrinting)
                    }

                    if viewModel.connectedDevices.isEmpty {
                        Text("No connected Zebra printers")
                            .appFont(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Picker("Connected Zebra Printer", selection: $viewModel.selectedDeviceSerial) {
                            ForEach(viewModel.connectedDevices) { device in
                                Text("\(device.name) (\(device.serialNumber))")
                                    .tag(device.serialNumber)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }

                TextField("PNR", text: $viewModel.pnr)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .textFieldStyle(.roundedBorder)

                Button {
                    isScannerPresented = true
                } label: {
                    Text("Scan Boarding Pass")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.isPrinting || viewModel.isSearchingDevices)

                TextField("Zebra Serial Number", text: $viewModel.printerSerial)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .textFieldStyle(.roundedBorder)

                Button {
                    Task {
                        await viewModel.printLabel()
                    }
                } label: {
                    HStack {
                        Spacer()
                        if viewModel.isPrinting {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.white)
                        } else {
                            Text("Print")
                                .appFont(.body)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 10)
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isPrinting)

                Text(viewModel.statusMessage)
                    .appFont(.caption)
                    .foregroundStyle(.secondary)

                Spacer(minLength: 0)
            }
            .padding(20)
            .navigationTitle("Zebra Agent")
        }
        .task {
            viewModel.startAccessoryMonitoringIfNeeded()
        }
        .sheet(isPresented: $isScannerPresented) {
            NavigationStack {
                BoardingPassScannerView(
                    onCodeScanned: { payload in
                        viewModel.applyScannedPayload(payload)
                        isScannerPresented = false
                    },
                    onError: { message in
                        viewModel.statusMessage = message
                        isScannerPresented = false
                    }
                )
                .ignoresSafeArea()
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Close") {
                            isScannerPresented = false
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    PrintScreen(viewModel: PrintViewModel())
}
