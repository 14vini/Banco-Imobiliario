//
//  GameActionCoinButton.swift
//  BancoImo
//
//  Created by iOS Senior Developer.
//

import SwiftUI

/// Tipos semânticos de ação com gradientes 3D ricos e profundidade de cunhagem tátil.
enum ActionCoinTheme {
    case green   // 🟢 Receber / Salário (+2.000)
    case coral   // 🔴 Pagar / Transferir
    case blue    // 🏢 Gestão de Imóveis & Títulos
    case yellow  // 🟡 Rolar Dados 3D
    case purple  // 🟣 Extrato & Gráficos
    case white   // ⚪ Neutro / Mais Opções
    
    var faceGradient: LinearGradient {
        switch self {
        case .green:
            return LinearGradient(
                colors: [Color(red: 0.32, green: 0.92, blue: 0.55), Color(red: 0.16, green: 0.74, blue: 0.38)],
                startPoint: .top,
                endPoint: .bottom
            )
        case .coral:
            return LinearGradient(
                colors: [Color(red: 1.0, green: 0.44, blue: 0.48), Color(red: 0.92, green: 0.22, blue: 0.28)],
                startPoint: .top,
                endPoint: .bottom
            )
        case .blue:
            return LinearGradient(
                colors: [Color(red: 0.26, green: 0.68, blue: 1.0), Color(red: 0.12, green: 0.44, blue: 0.94)],
                startPoint: .top,
                endPoint: .bottom
            )
        case .yellow:
            return LinearGradient(
                colors: [Color(red: 1.0, green: 0.82, blue: 0.26), Color(red: 0.98, green: 0.62, blue: 0.04)],
                startPoint: .top,
                endPoint: .bottom
            )
        case .purple:
            return LinearGradient(
                colors: [Color(red: 0.58, green: 0.42, blue: 1.0), Color(red: 0.42, green: 0.26, blue: 0.86)],
                startPoint: .top,
                endPoint: .bottom
            )
        case .white:
            return LinearGradient(
                colors: [Color.white, Color(red: 0.90, green: 0.92, blue: 0.96)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
    
    var depthColor: Color {
        switch self {
        case .green: return Color(red: 0.10, green: 0.52, blue: 0.26)
        case .coral: return Color(red: 0.74, green: 0.14, blue: 0.18)
        case .blue: return Color(red: 0.06, green: 0.26, blue: 0.66)
        case .yellow: return Color(red: 0.82, green: 0.46, blue: 0.0)
        case .purple: return Color(red: 0.30, green: 0.16, blue: 0.66)
        case .white: return Color(red: 0.74, green: 0.77, blue: 0.84)
        }
    }
    
    var iconColor: Color {
        switch self {
        case .green, .coral, .blue, .purple:
            return .white
        case .yellow, .white:
            return AppTheme.strokeBlack
        }
    }
    
    var highlightColor: Color {
        switch self {
        case .yellow:
            return Color.white.opacity(0.65)
        default:
            return Color.white.opacity(0.45)
        }
    }
}

/// Botão de Ação em formato de Moeda 3D Chunky com bisel chanfrado, brilho especular e afundamento físico mecânico.
struct GameActionCoinButton: View {
    let icon: String
    let label: String
    var theme: ActionCoinTheme = .yellow
    let action: () -> Void
    
    @State private var isPressed: Bool = false
    
    var coinSize: CGFloat = 56
    var depthAmount: CGFloat = 5.0
    
    var body: some View {
        Button(action: {
            SoundManager.play(.buttonTap)
            HapticManager.impact(.heavy)
            action()
        }) {
            VStack(spacing: 6) {
                ZStack(alignment: .bottom) {
                    // MARK: - 1. Sombra de Contato com o Chassi
                    Circle()
                        .fill(Color.black.opacity(isPressed ? 0.08 : 0.24))
                        .frame(width: coinSize + 2, height: coinSize)
                        .offset(y: depthAmount + (isPressed ? 1 : 3))
                        .blur(radius: isPressed ? 1.5 : 5)
                    
                    // MARK: - 2. Base Cilíndrica Extrudada (Profundidade 3D)
                    Circle()
                        .fill(theme.depthColor)
                        .frame(width: coinSize, height: coinSize)
                        .overlay(
                            Circle().stroke(AppTheme.strokeBlack, lineWidth: 2.0)
                        )
                    
                    // MARK: - 3. Face Superior Cunhada (Afunda ao tocar com mola)
                    ZStack {
                        // Corpo Principal com Gradiente
                        Circle()
                            .fill(theme.faceGradient)
                            .frame(width: coinSize, height: coinSize)
                            .overlay(
                                Circle().stroke(AppTheme.strokeBlack, lineWidth: 2.0)
                            )
                        
                        // Borda Interna / Anel de Relevo Metálico
                        Circle()
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        theme.highlightColor,
                                        theme.highlightColor.opacity(0.15),
                                        Color.clear
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 1.8
                            )
                            .padding(2.0)
                        
                        // Efeito de Centro Rebaixado (Coin Well)
                        Circle()
                            .fill(Color.black.opacity(0.06))
                            .frame(width: coinSize * 0.72, height: coinSize * 0.72)
                        
                        // Ícone em Alto-Relevo 3D
                        ZStack {
                            // Sombra do Ícone
                            Image(systemName: icon)
                                .font(.system(size: coinSize * 0.38, weight: .black))
                                .foregroundStyle(Color.black.opacity(0.25))
                                .offset(y: 1.0)
                            
                            // Ícone Principal
                            Image(systemName: icon)
                                .font(.system(size: coinSize * 0.38, weight: .black))
                                .foregroundStyle(theme.iconColor)
                        }
                    }
                    .offset(y: isPressed ? depthAmount - 1.5 : -depthAmount)
                    .scaleEffect(isPressed ? 0.98 : 1.0)
                }
                .frame(width: coinSize, height: coinSize + depthAmount)
                
                // Rótulo Tipográfico com Sombra Tátil
                Text(label)
                    .font(.system(size: 11.5, weight: .black, design: .rounded))
                    .foregroundStyle(Color.white)
                    .shadow(color: Color.black.opacity(0.35), radius: 2, x: 0, y: 1.2)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(CoinPressTrackingStyle(isPressed: $isPressed))
    }
}

/// Helper para rastrear clique suave com animação elástica
private struct CoinPressTrackingStyle: ButtonStyle {
    @Binding var isPressed: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { _, pressed in
                withAnimation(.spring(response: 0.12, dampingFraction: 0.55)) {
                    isPressed = pressed
                }
            }
    }
}

#Preview {
    ZStack {
        AppTheme.gamePeriwinkle.ignoresSafeArea()
        HStack(spacing: 14) {
            GameActionCoinButton(icon: "plus.circle.fill", label: "+2.000", theme: .green, action: {})
            GameActionCoinButton(icon: "dollarsign.arrow.circlepath", label: "Pagar", theme: .coral, action: {})
            GameActionCoinButton(icon: "die.face.5.fill", label: "Dados", theme: .yellow, action: {})
            GameActionCoinButton(icon: "chart.line.uptrend.xyaxis", label: "Extrato", theme: .purple, action: {})
        }
        .padding()
    }
}
