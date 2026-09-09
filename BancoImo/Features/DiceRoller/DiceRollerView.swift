//
//  DiceRollerView.swift
//  BancoImo
//
//  Created by iOS Senior Developer.
//

import SwiftUI

/// Componente compacto e elegante de Dados Virtuais (Dice Roller) para jogos de tabuleiro.
/// Ocupa espaço vertical mínimo, possui física 3D de rolagem, acabamento marfim tátil e detecção de duplos.
struct DiceRollerView: View {
    @Bindable var viewModel: GameViewModel
    
    @State private var isDicePressed: Bool = false
    
    private var totalSum: Int {
        viewModel.dice1 + viewModel.dice2
    }
    
    private var isDouble: Bool {
        viewModel.dice1 == viewModel.dice2
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // MARK: - 1. Par de Dados 3D Interativos (Toque Direto)
            Button {
                triggerRollWithHaptic()
            } label: {
                HStack(spacing: 8) {
                    RealisticDieView(
                        value: viewModel.dice1,
                        isRolling: viewModel.isRollingDice,
                        seed: 1
                    )
                    RealisticDieView(
                        value: viewModel.dice2,
                        isRolling: viewModel.isRollingDice,
                        seed: 2
                    )
                }
                .scaleEffect(isDicePressed ? 0.94 : 1.0)
                .animation(.spring(response: 0.25, dampingFraction: 0.6), value: isDicePressed)
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isRollingDice)
            
            // MARK: - 2. Painel Central de Informação / Resultado
            VStack(alignment: .leading, spacing: 2) {
                if viewModel.isRollingDice {
                    // Estado Rolando com animação pulsante
                    HStack(spacing: 6) {
                        Image(systemName: "die.face.5.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(AppTheme.strokeBlack)
                            .rotationEffect(.degrees(viewModel.isRollingDice ? 360 : 0))
                            .animation(.linear(duration: 0.4).repeatForever(autoreverses: false), value: viewModel.isRollingDice)
                        
                        Text("Rolando dados...")
                            .font(.system(size: 13, weight: .black, design: .rounded))
                            .foregroundStyle(AppTheme.strokeBlack)
                    }
                } else if viewModel.consecutiveDoublesCount >= 3 {
                    // Alerta de 3º Duplo (Prisão)
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 11, weight: .black))
                        Text("3º DUPLO! Vá para a Prisão")
                            .font(.system(size: 12, weight: .black, design: .rounded))
                    }
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(AppTheme.gameCoral)
                    .clipShape(Capsule())
                } else if isDouble {
                    // Comemoração de Duplo
                    VStack(alignment: .leading, spacing: 1) {
                        HStack(spacing: 4) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 10, weight: .black))
                            Text("DUPLO \(viewModel.dice1)! (Soma: \(totalSum))")
                                .font(.system(size: 12, weight: .black, design: .rounded))
                        }
                        .foregroundStyle(AppTheme.strokeBlack)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(AppTheme.gameYellow)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().stroke(AppTheme.strokeBlack, lineWidth: 1)
                        )
                        
                        Text("Jogue novamente!")
                            .font(.system(size: 10, weight: .heavy, design: .rounded))
                            .foregroundStyle(AppTheme.gameGreen)
                            .padding(.leading, 2)
                    }
                } else {
                    // Total Normal Elegante e Compacto
                    HStack(alignment: .firstTextBaseline, spacing: 5) {
                        Text("Soma:")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.textSecondary)
                        
                        Text("\(totalSum)")
                            .font(.system(size: 20, weight: .heavy, design: .rounded))
                            .foregroundStyle(AppTheme.strokeBlack)
                        
                        Text("(\(viewModel.dice1) + \(viewModel.dice2))")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundStyle(AppTheme.textSecondary.opacity(0.8))
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // MARK: - 3. Botão Rolar 3D Tátil + Botão Ocultar
            HStack(spacing: 8) {
                // Botão Rolar em 3D Tátil
                Tactile3DButton(
                    faceGradient: AppTheme.actionYellowGradient,
                    depthColor: AppTheme.actionYellowDark,
                    cornerRadius: 12,
                    depth: 4.0,
                    strokeColor: AppTheme.strokeBlack,
                    strokeWidth: 1.8,
                    highlightColor: Color.white.opacity(0.65),
                    action: {
                        triggerRollWithHaptic()
                    }
                ) {
                    HStack(spacing: 5) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 11, weight: .black))
                            .rotationEffect(.degrees(viewModel.isRollingDice ? 360 : 0))
                            .animation(.linear(duration: 0.5).repeatForever(autoreverses: false), value: viewModel.isRollingDice)
                        
                        Text(viewModel.isRollingDice ? "Rolando" : "Rolar")
                            .font(.system(size: 12, weight: .black, design: .rounded))
                    }
                    .foregroundStyle(AppTheme.strokeBlack)
                    .padding(.horizontal, 10)
                    .frame(height: 30)
                }
                .disabled(viewModel.isRollingDice)
                
                // Botão Fechar / Ocultar Bandeja
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        viewModel.isDiceEnabled = false
                        HapticManager.selection()
                        SoundManager.play(.buttonTap)
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(AppTheme.textSecondary)
                        .frame(width: 24, height: 24)
                        .background(Color.black.opacity(0.05))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Ocultar dados")
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AppTheme.strokeBlack, lineWidth: 1.5)
        )
        .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 3)
    }
    
    private func triggerRollWithHaptic() {
        withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
            isDicePressed = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                isDicePressed = false
            }
        }
        viewModel.rollDice()
    }
}

// MARK: - Componente Visual de Dado 3D com Física de Rolagem e Pips Geométricos

/// Dado 3D realista com cantos arredondados, acabamento marfim, pips proporcionais e animação de rotação multi-eixo.
struct RealisticDieView: View {
    let value: Int
    let isRolling: Bool
    let seed: Int // 1 ou 2 para dar variação física única a cada dado
    
    let size: CGFloat = 38
    
    // Estado local para interpolação de rotação 3D suave
    @State private var rollAngleX: Double = 0
    @State private var rollAngleY: Double = 0
    @State private var rollAngleZ: Double = 0
    @State private var verticalBounce: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Sombra de contato inferior
            RoundedRectangle(cornerRadius: size * 0.26, style: .continuous)
                .fill(Color.black.opacity(0.20))
                .frame(width: size, height: size)
                .offset(y: 3)
                .blur(radius: 2)
            
            // Corpo principal do Dado (Acabamento Marfim / Pearl)
            RoundedRectangle(cornerRadius: size * 0.26, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white,
                            Color(red: 0.95, green: 0.95, blue: 0.97)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
                .overlay(
                    // Borda Neo-Brutalist nítida
                    RoundedRectangle(cornerRadius: size * 0.26, style: .continuous)
                        .stroke(AppTheme.strokeBlack, lineWidth: 1.5)
                )
                .overlay(
                    // Brilho especular sutil no canto superior esquerdo
                    RoundedRectangle(cornerRadius: size * 0.26, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.8), Color.clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                        .padding(1)
                )
            
            // Pontos (Pips) de Alta Precisão Geométrica
            diePipsView(for: max(1, min(6, value)))
                .frame(width: size, height: size)
        }
        .offset(y: verticalBounce)
        .rotation3DEffect(
            .degrees(rollAngleX),
            axis: (x: 1.0, y: seed == 1 ? 0.2 : -0.2, z: 0.0),
            perspective: 0.5
        )
        .rotation3DEffect(
            .degrees(rollAngleY),
            axis: (x: 0.0, y: 1.0, z: seed == 1 ? 0.3 : -0.3),
            perspective: 0.5
        )
        .rotationEffect(.degrees(rollAngleZ))
        .onChange(of: isRolling) { _, rolling in
            if rolling {
                // Inicia o salto e rotação 3D
                withAnimation(.easeOut(duration: 0.15)) {
                    verticalBounce = -10
                }
                withAnimation(.linear(duration: 0.6)) {
                    rollAngleX += (seed == 1 ? 720 : -720)
                    rollAngleY += (seed == 1 ? 540 : -540)
                    rollAngleZ = Double.random(in: -15...15)
                }
            } else {
                // Pouso com amortecimento físico elástico
                withAnimation(.spring(response: 0.4, dampingFraction: 0.55)) {
                    verticalBounce = 0
                    rollAngleX = 0
                    rollAngleY = 0
                    rollAngleZ = Double(seed == 1 ? -3 : 3)
                }
            }
        }
    }
    
    // MARK: - Grid Geométrico 3x3 para Pips Perfeitos
    
    @ViewBuilder
    private func diePipsView(for val: Int) -> some View {
        let pipDiameter: CGFloat = size * 0.18 // ~7pt
        let centerPipDiameter: CGFloat = size * 0.23 // ~9pt para o 1 vermelho
        let pipColor = Color(red: 0.13, green: 0.13, blue: 0.15)
        
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            
            // Coordenadas relativas simétricas
            let leftX: CGFloat = w * 0.25
            let midX: CGFloat = w * 0.50
            let rightX: CGFloat = w * 0.75
            
            let topY: CGFloat = h * 0.25
            let midY: CGFloat = h * 0.50
            let botY: CGFloat = h * 0.75
            
            ZStack {
                switch val {
                case 1:
                    // 1: Ponto vermelho clássico ampliado no centro
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color(red: 0.95, green: 0.25, blue: 0.25), Color(red: 0.75, green: 0.10, blue: 0.10)],
                                center: .center,
                                startRadius: 1,
                                endRadius: centerPipDiameter / 2
                            )
                        )
                        .frame(width: centerPipDiameter, height: centerPipDiameter)
                        .position(x: midX, y: midY)
                    
                case 2:
                    // 2: Top-Left, Bottom-Right
                    singlePip(diameter: pipDiameter, color: pipColor).position(x: leftX, y: topY)
                    singlePip(diameter: pipDiameter, color: pipColor).position(x: rightX, y: botY)
                    
                case 3:
                    // 3: Diagonal completa
                    singlePip(diameter: pipDiameter, color: pipColor).position(x: leftX, y: topY)
                    singlePip(diameter: pipDiameter, color: pipColor).position(x: midX, y: midY)
                    singlePip(diameter: pipDiameter, color: pipColor).position(x: rightX, y: botY)
                    
                case 4:
                    // 4: 4 Cantos
                    singlePip(diameter: pipDiameter, color: pipColor).position(x: leftX, y: topY)
                    singlePip(diameter: pipDiameter, color: pipColor).position(x: rightX, y: topY)
                    singlePip(diameter: pipDiameter, color: pipColor).position(x: leftX, y: botY)
                    singlePip(diameter: pipDiameter, color: pipColor).position(x: rightX, y: botY)
                    
                case 5:
                    // 5: 4 Cantos + Centro
                    singlePip(diameter: pipDiameter, color: pipColor).position(x: leftX, y: topY)
                    singlePip(diameter: pipDiameter, color: pipColor).position(x: rightX, y: topY)
                    singlePip(diameter: pipDiameter, color: pipColor).position(x: midX, y: midY)
                    singlePip(diameter: pipDiameter, color: pipColor).position(x: leftX, y: botY)
                    singlePip(diameter: pipDiameter, color: pipColor).position(x: rightX, y: botY)
                    
                case 6:
                    // 6: Duas colunas de 3
                    singlePip(diameter: pipDiameter, color: pipColor).position(x: leftX, y: topY)
                    singlePip(diameter: pipDiameter, color: pipColor).position(x: rightX, y: topY)
                    singlePip(diameter: pipDiameter, color: pipColor).position(x: leftX, y: midY)
                    singlePip(diameter: pipDiameter, color: pipColor).position(x: rightX, y: midY)
                    singlePip(diameter: pipDiameter, color: pipColor).position(x: leftX, y: botY)
                    singlePip(diameter: pipDiameter, color: pipColor).position(x: rightX, y: botY)
                    
                default:
                    EmptyView()
                }
            }
        }
    }
    
    private func singlePip(diameter: CGFloat, color: Color) -> some View {
        Circle()
            .fill(color)
            .frame(width: diameter, height: diameter)
            .overlay(
                // Efeito sutil de profundidade
                Circle()
                    .stroke(Color.black.opacity(0.3), lineWidth: 0.5)
            )
    }
}

#Preview {
    let vm = GameViewModel()
    return VStack(spacing: 16) {
        DiceRollerView(viewModel: vm)
        
        HStack(spacing: 12) {
            RealisticDieView(value: 1, isRolling: false, seed: 1)
            RealisticDieView(value: 2, isRolling: false, seed: 2)
            RealisticDieView(value: 3, isRolling: false, seed: 1)
            RealisticDieView(value: 4, isRolling: false, seed: 2)
            RealisticDieView(value: 5, isRolling: false, seed: 1)
            RealisticDieView(value: 6, isRolling: false, seed: 2)
        }
    }
    .padding()
    .background(AppTheme.gamePeriwinkle)
}
