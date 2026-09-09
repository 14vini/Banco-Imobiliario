//
//  ColorChip.swift
//  BancoImo
//
//  Created by iOS Senior Developer.
//

import SwiftUI

/// Componente visual circular para seleção de cor do jogador com estética de Peão/Token 3D de Tabuleiro.
struct ColorChip: View {
    let color: PlayerColor
    let isSelected: Bool
    let isUsedByAnotherPlayer: Bool
    let onSelect: () -> Void
    
    @State private var isPressed: Bool = false
    
    private let tokenSize: CGFloat = 38
    private let depth: CGFloat = 3.5
    
    var body: some View {
        Button(action: {
            if !isUsedByAnotherPlayer {
                onSelect()
            }
        }) {
            ZStack(alignment: .bottom) {
                // MARK: 1. Base Extrudada 3D do Token
                Circle()
                    .fill(isUsedByAnotherPlayer ? Color(white: 0.6) : color.color.opacity(0.85))
                    .frame(width: tokenSize, height: tokenSize)
                    .overlay(
                        Circle().stroke(AppTheme.strokeBlack, lineWidth: 1.8)
                    )
                
                // MARK: 2. Face Superior do Token com Bisel de Luz
                ZStack {
                    // Face Colorida com Gradiente
                    Circle()
                        .fill(isUsedByAnotherPlayer ? Color.gray.gradient : color.color.gradient)
                        .frame(width: tokenSize, height: tokenSize)
                        .overlay(
                            Circle().stroke(AppTheme.strokeBlack, lineWidth: 1.8)
                        )
                    
                    // Bisel / Brilho de Reflexo Superior
                    Circle()
                        .strokeBorder(Color.white.opacity(isUsedByAnotherPlayer ? 0.2 : 0.45), lineWidth: 1.5)
                        .padding(2)
                    
                    // Centro Rebaixado Sutil
                    Circle()
                        .fill(Color.black.opacity(0.06))
                        .frame(width: tokenSize * 0.65, height: tokenSize * 0.65)
                    
                    if isSelected {
                        // Ícone de Selecionado em Alto-Relevo
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .black))
                            .foregroundStyle(.white)
                            .shadow(color: Color.black.opacity(0.4), radius: 1, x: 0, y: 1)
                    } else if isUsedByAnotherPlayer {
                        // Ícone de Já Utilizado
                        Image(systemName: "person.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white.opacity(0.85))
                    }
                }
                .offset(y: isSelected ? -(depth + 1.5) : (isPressed ? 0 : -depth))
                .scaleEffect(isSelected ? 1.08 : 1.0)
            }
            .frame(width: tokenSize + 4, height: tokenSize + depth + 4)
            .shadow(
                color: isSelected ? color.color.opacity(0.45) : Color.black.opacity(0.12),
                radius: isSelected ? 5 : 2,
                x: 0,
                y: isSelected ? 3 : 1
            )
        }
        .buttonStyle(ColorChipPressStyle(isPressed: $isPressed))
        .disabled(isUsedByAnotherPlayer)
        .accessibilityLabel("Cor \(color.displayName)\(isSelected ? ", selecionada" : "")\(isUsedByAnotherPlayer ? ", já utilizada" : "")")
    }
}

private struct ColorChipPressStyle: ButtonStyle {
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
        AppTheme.canvasBackground.ignoresSafeArea()
        HStack(spacing: 14) {
            ColorChip(color: .blue, isSelected: true, isUsedByAnotherPlayer: false, onSelect: {})
            ColorChip(color: .red, isSelected: false, isUsedByAnotherPlayer: true, onSelect: {})
            ColorChip(color: .green, isSelected: false, isUsedByAnotherPlayer: false, onSelect: {})
            ColorChip(color: .yellow, isSelected: false, isUsedByAnotherPlayer: false, onSelect: {})
        }
        .padding()
    }
}
