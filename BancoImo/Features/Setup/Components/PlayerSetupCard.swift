//
//  PlayerSetupCard.swift
//  BancoImo
//
//  Created by iOS Senior Developer.
//

import SwiftUI

/// Card lúdico 3D de exibição do jogador na tela inicial com avatar em relevo, borda Neo-Brutalist e botão 3D de exclusão.
struct PlayerSetupCard: View {
    let player: Player
    var isHost: Bool = false
    var onSetHost: (() -> Void)? = nil
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 14) {
            // MARK: - Avatar Token 3D com Relevo e Sombra
            Button {
                onSetHost?()
            } label: {
                ZStack(alignment: .bottom) {
                    // Base Extrudada
                    Circle()
                        .fill(player.color.color.opacity(0.8))
                        .frame(width: 44, height: 44)
                        .overlay(Circle().stroke(AppTheme.strokeBlack, lineWidth: 1.8))
                        .offset(y: 3)
                    
                    // Face do Token com Brilho
                    ZStack {
                        Circle()
                            .fill(player.color.color.gradient)
                            .frame(width: 44, height: 44)
                            .overlay(Circle().stroke(AppTheme.strokeBlack, lineWidth: 1.8))
                        
                        Circle()
                            .strokeBorder(Color.white.opacity(0.4), lineWidth: 1.5)
                            .padding(2)
                        
                        Text(String(player.name.prefix(1)).uppercased())
                            .font(.system(size: 19, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .shadow(color: Color.black.opacity(0.35), radius: 1, x: 0, y: 1)
                    }
                }
                .frame(width: 44, height: 47)
                .shadow(color: player.color.color.opacity(0.35), radius: 4, x: 0, y: 2)
            }
            .buttonStyle(.plain)
            
            // MARK: - Informações do Jogador
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(player.name)
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)
                        .lineLimit(1)
                    
                    if isHost {
                        HStack(spacing: 3) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 8))
                            Text("ANFITRIÃO")
                                .font(.system(size: 8, weight: .black))
                        }
                        .foregroundStyle(AppTheme.strokeBlack)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(AppTheme.actionYellow)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(AppTheme.strokeBlack, lineWidth: 1))
                    }
                }
                
                HStack(spacing: 6) {
                    Circle()
                        .fill(player.color.color)
                        .frame(width: 9, height: 9)
                        .overlay(Circle().stroke(AppTheme.strokeBlack, lineWidth: 1))
                    
                    Text(player.color.displayName)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(AppTheme.textSecondary)
                    
                    Text("•")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(AppTheme.textSecondary.opacity(0.6))
                    
                    Text(player.balance.asCurrency)
                        .font(.caption.weight(.heavy))
                        .foregroundStyle(AppTheme.actionGreenDark)
                }
            }
            
            Spacer()
            
            // MARK: - Botão 3D Tátil de Remoção (Coral)
            Tactile3DButton(
                faceGradient: LinearGradient(
                    colors: [Color(red: 1.0, green: 0.92, blue: 0.92), Color(red: 0.98, green: 0.85, blue: 0.85)],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                depthColor: Color(red: 0.85, green: 0.70, blue: 0.70),
                cornerRadius: 12,
                depth: 3.5,
                strokeColor: AppTheme.strokeBlack,
                strokeWidth: 1.5,
                highlightColor: Color.white.opacity(0.8),
                action: onDelete
            ) {
                Image(systemName: "trash.fill")
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(AppTheme.actionCoral)
                    .frame(width: 32, height: 28)
            }
            .accessibilityLabel("Remover jogador \(player.name)")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AppTheme.strokeBlack, lineWidth: 1.8)
        )
        .shadow(color: Color.black.opacity(0.06), radius: 5, x: 0, y: 3)
    }
}

#Preview {
    VStack(spacing: 12) {
        PlayerSetupCard(
            player: Player(name: "Kauã Vinícius", balance: 1500, color: .blue),
            onDelete: {}
        )
        PlayerSetupCard(
            player: Player(name: "Mariana Souza", balance: 1500, color: .purple),
            onDelete: {}
        )
    }
    .padding()
    .background(AppTheme.canvasBackground)
}
