//
//  MultiplayerHostModalView.swift
//  BancoImo
//
//  Created by iOS Senior Developer.
//

import SwiftUI
import MultipeerConnectivity

/// Modal exibido no iPad (Mesa Central) para gerenciamento da transmissão local P2P e pareamento por QR Code.
struct MultiplayerHostModalView: View {
    @Bindable var viewModel: GameViewModel
    @State private var multipeerService = MultipeerGameService.shared
    @Environment(\.dismiss) private var dismiss
    
    private var qrCodePayloadString: String {
        let qrData = HostQRData(
            sessionId: multipeerService.currentSessionId,
            hostName: multipeerService.myPeerID.displayName,
            gameId: UUID(),
            serviceType: MultipeerGameService.serviceType
        )
        return qrData.encodeToString() ?? multipeerService.currentSessionId
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.canvasBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // MARK: 1. QR Code 3D Neo-Brutalist
                        VStack(spacing: 8) {
                            QRCodeGeneratorView(
                                qrDataString: qrCodePayloadString,
                                sessionPin: multipeerService.currentSessionId,
                                hostName: multipeerService.myPeerID.displayName
                            )
                        }
                        .padding(.top, 12)
                        
                        // MARK: 2. Instruções Rápidas para os Amigos
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(AppTheme.actionYellow)
                                    .frame(width: 32, height: 32)
                                    .overlay(Circle().stroke(AppTheme.strokeBlack, lineWidth: 1.5))
                                Image(systemName: "iphone.gen3")
                                    .font(.system(size: 15, weight: .black))
                                    .foregroundStyle(AppTheme.strokeBlack)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Como os amigos conectam?")
                                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                                    .foregroundStyle(AppTheme.strokeBlack)
                                Text("Basta abrir o Banco Imobiliário no iPhone e tocar em \"Entrar por QR Code\".")
                                    .font(.system(size: 11.5, weight: .medium))
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                            
                            Spacer()
                        }
                        .padding(14)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(AppTheme.strokeBlack, lineWidth: 1.8)
                        )
                        .padding(.horizontal, 20)
                        
                        // MARK: 3. Dispositivos e Carteiras Conectadas
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(AppTheme.actionGreen)
                                        .frame(width: 8, height: 8)
                                        .overlay(Circle().stroke(AppTheme.strokeBlack, lineWidth: 1))
                                    
                                    Text("DISPOSITIVOS CONECTADOS (\(multipeerService.connectedDevices.count))")
                                        .font(.system(size: 11, weight: .black, design: .rounded))
                                        .foregroundStyle(AppTheme.strokeBlack.opacity(0.8))
                                        .tracking(0.8)
                                }
                                
                                Spacer()
                            }
                            
                            if multipeerService.connectedDevices.isEmpty {
                                HStack {
                                    Spacer()
                                    VStack(spacing: 6) {
                                        Image(systemName: "antenna.radiowaves.left.and.right")
                                            .font(.system(size: 24))
                                            .foregroundStyle(AppTheme.textSecondary.opacity(0.6))
                                        Text("Aguardando conexões dos iPhones...")
                                            .font(.system(size: 12, weight: .bold, design: .rounded))
                                            .foregroundStyle(AppTheme.textSecondary)
                                    }
                                    .padding(.vertical, 20)
                                    Spacer()
                                }
                                .background(Color.white.opacity(0.7))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppTheme.strokeBlack.opacity(0.2), lineWidth: 1))
                            } else {
                                VStack(spacing: 8) {
                                    ForEach(multipeerService.connectedDevices) { device in
                                        connectedDeviceRow(device)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Mesa Remota P2P")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Concluído") {
                        dismiss()
                    }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(AppTheme.strokeBlack)
                }
            }
            .onAppear {
                if multipeerService.role != .host {
                    multipeerService.startHosting(gameId: UUID())
                }
            }
        }
    }
    
    private func connectedDeviceRow(_ device: ConnectedPeerDevice) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(AppTheme.actionGreen.opacity(0.2))
                    .frame(width: 36, height: 36)
                    .overlay(Circle().stroke(AppTheme.strokeBlack, lineWidth: 1.2))
                Image(systemName: "iphone")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(AppTheme.strokeBlack)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(device.deviceDisplayName)
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundStyle(AppTheme.strokeBlack)
                
                if let claimedId = device.claimedPlayerId,
                   let player = viewModel.players.first(where: { $0.id == claimedId }) {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(player.color.color)
                            .frame(width: 8, height: 8)
                        Text("Controlando: \(player.name)")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                } else {
                    Text("Escolhendo peão...")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
            
            Spacer()
            
            Button {
                SoundManager.play(.buttonTap)
                HapticManager.impact(.light)
                multipeerService.disconnectDevice(peerName: device.peerIdName)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(AppTheme.gameCoral)
            }
        }
        .padding(12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppTheme.strokeBlack, lineWidth: 1.5))
    }
}
