//
//  Tactile3DButton.swift
//  BancoImo
//
//  Created by iOS Senior Developer.
//

import SwiftUI

// MARK: - Estilo Base de Botão 3D Mecânico Tátil

/// Estilo de botão 3D com física mecânica realista, bisel de luz especular, paredes laterais extrudadas e afundamento elástico ao toque.
struct Tactile3DPushButtonStyle: ButtonStyle {
    let faceGradient: LinearGradient
    let depthColor: Color
    let cornerRadius: CGFloat
    let depth: CGFloat
    let strokeColor: Color
    let strokeWidth: CGFloat
    let highlightColor: Color
    
    init(
        faceGradient: LinearGradient,
        depthColor: Color,
        cornerRadius: CGFloat = 16,
        depth: CGFloat = 6,
        strokeColor: Color = AppTheme.strokeBlack,
        strokeWidth: CGFloat = 2.0,
        highlightColor: Color = Color.white.opacity(0.4)
    ) {
        self.faceGradient = faceGradient
        self.depthColor = depthColor
        self.cornerRadius = cornerRadius
        self.depth = depth
        self.strokeColor = strokeColor
        self.strokeWidth = strokeWidth
        self.highlightColor = highlightColor
    }
    
    init(
        faceColor: Color,
        depthColor: Color,
        cornerRadius: CGFloat = 16,
        depth: CGFloat = 6,
        strokeColor: Color = AppTheme.strokeBlack,
        strokeWidth: CGFloat = 2.0,
        highlightColor: Color = Color.white.opacity(0.4)
    ) {
        self.faceGradient = LinearGradient(
            colors: [faceColor, faceColor.opacity(0.92)],
            startPoint: .top,
            endPoint: .bottom
        )
        self.depthColor = depthColor
        self.cornerRadius = cornerRadius
        self.depth = depth
        self.strokeColor = strokeColor
        self.strokeWidth = strokeWidth
        self.highlightColor = highlightColor
    }
    
    func makeBody(configuration: Configuration) -> some View {
        let isPressed = configuration.isPressed
        let currentOffset: CGFloat = isPressed ? (depth - 1.5) : 0
        let shadowRadius: CGFloat = isPressed ? 1.5 : 4.0
        
        ZStack(alignment: .bottom) {
            // MARK: 1. Base Sólida de Profundidade 3D
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(depthColor)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(strokeColor, lineWidth: strokeWidth)
                )
                .shadow(color: Color.black.opacity(isPressed ? 0.08 : 0.22), radius: shadowRadius, x: 0, y: isPressed ? 1 : 3)
            
            // MARK: 2. Face Superior Colorida que Afunda
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(faceGradient)
                
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                highlightColor,
                                highlightColor.opacity(0.1),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: strokeWidth * 0.9
                    )
                    .padding(strokeWidth * 0.5)
                
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(strokeColor, lineWidth: strokeWidth)
                
                configuration.label
            }
            .padding(.bottom, depth)
            .offset(y: currentOffset)
            .scaleEffect(isPressed ? 0.985 : 1.0)
        }
        .fixedSize(horizontal: false, vertical: true)
        .animation(.spring(response: 0.12, dampingFraction: 0.55), value: isPressed)
        .onChange(of: isPressed) { _, pressed in
            if pressed {
                HapticManager.impact(.medium)
            }
        }
    }
}

// MARK: - Botão 3D Genérico com Visual Tátil

struct Tactile3DButton<Content: View>: View {
    let faceGradient: LinearGradient
    let depthColor: Color
    var cornerRadius: CGFloat = 16
    var depth: CGFloat = 6
    var strokeColor: Color = AppTheme.strokeBlack
    var strokeWidth: CGFloat = 2.0
    var highlightColor: Color = Color.white.opacity(0.4)
    let action: () -> Void
    let label: () -> Content
    
    init(
        faceColor: Color,
        depthColor: Color,
        cornerRadius: CGFloat = 16,
        depth: CGFloat = 6,
        strokeColor: Color = AppTheme.strokeBlack,
        strokeWidth: CGFloat = 2.0,
        highlightColor: Color = Color.white.opacity(0.4),
        action: @escaping () -> Void,
        @ViewBuilder label: @escaping () -> Content
    ) {
        self.faceGradient = LinearGradient(
            colors: [faceColor, faceColor.opacity(0.90)],
            startPoint: .top,
            endPoint: .bottom
        )
        self.depthColor = depthColor
        self.cornerRadius = cornerRadius
        self.depth = depth
        self.strokeColor = strokeColor
        self.strokeWidth = strokeWidth
        self.highlightColor = highlightColor
        self.action = action
        self.label = label
    }
    
    init(
        faceGradient: LinearGradient,
        depthColor: Color,
        cornerRadius: CGFloat = 16,
        depth: CGFloat = 6,
        strokeColor: Color = AppTheme.strokeBlack,
        strokeWidth: CGFloat = 2.0,
        highlightColor: Color = Color.white.opacity(0.4),
        action: @escaping () -> Void,
        @ViewBuilder label: @escaping () -> Content
    ) {
        self.faceGradient = faceGradient
        self.depthColor = depthColor
        self.cornerRadius = cornerRadius
        self.depth = depth
        self.strokeColor = strokeColor
        self.strokeWidth = strokeWidth
        self.highlightColor = highlightColor
        self.action = action
        self.label = label
    }
    
    var body: some View {
        Button(action: {
            SoundManager.play(.buttonTap)
            action()
        }) {
            label()
        }
        .buttonStyle(
            Tactile3DPushButtonStyle(
                faceGradient: faceGradient,
                depthColor: depthColor,
                cornerRadius: cornerRadius,
                depth: depth,
                strokeColor: strokeColor,
                strokeWidth: strokeWidth,
                highlightColor: highlightColor
            )
        )
    }
}

// MARK: - Tecla Numérica Mecânica 3D (Keycap Retrô Futurista)

/// Tecla de teclado numérico em 3D realista com curvatura dished, relevo gravado e mola tátil.
struct Tactile3DKeypadKey: View {
    let label: String
    var isSpecial: Bool = false
    let action: () -> Void
    
    // Gradiente da Face (Porcelana / Resina acetinada)
    private var faceGradient: LinearGradient {
        if isSpecial {
            return LinearGradient(
                colors: [Color(red: 0.93, green: 0.94, blue: 0.97), Color(red: 0.86, green: 0.88, blue: 0.93)],
                startPoint: .top,
                endPoint: .bottom
            )
        } else {
            return LinearGradient(
                colors: [Color.white, Color(red: 0.94, green: 0.95, blue: 0.98)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
    
    // Cor da Base Extrudada
    private var depthColor: Color {
        if isSpecial {
            return Color(red: 0.72, green: 0.75, blue: 0.82)
        } else {
            return Color(red: 0.78, green: 0.81, blue: 0.88)
        }
    }
    
    var body: some View {
        Tactile3DButton(
            faceGradient: faceGradient,
            depthColor: depthColor,
            cornerRadius: 14,
            depth: 5.5,
            strokeColor: AppTheme.strokeBlack,
            strokeWidth: 2.0,
            highlightColor: Color.white.opacity(0.8),
            action: {
                SoundManager.play(.keypadTap)
                action()
            }
        ) {
            ZStack {
                // Efeito côncavo sutil no centro da tecla
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(
                        RadialGradient(
                            colors: [Color.white.opacity(0.4), Color.clear],
                            center: .center,
                            startRadius: 2,
                            endRadius: 22
                        )
                    )
                    .padding(4)
                
                // Texto com Efeito Moldado / Gravado (Engraved Depth)
                ZStack {
                    // Sombra superior interna (relevo gravado)
                    Text(label)
                        .font(.system(size: isSpecial ? 19 : 22, weight: .black, design: .rounded))
                        .foregroundStyle(Color.black.opacity(0.18))
                        .offset(y: 1.2)
                    
                    // Texto Principal Nítido
                    Text(label)
                        .font(.system(size: isSpecial ? 19 : 22, weight: .black, design: .rounded))
                        .foregroundStyle(AppTheme.strokeBlack)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 42)
        }
    }
}

// MARK: - Tecla de Apagar (Backspace) 3D Mecânica

/// Tecla de Apagar em 3D mecânico com acabamento de alerta coral e ícone em alto-relevo.
struct Tactile3DBackspaceKey: View {
    let action: () -> Void
    
    private var faceGradient: LinearGradient {
        LinearGradient(
            colors: [Color(red: 1.0, green: 0.94, blue: 0.94), Color(red: 0.98, green: 0.88, blue: 0.88)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    private var depthColor: Color {
        Color(red: 0.86, green: 0.72, blue: 0.72)
    }
    
    var body: some View {
        Tactile3DButton(
            faceGradient: faceGradient,
            depthColor: depthColor,
            cornerRadius: 14,
            depth: 5.5,
            strokeColor: AppTheme.strokeBlack,
            strokeWidth: 2.0,
            highlightColor: Color.white.opacity(0.85),
            action: {
                SoundManager.play(.keypadTap)
                action()
            }
        ) {
            ZStack {
                // Sombra de relevo do ícone
                Image(systemName: "delete.backward.fill")
                    .font(.system(size: 18, weight: .black))
                    .foregroundStyle(AppTheme.actionCoralDark.opacity(0.35))
                    .offset(y: 1.2)
                
                // Ícone Principal Coral
                Image(systemName: "delete.backward.fill")
                    .font(.system(size: 18, weight: .black))
                    .foregroundStyle(AppTheme.actionCoral)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 42)
        }
    }
}

// MARK: - Chip de Preset Rápido em 3D (Token de Tabuleiro / Arcade Switch)

/// Chip de valor rápido com aspecto de ficha de jogo volumétrica 3D.
struct Tactile3DPresetChip: View {
    let label: String
    var isAccent: Bool = false
    let action: () -> Void
    
    private var faceGradient: LinearGradient {
        if isAccent {
            return LinearGradient(
                colors: [Color(red: 0.24, green: 0.88, blue: 0.50), Color(red: 0.14, green: 0.72, blue: 0.36)],
                startPoint: .top,
                endPoint: .bottom
            )
        } else {
            return LinearGradient(
                colors: [Color.white, Color(red: 0.93, green: 0.95, blue: 0.98)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
    
    private var depthColor: Color {
        if isAccent {
            return AppTheme.actionGreenDark
        } else {
            return Color(red: 0.76, green: 0.80, blue: 0.87)
        }
    }
    
    var body: some View {
        Tactile3DButton(
            faceGradient: faceGradient,
            depthColor: depthColor,
            cornerRadius: 12,
            depth: 4.5,
            strokeColor: AppTheme.strokeBlack,
            strokeWidth: 1.8,
            highlightColor: Color.white.opacity(isAccent ? 0.45 : 0.7),
            action: {
                SoundManager.play(.keypadTap)
                HapticManager.selection()
                action()
            }
        ) {
            HStack(spacing: 4) {
                if isAccent {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 10, weight: .black))
                        .foregroundStyle(Color.white)
                }
                
                Text(label)
                    .font(.system(size: 11.5, weight: .black, design: .rounded))
                    .foregroundStyle(isAccent ? Color.white : AppTheme.strokeBlack)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .padding(.horizontal, 6)
            .frame(maxWidth: .infinity)
            .frame(height: 30)
        }
    }
}

// MARK: - Botão de Ação Principal 3D Chunky (CTA Volumétrico)

/// Grande botão de ação 3D com curvatura expressiva, luz especular e alto impacto visual.
struct Tactile3DActionButton: View {
    let title: String
    let icon: String
    let gradient: LinearGradient
    let depthColor: Color
    var isDisabled: Bool = false
    let action: () -> Void
    
    private var activeGradient: LinearGradient {
        if isDisabled {
            return LinearGradient(
                colors: [Color(white: 0.82), Color(white: 0.74)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        return gradient
    }
    
    private var activeDepthColor: Color {
        if isDisabled {
            return Color(white: 0.60)
        }
        return depthColor
    }
    
    var body: some View {
        Button(action: {
            if !isDisabled {
                SoundManager.play(.moneyIn)
                action()
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .black))
                    .shadow(color: Color.black.opacity(isDisabled ? 0 : 0.25), radius: 1, x: 0, y: 1)
                
                Text(title)
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(isDisabled ? Color(white: 0.45) : Color.white)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
        }
        .buttonStyle(
            Tactile3DPushButtonStyle(
                faceGradient: activeGradient,
                depthColor: activeDepthColor,
                cornerRadius: 16,
                depth: isDisabled ? 2 : 6,
                strokeColor: AppTheme.strokeBlack,
                strokeWidth: 2.2,
                highlightColor: isDisabled ? Color.clear : Color.white.opacity(0.4)
            )
        )
        .disabled(isDisabled)
    }
}

#Preview {
    ZStack {
        AppTheme.gamePeriwinkle.ignoresSafeArea()
        
        VStack(spacing: 20) {
            HStack(spacing: 8) {
                Tactile3DPresetChip(label: "+2.000 Início", isAccent: true, action: {})
                Tactile3DPresetChip(label: "+1.000", action: {})
                Tactile3DPresetChip(label: "+500 Fiança", action: {})
            }
            
            HStack(spacing: 10) {
                Tactile3DKeypadKey(label: "7", action: {})
                Tactile3DKeypadKey(label: "8", action: {})
                Tactile3DKeypadKey(label: "9", action: {})
            }
            
            HStack(spacing: 10) {
                Tactile3DKeypadKey(label: "00", isSpecial: true, action: {})
                Tactile3DKeypadKey(label: "0", action: {})
                Tactile3DBackspaceKey(action: {})
            }
            
            HStack(spacing: 12) {
                Tactile3DActionButton(
                    title: "Receber",
                    icon: "plus.circle.fill",
                    gradient: AppTheme.actionGreenGradient,
                    depthColor: AppTheme.actionGreenDark,
                    action: {}
                )
                
                Tactile3DActionButton(
                    title: "Pagar",
                    icon: "minus.circle.fill",
                    gradient: AppTheme.actionCoralGradient,
                    depthColor: AppTheme.actionCoralDark,
                    action: {}
                )
            }
        }
        .padding()
    }
}
