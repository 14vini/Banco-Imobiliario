//
//  SplashScreenView.swift
//  BancoImo
//

import SwiftUI

struct SplashScreenView: View {
    let onFinished: () -> Void
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    // Animações de entrada e ambiente
    @State private var isVisible: Bool = false
    @State private var ambientGlow: Bool = false
    @State private var cardTiltY: Double = -18.0
    @State private var cardFloatOffset: CGFloat = 0.0
    
    // Controle de progresso
    @State private var currentStepIndex: Int = 0
    
    private let steps: [LoadingStep] = [
        .init(title: "Configurando regras da partida", duration: 0.45),
        .init(title: "Distribuindo saldo inicial", duration: 0.50),
        .init(title: "Preparando a mesa de jogo", duration: 0.45),
        .init(title: "Tudo pronto!", duration: 0.30)
    ]
    
    var body: some View {
        ZStack {
            // MARK: - 1. Fundo Nobre com Iluminação Ambiente
            Color(hex: "080C14")
                .ignoresSafeArea()
            
            // Luz de topo (Spotlight sutil)
            RadialGradient(
                colors: [
                    Color(hex: "1C2C45").opacity(ambientGlow ? 0.75 : 0.45),
                    Color.clear
                ],
                center: .top,
                startRadius: 20,
                endRadius: 520
            )
            .ignoresSafeArea()
            .animation(
                reduceMotion ? .none : .easeInOut(duration: 2.5).repeatForever(autoreverses: true),
                value: ambientGlow
            )
            
            VStack(spacing: 0) {
                Spacer()
//                
//                // MARK: - 2. Cartão Holográfico / Peça de Tabuleiro de Luxo
//                PremiumCardEmblem()
//                    .offset(y: cardFloatOffset)
//                    .rotation3DEffect(
//                        .degrees(reduceMotion ? 0 : cardTiltY),
//                        axis: (x: 0.1, y: 1.0, z: 0.0),
//                        perspective: 0.5
//                    )
//                    .scaleEffect(isVisible ? 1.0 : 0.82)
//                    .opacity(isVisible ? 1.0 : 0.0)
//                    .padding(.bottom, 36)
                
                // MARK: - 3. Identidade Editorial
                VStack(spacing: 8) {
                    Text("BANCO IMOBILIÁRIO")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .tracking(4)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "F7D070"), Color(hex: "C69234")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    Text("Edição Executiva")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.45))
                }
                .opacity(isVisible ? 1.0 : 0.0)
                .offset(y: isVisible ? 0 : 12)
                
                Spacer()
                
                // MARK: - 4. Indicador de Etapas Segmentado
                VStack(spacing: 16) {
                    // Segmentos de progresso horizontais
                    HStack(spacing: 6) {
                        ForEach(0..<steps.count, id: \.self) { index in
                            Capsule()
                                .fill(
                                    index <= currentStepIndex
                                        ? Color(hex: "F7D070")
                                        : Color.white.opacity(0.12)
                                )
                                .frame(height: 3.5)
                                .animation(.spring(response: 0.35, dampingFraction: 0.7), value: currentStepIndex)
                        }
                    }
                    .frame(maxWidth: 160)
                    
                    // Texto contextual de status
                    Text(steps[currentStepIndex].title)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.75))
                        .contentTransition(.numericText())
                }
                .opacity(isVisible ? 1.0 : 0.0)
                .padding(.horizontal, 32)
                .padding(.bottom, 54)
            }
        }
        .task {
            await startSequence()
        }
    }
    
    // MARK: - Sequência Automatizada
    
    @MainActor
    private func startSequence() async {
        ambientGlow = true
        
        // Entrada visual fluida
        withAnimation(.spring(response: 0.7, dampingFraction: 0.75)) {
            isVisible = true
            cardTiltY = 0.0
        }
        
        if !reduceMotion {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true).delay(0.6)) {
                cardFloatOffset = -8
            }
        }
        
        // Execução das etapas de inicialização
        for index in steps.indices {
            let delayNanos = UInt64(steps[index].duration * 1_000_000_000)
            try? await Task.sleep(nanoseconds: delayNanos)
            guard !Task.isCancelled else { return }
            
            withAnimation(.easeInOut(duration: 0.25)) {
                currentStepIndex = index
            }
        }
        
        // Pequeno respiro antes de passar para a tela principal
        try? await Task.sleep(nanoseconds: 200_000_000)
        guard !Task.isCancelled else { return }
        
        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
            onFinished()
        }
    }
}

// MARK: - Modelo de Etapa

private struct LoadingStep {
    let title: String
    let duration: Double
}

// MARK: - Componente do Cartão/Ficha

private struct PremiumCardEmblem: View {
    var body: some View {
        ZStack {
            // Sombra difusa
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.black.opacity(0.6))
                .frame(width: 124, height: 124)
                .blur(radius: 20)
                .offset(y: 14)
            
            // Corpo do Cartão em Titânio Escuro
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "232B3A"), Color(hex: "121722")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 124, height: 124)
                .overlay(
                    // Borda chanfrada de luz
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.35),
                                    Color.white.opacity(0.08),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.2
                        )
                )
            
            // Emblema Central em Ouro Escovado
            Image(systemName: "building.columns")
                .font(.system(size: 46, weight: .medium))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(hex: "FDE8A0"), Color(hex: "D8A243"), Color(hex: "996C1B")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color(hex: "F7D070").opacity(0.25), radius: 8, y: 2)
        }
    }
}

// MARK: - Extensão de Cores Hexadecimal

private extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted))
        var int: UInt64 = 0
        scanner.scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6:
            (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: 1
        )
    }
}

#Preview {
    SplashScreenView(onFinished: {})
}
