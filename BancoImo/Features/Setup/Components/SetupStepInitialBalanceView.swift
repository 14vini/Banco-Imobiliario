//
//  SetupStepInitialBalanceView.swift
//  BancoImo
//
//  Created by iOS Senior Developer.
//

import SwiftUI

/// Passo 1 do Onboarding: Definição do Saldo Inicial da partida com Visor LCD 3D e Presets Táteis.
struct SetupStepInitialBalanceView: View {
    @Bindable var viewModel: GameViewModel
    let onNext: () -> Void
    
    @State private var manualText: String = "1500"
    @FocusState private var isFieldFocused: Bool
    
    private let presets: [Decimal] = [1000, 1500, 2000, 2500]
    
    var body: some View {
        VStack(spacing: 20) {
            // MARK: - Cabeçalho do Passo
            VStack(spacing: 6) {
                Text("Saldo Inicial da Mesa")
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundStyle(Color.white)
                    .multilineTextAlignment(.center)
                
                Text("Escolha a quantia em dinheiro que cada jogador receberá do banco para iniciar a partida.")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 10)
            }
            .padding(.top, 8)
            
            // MARK: - Visor Digital 3D Chanfrado (LCD Display)
            ZStack {
                // Moldura com Chanfro Escuro
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.08, green: 0.09, blue: 0.13),
                                Color(red: 0.14, green: 0.16, blue: 0.22)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(AppTheme.strokeBlack, lineWidth: 2.2)
                    )
                    .shadow(color: Color.black.opacity(0.25), radius: 6, x: 0, y: 3)
                
                // Reflexo de Luz no Vidro
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.25), Color.clear, Color.white.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
                    .padding(2)
                
                HStack(alignment: .center, spacing: 10) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("VALOR INICIAL POR JOGADOR")
                            .font(.system(size: 9.5, weight: .black, design: .rounded))
                            .foregroundStyle(Color.white.opacity(0.65))
                            .tracking(1.2)
                        
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("R$")
                                .font(.system(size: 24, weight: .heavy, design: .rounded))
                                .foregroundStyle(AppTheme.actionYellow.opacity(0.7))
                            
                            TextField("1500", text: $manualText)
                                .font(.system(size: 34, weight: .heavy, design: .rounded))
                                .foregroundStyle(AppTheme.actionYellow)
                                .keyboardType(.numberPad)
                                .focused($isFieldFocused)
                                .shadow(color: AppTheme.actionYellow.opacity(0.4), radius: 4, x: 0, y: 0)
                                .onChange(of: manualText) { _, newValue in
                                    let filtered = newValue.filter { "0123456789".contains($0) }
                                    if let val = Decimal(string: filtered), val > 0 {
                                        viewModel.updateInitialBalance(val)
                                    }
                                }
                        }
                    }
                    
                    Spacer()
                    
                    if isFieldFocused {
                        Tactile3DButton(
                            faceGradient: AppTheme.actionYellowGradient,
                            depthColor: AppTheme.actionYellowDark,
                            cornerRadius: 12,
                            depth: 3.5,
                            strokeWidth: 1.5,
                            highlightColor: Color.white.opacity(0.7),
                            action: {
                                isFieldFocused = false
                                HapticManager.impact(.light)
                                SoundManager.play(.buttonTap)
                            }
                        ) {
                            Text("OK")
                                .font(.system(size: 13, weight: .heavy, design: .rounded))
                                .foregroundStyle(AppTheme.strokeBlack)
                                .padding(.horizontal, 14)
                                .frame(height: 32)
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
            }
            .frame(height: 84)
            
            // MARK: - Fichas / Presets Táteis em 3D
            VStack(alignment: .leading, spacing: 10) {
                Text("Valores Rápidos de Tabuleiro:")
                    .font(.caption.weight(.heavy))
                    .foregroundStyle(Color.white.opacity(0.85))
                
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                    ForEach(presets, id: \.self) { amount in
                        let isSelected = viewModel.initialBalance == amount
                        let isStandard = amount == 1500
                        
                        Tactile3DButton(
                            faceGradient: isSelected
                                ? AppTheme.actionYellowGradient
                                : LinearGradient(colors: [Color.white, Color(red: 0.94, green: 0.95, blue: 0.98)], startPoint: .top, endPoint: .bottom),
                            depthColor: isSelected
                                ? AppTheme.actionYellowDark
                                : Color(red: 0.78, green: 0.81, blue: 0.88),
                            cornerRadius: 14,
                            depth: 4.5,
                            strokeColor: AppTheme.strokeBlack,
                            strokeWidth: isSelected ? 2.0 : 1.6,
                            highlightColor: isSelected ? Color.white.opacity(0.7) : Color.white.opacity(0.8),
                            action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                    viewModel.updateInitialBalance(amount)
                                    manualText = "\(NSDecimalNumber(decimal: amount).intValue)"
                                    HapticManager.selection()
                                    SoundManager.play(.keypadTap)
                                }
                            }
                        ) {
                            VStack(spacing: 2) {
                                Text(amount.asCurrency)
                                    .font(.system(size: 17, weight: .black, design: .rounded))
                                    .foregroundStyle(AppTheme.strokeBlack)
                                
                                Text(isStandard ? "Padrão Clássico" : (amount == 2500 ? "Partida Rápida" : "Personalizado"))
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(isSelected ? AppTheme.strokeBlack.opacity(0.8) : AppTheme.textSecondary)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                        }
                    }
                }
            }
            
            // MARK: - Dica Informativa
            HStack(spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(AppTheme.actionYellow)
                
                Text("A regra oficial do Banco Imobiliário recomenda **R$ 1.500** por jogador.")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color.white.opacity(0.88))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.18))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.15), lineWidth: 1))
            
            Spacer(minLength: 10)
            
            // MARK: - Botão de Avançar 3D
            Tactile3DButton(
                faceGradient: AppTheme.actionYellowGradient,
                depthColor: AppTheme.actionYellowDark,
                cornerRadius: 18,
                depth: 5.0,
                strokeColor: AppTheme.strokeBlack,
                strokeWidth: 2.0,
                highlightColor: Color.white.opacity(0.7),
                action: {
                    SoundManager.play(.buttonTap)
                    onNext()
                }
            ) {
                HStack(spacing: 8) {
                    Text("Avançar: Adicionar Jogadores")
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                    
                    Image(systemName: "arrow.right")
                        .font(.system(size: 15, weight: .black))
                }
                .foregroundStyle(AppTheme.strokeBlack)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
        .onAppear {
            manualText = "\(NSDecimalNumber(decimal: viewModel.initialBalance).intValue)"
        }
    }
}

#Preview {
    ZStack {
        AppTheme.canvasBackground.ignoresSafeArea()
        SetupStepInitialBalanceView(viewModel: GameViewModel(), onNext: {})
    }
}
