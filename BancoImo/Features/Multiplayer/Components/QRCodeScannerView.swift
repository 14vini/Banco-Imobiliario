//
//  QRCodeScannerView.swift
//  BancoImo
//
//  Created by iOS Senior Developer.
//

import SwiftUI
import AVFoundation

/// View interativa de escaneamento de QR Code com suporte a câmera ao vivo, busca de mesas próximas e entrada manual de PIN.
struct QRCodeScannerView: View {
    let onScannedQR: (String) -> Void
    let onCancel: () -> Void
    
    @State private var multipeerService = MultipeerGameService.shared
    @State private var manualPinInput: String = ""
    @State private var isCameraAuthorized: Bool = AVCaptureDevice.authorizationStatus(for: .video) == .authorized
    @State private var scanLaserOffset: CGFloat = -110
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.canvasBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // MARK: 1. Topo & Instrução
                    VStack(spacing: 6) {
                        Text("Conectar à Mesa")
                            .font(.system(size: 24, weight: .heavy, design: .rounded))
                            .foregroundStyle(AppTheme.strokeBlack)
                        
                        Text("Aponte para o QR Code no iPad central ou selecione uma mesa abaixo")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(AppTheme.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                    .padding(.top, 12)
                    
                    // MARK: 2. Viewfinder do Scanner de Câmera
                    ZStack {
                        // Câmera / Fallback de Simulador
                        #if targetEnvironment(simulator)
                        simulatorCameraPlaceholder
                        #else
                        if isCameraAuthorized {
                            CameraScannerRepresentable { scannedCode in
                                handleScannedCode(scannedCode)
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        } else {
                            cameraPermissionPlaceholder
                        }
                        #endif
                        
                        // Moldura Neo-Brutalist & Retículos de Foco
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(AppTheme.strokeBlack, lineWidth: 3.5)
                        
                        // Barra Laser Animada de Varredura
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        AppTheme.actionYellow.opacity(0),
                                        AppTheme.actionYellow,
                                        AppTheme.actionYellow.opacity(0)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(height: 3)
                            .shadow(color: AppTheme.actionYellow, radius: 4)
                            .offset(y: scanLaserOffset)
                            .onAppear {
                                withAnimation(
                                    .easeInOut(duration: 1.8)
                                    .repeatForever(autoreverses: true)
                                ) {
                                    scanLaserOffset = 110
                                }
                            }
                    }
                    .frame(width: 250, height: 250)
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(AppTheme.strokeBlack)
                            .offset(x: 4, y: 5)
                    )
                    
                    // MARK: 3. Entrada Manual de PIN
                    HStack(spacing: 10) {
                        TextField("Código PIN da Sala (ex: A1B2C3)", text: $manualPinInput)
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(AppTheme.strokeBlack, lineWidth: 1.8)
                            )
                        
                        Button {
                            guard !manualPinInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                            SoundManager.play(.buttonTap)
                            HapticManager.impact(.medium)
                            
                            let cleanPin = manualPinInput.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
                            multipeerService.startClient(targetSessionId: cleanPin)
                            onScannedQR(cleanPin)
                        } label: {
                            Text("Entrar")
                                .font(.system(size: 13, weight: .heavy, design: .rounded))
                                .foregroundStyle(AppTheme.strokeBlack)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(AppTheme.actionYellow)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(AppTheme.strokeBlack, lineWidth: 1.8)
                                )
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // MARK: 4. Lista de Mesas Próximas Encontradas por P2P
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(AppTheme.actionGreen)
                                .frame(width: 8, height: 8)
                            Text("MESAS PRÓXIMAS (WI-FI / BLUETOOTH)")
                                .font(.system(size: 10, weight: .black, design: .rounded))
                                .foregroundStyle(AppTheme.strokeBlack.opacity(0.8))
                                .tracking(0.8)
                        }
                        
                        if multipeerService.discoveredHosts.isEmpty {
                            HStack {
                                Spacer()
                                VStack(spacing: 4) {
                                    ProgressView()
                                        .tint(AppTheme.strokeBlack)
                                    Text("Buscando mesas na rede local...")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(AppTheme.textSecondary)
                                }
                                .padding(.vertical, 12)
                                Spacer()
                            }
                            .background(Color.white.opacity(0.6))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppTheme.strokeBlack.opacity(0.2), lineWidth: 1))
                        } else {
                            ScrollView {
                                VStack(spacing: 8) {
                                    ForEach(multipeerService.discoveredHosts) { host in
                                        Button {
                                            SoundManager.play(.buttonTap)
                                            HapticManager.impact(.medium)
                                            multipeerService.connectToHost(host)
                                            onScannedQR(host.sessionId)
                                        } label: {
                                            HStack {
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(host.hostName)
                                                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                                                        .foregroundStyle(AppTheme.strokeBlack)
                                                    Text("Sala: \(host.sessionId)")
                                                        .font(.system(size: 10.5, weight: .bold, design: .monospaced))
                                                        .foregroundStyle(AppTheme.textSecondary)
                                                }
                                                Spacer()
                                                
                                                HStack(spacing: 4) {
                                                    Text("Conectar")
                                                        .font(.system(size: 11, weight: .black, design: .rounded))
                                                    Image(systemName: "chevron.right")
                                                        .font(.system(size: 10, weight: .bold))
                                                }
                                                .foregroundStyle(AppTheme.strokeBlack)
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 6)
                                                .background(AppTheme.actionGreen)
                                                .clipShape(Capsule())
                                                .overlay(Capsule().stroke(AppTheme.strokeBlack, lineWidth: 1.2))
                                            }
                                            .padding(12)
                                            .background(Color.white)
                                            .clipShape(RoundedRectangle(cornerRadius: 14))
                                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppTheme.strokeBlack, lineWidth: 1.5))
                                        }
                                    }
                                }
                            }
                            .frame(maxHeight: 120)
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer()
                }
            }
            .navigationTitle("Scanner da Mesa")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancelar") {
                        onCancel()
                    }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(AppTheme.strokeBlack)
                }
            }
            .onAppear {
                checkCameraPermission()
                multipeerService.startBrowsingTables()
            }
            .onDisappear {
                multipeerService.stopBrowsing()
            }
        }
    }
    
    private func handleScannedCode(_ code: String) {
        SoundManager.play(.salary)
        HapticManager.notification(.success)
        
        // Tenta decodificar o payload estruturado HostQRData
        if let qrData = HostQRData.decodeFromString(code) {
            multipeerService.joinViaQRCode(qrData)
            onScannedQR(qrData.sessionId)
        } else {
            // Se for um PIN puro
            multipeerService.startClient(targetSessionId: code)
            onScannedQR(code)
        }
    }
    
    private func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            isCameraAuthorized = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    self.isCameraAuthorized = granted
                }
            }
        default:
            isCameraAuthorized = false
        }
    }
    
    // MARK: - Placeholders
    
    private var simulatorCameraPlaceholder: some View {
        ZStack {
            Color(red: 0.15, green: 0.18, blue: 0.25)
            VStack(spacing: 8) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(AppTheme.actionYellow)
                Text("Modo Simulador")
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.white)
                Text("Selecione uma mesa na lista abaixo ou digite o PIN")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
        }
    }
    
    private var cameraPermissionPlaceholder: some View {
        ZStack {
            Color(red: 0.15, green: 0.18, blue: 0.25)
            VStack(spacing: 8) {
                Image(systemName: "camera.badge.ellipsis")
                    .font(.system(size: 32))
                    .foregroundStyle(AppTheme.gameCoral)
                Text("Câmera Bloqueada")
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.white)
                Text("Permita o acesso à câmera nos Ajustes do iOS ou use o código PIN")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
        }
    }
}

// MARK: - Representable de AVCaptureSession

struct CameraScannerRepresentable: UIViewControllerRepresentable {
    let onScanned: (String) -> Void
    
    func makeUIViewController(context: Context) -> CameraScannerViewController {
        let vc = CameraScannerViewController()
        vc.delegate = context.coordinator
        return vc
    }
    
    func updateUIViewController(_ uiViewController: CameraScannerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onScanned: onScanned)
    }
    
    class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        let onScanned: (String) -> Void
        private var didScan: Bool = false
        
        init(onScanned: @escaping (String) -> Void) {
            self.onScanned = onScanned
        }
        
        func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
            guard !didScan, let metadata = metadataObjects.first as? AVMetadataMachineReadableCodeObject, let code = metadata.stringValue else { return }
            didScan = true
            onScanned(code)
        }
    }
}

class CameraScannerViewController: UIViewController {
    var delegate: AVCaptureMetadataOutputObjectsDelegate?
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupCamera()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }
    
    private func setupCamera() {
        let session = AVCaptureSession()
        
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            return
        }
        
        session.addInput(input)
        
        let output = AVCaptureMetadataOutput()
        guard session.canAddOutput(output) else { return }
        
        session.addOutput(output)
        output.setMetadataObjectsDelegate(delegate, queue: DispatchQueue.main)
        output.metadataObjectTypes = [.qr]
        
        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        view.layer.addSublayer(preview)
        self.previewLayer = preview
        self.captureSession = session
        
        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        captureSession?.stopRunning()
    }
}
