//
//  QRCodeGeneratorView.swift
//  BancoImo
//
//  Created by iOS Senior Developer.
//

import SwiftUI
import CoreImage.CIFilterBuiltins

/// Componente visual para renderização do QR Code de pareamento da mesa com estilo Neo-Brutalist.
struct QRCodeGeneratorView: View {
    let qrDataString: String
    let sessionPin: String
    let hostName: String
    
    @State private var qrImage: UIImage? = nil
    @State private var didCopyPin: Bool = false
    
    private let context = CIContext()
    private let filter = CIFilter.qrCodeGenerator()
    
    var body: some View {
        VStack(spacing: 16) {
            // Container do QR Code Neo-Brutalist
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(AppTheme.strokeBlack, lineWidth: 2.8)
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(AppTheme.strokeBlack)
                            .offset(x: 4, y: 6)
                    )
                
                VStack(spacing: 14) {
                    if let image = qrImage {
                        Image(uiImage: image)
                            .interpolation(.none)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 200, height: 200)
                            .padding(12)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(AppTheme.strokeBlack.opacity(0.15), lineWidth: 1.5)
                            )
                    } else {
                        ProgressView()
                            .frame(width: 200, height: 200)
                    }
                    
                    // PIN da Mesa para Digitação Rápida ou Backup
                    HStack(spacing: 8) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("CÓDIGO DA SALA")
                                .font(.system(size: 9.5, weight: .black, design: .rounded))
                                .foregroundStyle(AppTheme.textSecondary)
                                .tracking(1)
                            
                            Text(sessionPin)
                                .font(.system(size: 20, weight: .heavy, design: .monospaced))
                                .foregroundStyle(AppTheme.strokeBlack)
                        }
                        
                        Spacer()
                        
                        Button {
                            UIPasteboard.general.string = sessionPin
                            SoundManager.play(.buttonTap)
                            HapticManager.impact(.light)
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                didCopyPin = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                didCopyPin = false
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: didCopyPin ? "checkmark" : "doc.on.doc.fill")
                                    .font(.system(size: 11, weight: .black))
                                Text(didCopyPin ? "Copiado!" : "Copiar")
                                    .font(.system(size: 11.5, weight: .bold, design: .rounded))
                            }
                            .foregroundStyle(AppTheme.strokeBlack)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(didCopyPin ? AppTheme.actionGreen : AppTheme.actionYellow)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(AppTheme.strokeBlack, lineWidth: 1.5))
                        }
                    }
                    .padding(.horizontal, 8)
                }
                .padding(20)
            }
            .frame(width: 260)
            
            // Subtítulo explicativo
            HStack(spacing: 6) {
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 13, weight: .bold))
                Text("Aponte a câmera do iPhone para entrar na mesa")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
            }
            .foregroundStyle(AppTheme.strokeBlack.opacity(0.8))
        }
        .onAppear {
            generateQRCode()
        }
        .onChange(of: qrDataString) { _, _ in
            generateQRCode()
        }
    }
    
    private func generateQRCode() {
        let data = Data(qrDataString.utf8)
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")
        
        guard let outputImage = filter.outputImage else { return }
        
        // Escala a imagem CIImage para resolução nítida
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let scaledCIImage = outputImage.transformed(by: transform)
        
        if let cgImage = context.createCGImage(scaledCIImage, from: scaledCIImage.extent) {
            self.qrImage = UIImage(cgImage: cgImage)
        }
    }
}
