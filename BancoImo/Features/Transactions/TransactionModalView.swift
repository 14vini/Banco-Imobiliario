//
//  TransactionModalView.swift
//  BancoImo
//
//  Created by iOS Senior Developer.
//

import SwiftUI

/// Modal de transações e pagamentos estilo Maquininha/Calculadora 3D Neo-Fintech,
/// com visor LCD 3D chanfrado com reflexo de vidro, teclado mecânico 3D, tokens de tabuleiro táteis e botões de ação com afundamento físico.
struct TransactionModalView: View {
    let viewModel: GameViewModel
    let player: Player
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedTab: Int = 0 // 0: Banco, 1: Pagar a Amigo
    @State private var targetPlayerId: UUID? = nil
    @State private var keypadValueString: String = ""
    @State private var feedbackSuccessMessage: String? = nil
    
    private var currentPlayer: Player {
        viewModel.players.first(where: { $0.id == player.id }) ?? player
    }
    
    private var otherPlayers: [Player] {
        viewModel.players.filter { $0.id != player.id && !$0.isBankrupt }
    }
    
    private var currentAmount: Decimal {
        Decimal(string: keypadValueString) ?? 0
    }
    
    private var targetPlayer: Player? {
        otherPlayers.first(where: { $0.id == targetPlayerId }) ?? otherPlayers.first
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.canvasBackground
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        // MARK: - 1. Header do Jogador
                        currentPlayerCard
                        
                        // MARK: - 2. Segmented Control estilizado
                        Picker("Tipo", selection: $selectedTab) {
                            Text("Banco (+ / -)").tag(0)
                            Text("Pagar a Amigo").tag(1)
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: selectedTab) { _, _ in
                            HapticManager.selection()
                            SoundManager.play(.buttonTap)
                        }
                        .padding(.horizontal, 20)
                        
                        if selectedTab == 1 {
                            // Seletor horizontal de amigos
                            targetPlayerSelector
                        }
                        
                        // MARK: - 3. Visor Digital do Caixa em 3D (LCD Chanfrado com Reflexo de Vidro)
                        amountDisplay3DCard
                        
                        // MARK: - 4. Pílulas de Incremento Rápido em 3D Tátil
                        quickPreset3DChips
                        
                        // MARK: - 5. Teclado Numérico 3D Mecânico (0-9, 00, ⌫)
                        keypad3DGrid
                        
                        // MARK: - 6. Botões de Ação Principal 3D Chunky
                        action3DButtonsSection
                            .padding(.top, 4)
                    }
                    .padding(.vertical, 12)
                }
                .scrollBounceBehavior(.basedOnSize)
            }
            .navigationTitle("Calculadora 3D do Caixa")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Pronto") {
                        HapticManager.impact(.light)
                        SoundManager.play(.buttonTap)
                        dismiss()
                    }
                    .font(.headline.weight(.heavy))
                    .foregroundStyle(Color.white)
                }
            }
            .onAppear {
                targetPlayerId = otherPlayers.first?.id
            }
        }
        .presentationDetents([.large])
    }
    
    // MARK: - Subviews de Layout
    
    /// Card do jogador atual e saldo
    private var currentPlayerCard: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(currentPlayer.color.color.gradient)
                    .frame(width: 40, height: 40)
                    .overlay(Circle().stroke(AppTheme.strokeBlack, lineWidth: 1.8))
                
                Circle()
                    .strokeBorder(Color.white.opacity(0.4), lineWidth: 1.5)
                    .padding(2)
                
                Text(String(currentPlayer.name.prefix(1)).uppercased())
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: Color.black.opacity(0.3), radius: 1, x: 0, y: 1)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(currentPlayer.name)
                    .font(.headline.weight(.heavy))
                    .foregroundStyle(AppTheme.textPrimary)
                
                Text("Saldo Atual: \(currentPlayer.balance.asCurrency)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppTheme.textSecondary)
            }
            
            Spacer()
            
            // Toast de Feedback
            if let msg = feedbackSuccessMessage {
                Text(msg)
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(AppTheme.strokeBlack)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(AppTheme.actionYellow)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(AppTheme.strokeBlack, lineWidth: 1))
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AppTheme.strokeBlack, lineWidth: 2.0)
        )
        .shadow(color: Color.black.opacity(0.08), radius: 5, x: 0, y: 2.5)
        .padding(.horizontal, 20)
    }
    
    /// Seletor de amigos para transferência
    private var targetPlayerSelector: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Pagar para:")
                .font(.caption2.weight(.black))
                .foregroundStyle(Color.white.opacity(0.9))
                .padding(.horizontal, 20)
            
            if otherPlayers.isEmpty {
                Text("Não há outros jogadores ativos.")
                    .font(.caption)
                    .foregroundStyle(Color.white.opacity(0.8))
                    .padding(.horizontal, 20)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(otherPlayers) { other in
                            let isSelected = targetPlayerId == other.id
                            Button {
                                HapticManager.selection()
                                SoundManager.play(.buttonTap)
                                targetPlayerId = other.id
                            } label: {
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(other.color.color)
                                        .frame(width: 12, height: 12)
                                        .overlay(Circle().stroke(AppTheme.strokeBlack, lineWidth: 1))
                                    Text(other.name)
                                        .font(.caption.weight(.heavy))
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(isSelected ? AppTheme.actionCoral.opacity(0.18) : Color.white)
                                .foregroundStyle(AppTheme.strokeBlack)
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule().stroke(isSelected ? AppTheme.actionCoral : AppTheme.strokeBlack.opacity(0.2), lineWidth: isSelected ? 2.2 : 1.2)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
    }
    
    // MARK: - Visor Digital 3D Chanfrado com Reflexo de Vidro (LCD Screen)
    
    private var amountDisplay3DCard: some View {
        ZStack {
            // 1. Moldura Chanfrada Externa (Bisel Escuro)
            RoundedRectangle(cornerRadius: 18, style: .continuous)
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
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(AppTheme.strokeBlack, lineWidth: 2.2)
                )
                .shadow(color: Color.black.opacity(0.25), radius: 6, x: 0, y: 3)
            
            // 2. Reflexo de Luz Diagonal no Vidro do LCD
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.25),
                            Color.clear,
                            Color.white.opacity(0.08)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
                .padding(2)
            
            // 3. Conteúdo do LCD com Dígitos Fosforescentes
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(selectedTab == 0 ? "VALOR NO CAIXA" : "VALOR PARA TRANSFERIR")
                        .font(.system(size: 9.5, weight: .black, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.65))
                        .tracking(1.2)
                    
                    Text(currentAmount > 0 ? currentAmount.asCurrency : "R$ 0")
                        .font(.system(size: 32, weight: .heavy, design: .rounded))
                        .foregroundStyle(currentAmount > 0 ? AppTheme.actionYellow : Color.white.opacity(0.35))
                        .shadow(color: currentAmount > 0 ? AppTheme.actionYellow.opacity(0.4) : Color.clear, radius: 4, x: 0, y: 0)
                        .lineLimit(1)
                        .minimumScaleFactor(0.55)
                }
                
                Spacer()
                
                if currentAmount > 0 {
                    Tactile3DButton(
                        faceColor: AppTheme.actionCoral,
                        depthColor: AppTheme.actionCoralDark,
                        cornerRadius: 14,
                        depth: 3.5,
                        strokeWidth: 1.5,
                        action: {
                            keypadValueString = ""
                        }
                    ) {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .black))
                            .foregroundStyle(Color.white)
                            .frame(width: 32, height: 28)
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
        }
        .frame(height: 76)
        .padding(.horizontal, 20)
    }
    
    // MARK: - Presets de Tabuleiro em 3D Tátil
    
    private var quickPreset3DChips: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
            Tactile3DPresetChip(label: "+2.000 Início", isAccent: true) { appendPreset(2000) }
            Tactile3DPresetChip(label: "+1.000") { appendPreset(1000) }
            Tactile3DPresetChip(label: "+500 Fiança") { appendPreset(500) }
            Tactile3DPresetChip(label: "+200 Lucros") { appendPreset(200) }
            Tactile3DPresetChip(label: "+100 Taxa") { appendPreset(100) }
            Tactile3DPresetChip(label: "+50") { appendPreset(50) }
        }
        .padding(.horizontal, 20)
    }
    
    private func appendPreset(_ amount: Int) {
        let current = Int(keypadValueString) ?? 0
        keypadValueString = "\(current + amount)"
    }
    
    // MARK: - Teclado Numérico 3D Mecânico
    
    private var keypad3DGrid: some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                Tactile3DKeypadKey(label: "1") { appendChar("1") }
                Tactile3DKeypadKey(label: "2") { appendChar("2") }
                Tactile3DKeypadKey(label: "3") { appendChar("3") }
            }
            HStack(spacing: 10) {
                Tactile3DKeypadKey(label: "4") { appendChar("4") }
                Tactile3DKeypadKey(label: "5") { appendChar("5") }
                Tactile3DKeypadKey(label: "6") { appendChar("6") }
            }
            HStack(spacing: 10) {
                Tactile3DKeypadKey(label: "7") { appendChar("7") }
                Tactile3DKeypadKey(label: "8") { appendChar("8") }
                Tactile3DKeypadKey(label: "9") { appendChar("9") }
            }
            HStack(spacing: 10) {
                Tactile3DKeypadKey(label: "00", isSpecial: true) { appendChar("00") }
                Tactile3DKeypadKey(label: "0") { appendChar("0") }
                Tactile3DBackspaceKey {
                    if !keypadValueString.isEmpty {
                        keypadValueString.removeLast()
                    }
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
    private func appendChar(_ char: String) {
        if keypadValueString.count < 9 {
            if keypadValueString == "0" {
                keypadValueString = char == "00" ? "0" : char
            } else {
                keypadValueString += char
            }
        }
    }
    
    // MARK: - Botões de Ação Principal 3D Chunky
    
    private var action3DButtonsSection: some View {
        Group {
            if selectedTab == 0 {
                // Aba Banco: Receber (+) ou Pagar (-) em 3D Chunky
                HStack(spacing: 12) {
                    Tactile3DActionButton(
                        title: "Receber",
                        icon: "plus.circle.fill",
                        gradient: AppTheme.actionGreenGradient,
                        depthColor: AppTheme.actionGreenDark,
                        isDisabled: currentAmount <= 0
                    ) {
                        executeBankOperation(isPositive: true)
                    }
                    
                    Tactile3DActionButton(
                        title: "Pagar",
                        icon: "minus.circle.fill",
                        gradient: AppTheme.actionCoralGradient,
                        depthColor: AppTheme.actionCoralDark,
                        isDisabled: currentAmount <= 0
                    ) {
                        executeBankOperation(isPositive: false)
                    }
                }
            } else {
                // Aba Transferência: Pagar a Amigo em 3D Chunky
                Tactile3DActionButton(
                    title: targetPlayer != nil
                    ? "Transferir \(currentAmount > 0 ? currentAmount.asCurrency : "") para \(targetPlayer!.name)"
                    : "Selecione um Jogador",
                    icon: "arrow.up.right.circle.fill",
                    gradient: AppTheme.actionCoralGradient,
                    depthColor: AppTheme.actionCoralDark,
                    isDisabled: currentAmount <= 0 || targetPlayer == nil
                ) {
                    executeTransferOperation()
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Helpers de Execução
    
    private func executeBankOperation(isPositive: Bool) {
        guard currentAmount > 0 else { return }
        let delta = isPositive ? currentAmount : -currentAmount
        withAnimation {
            viewModel.adjustBalance(for: currentPlayer.id, delta: delta)
            showFeedback(delta > 0 ? "+\(currentAmount.asCurrency)" : "-\(currentAmount.asCurrency)")
            keypadValueString = ""
        }
    }
    
    private func executeTransferOperation() {
        guard currentAmount > 0, let target = targetPlayer else { return }
        withAnimation {
            if viewModel.transferMoney(from: currentPlayer.id, to: target.id, amount: currentAmount) {
                showFeedback("Transferido \(currentAmount.asCurrency)!")
                keypadValueString = ""
            }
        }
    }
    
    private func showFeedback(_ text: String) {
        withAnimation {
            feedbackSuccessMessage = text
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                feedbackSuccessMessage = nil
            }
        }
    }
}

#Preview {
    let vm = GameViewModel()
    vm.players = [
        Player(name: "Kauã", balance: 2500, color: .blue),
        Player(name: "Mariana", balance: 1400, color: .purple)
    ]
    return TransactionModalView(viewModel: vm, player: vm.players[0])
}
