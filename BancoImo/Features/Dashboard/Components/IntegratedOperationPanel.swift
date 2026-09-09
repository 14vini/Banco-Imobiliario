//
//  IntegratedOperationPanel.swift
//  BancoImo
//
//  Created by iOS Senior Developer.
//

import SwiftUI

/// Painel de Operações / Maquininha 3D Integrada projetada para o iPad,
/// com teclado mecânico táctil 3D, visor chanfrado LCD com reflexo de vidro, tokens de tabuleiro 3D e botões de ação com afundamento físico.
struct IntegratedOperationPanel: View {
    @Bindable var viewModel: GameViewModel
    @Binding var selectedPlayerId: UUID?
    
    @State private var selectedTab: Int = 0 // 0: Banco (+ / -), 1: Pagar Amigo
    @State private var targetPlayerId: UUID? = nil
    @State private var keypadValueString: String = ""
    @State private var operationFeedbackText: String? = nil
    
    // Jogador ativo selecionado
    private var activePlayer: Player {
        if let id = selectedPlayerId, let found = viewModel.players.first(where: { $0.id == id }) {
            return found
        }
        return viewModel.players.first ?? Player(name: "Jogador", balance: 1500, color: .blue)
    }
    
    // Outros jogadores para transferência
    private var otherPlayers: [Player] {
        viewModel.players.filter { $0.id != activePlayer.id && !$0.isBankrupt }
    }
    
    private var currentAmount: Decimal {
        Decimal(string: keypadValueString) ?? 0
    }
    
    private var targetPlayer: Player? {
        otherPlayers.first(where: { $0.id == targetPlayerId }) ?? otherPlayers.first
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // MARK: - 1. Cabeçalho do Caixa Ativo
            activeAccountHeader
            
            // MARK: - 2. Seletor de Tipo (Banco / Amigo)
            Picker("Operação", selection: $selectedTab) {
                Text("Banco (+ / -)").tag(0)
                Text("Pagar a Amigo").tag(1)
            }
            .pickerStyle(.segmented)
            .onChange(of: selectedTab) { _, _ in
                HapticManager.selection()
                SoundManager.play(.buttonTap)
            }
            
            // MARK: - 3. Seletor de Destino (se for amigo)
            if selectedTab == 1 {
                targetPlayerSelectionRow
            }
            
            // MARK: - 4. Visor do Caixa 3D (LCD / Display Chanfrado com Reflexo)
            amountDisplay3DCard
            
            // MARK: - 5. Presets Rápidos de Tabuleiro em 3D Tátil
            boardGamePresets3DRow
            
            // MARK: - 6. Teclado Numérico 3D Mecânico (Keypad 3D)
            keypad3DGrid
            
            Spacer(minLength: 4)
            
            // MARK: - 7. Botão(ões) de Ação Principal 3D Chunky
            action3DButtonsSection
        }
        .padding(18)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(AppTheme.strokeBlack, lineWidth: 2.2)
        )
        .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 5)
        .onAppear {
            if targetPlayerId == nil {
                targetPlayerId = otherPlayers.first?.id
            }
        }
    }
    
    // MARK: - Subviews
    
    private var activeAccountHeader: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(activePlayer.color.color.gradient)
                    .frame(width: 38, height: 38)
                    .overlay(
                        Circle().stroke(AppTheme.strokeBlack, lineWidth: 1.8)
                    )
                
                Circle()
                    .strokeBorder(Color.white.opacity(0.4), lineWidth: 1.5)
                    .padding(2)
                
                Text(String(activePlayer.name.prefix(1)).uppercased())
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: Color.black.opacity(0.3), radius: 1, x: 0, y: 1)
            }
            
            VStack(alignment: .leading, spacing: 1) {
                Text(activePlayer.name)
                    .font(.headline.weight(.heavy))
                    .foregroundStyle(AppTheme.textPrimary)
                
                Text("Saldo: \(activePlayer.balance.asCurrency)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppTheme.textSecondary)
            }
            
            Spacer()
            
            if let feedback = operationFeedbackText {
                Text(feedback)
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
    }
    
    private var targetPlayerSelectionRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Pagar para:")
                .font(.caption2.weight(.black))
                .foregroundStyle(AppTheme.textSecondary)
                .tracking(0.5)
            
            if otherPlayers.isEmpty {
                Text("Nenhum outro jogador ativo na mesa.")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(otherPlayers) { other in
                            let isTarget = targetPlayerId == other.id
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
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(isTarget ? AppTheme.actionCoral.opacity(0.18) : Color.white)
                                .foregroundStyle(AppTheme.strokeBlack)
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule().stroke(isTarget ? AppTheme.actionCoral : AppTheme.strokeBlack.opacity(0.2), lineWidth: isTarget ? 2.0 : 1.2)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Visor Digital 3D Chanfrado (LCD Screen com Reflexo de Vidro)
    
    private var amountDisplay3DCard: some View {
        ZStack {
            // Moldura Chanfrada Externa
            RoundedRectangle(cornerRadius: 16, style: .continuous)
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
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(AppTheme.strokeBlack, lineWidth: 2.2)
                )
                .shadow(color: Color.black.opacity(0.20), radius: 5, x: 0, y: 2.5)
            
            // Reflexo de Luz no Vidro
            RoundedRectangle(cornerRadius: 16, style: .continuous)
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
                    lineWidth: 1.2
                )
                .padding(2)
            
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(selectedTab == 0 ? "VALOR DA TRANSAÇÃO" : "VALOR PARA TRANSFERIR")
                        .font(.system(size: 9, weight: .black, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.65))
                        .tracking(1)
                    
                    Text(currentAmount > 0 ? currentAmount.asCurrency : "R$ 0")
                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                        .foregroundStyle(currentAmount > 0 ? AppTheme.actionYellow : Color.white.opacity(0.35))
                        .shadow(color: currentAmount > 0 ? AppTheme.actionYellow.opacity(0.35) : Color.clear, radius: 3, x: 0, y: 0)
                        .lineLimit(1)
                        .minimumScaleFactor(0.55)
                }
                
                Spacer()
                
                if currentAmount > 0 {
                    Tactile3DButton(
                        faceColor: AppTheme.actionCoral,
                        depthColor: AppTheme.actionCoralDark,
                        cornerRadius: 14,
                        depth: 3,
                        strokeWidth: 1.4,
                        action: {
                            keypadValueString = ""
                        }
                    ) {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .black))
                            .foregroundStyle(Color.white)
                            .frame(width: 30, height: 26)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
        .frame(height: 66)
    }
    
    // MARK: - Presets de Tabuleiro 3D
    
    private var boardGamePresets3DRow: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 6), GridItem(.flexible(), spacing: 6), GridItem(.flexible(), spacing: 6)], spacing: 6) {
            Tactile3DPresetChip(label: "+2.000 Início", isAccent: true) { appendPreset(2000) }
            Tactile3DPresetChip(label: "+1.000") { appendPreset(1000) }
            Tactile3DPresetChip(label: "+500 Fiança") { appendPreset(500) }
            Tactile3DPresetChip(label: "+200 Lucros") { appendPreset(200) }
            Tactile3DPresetChip(label: "+100 Taxa") { appendPreset(100) }
            Tactile3DPresetChip(label: "+50") { appendPreset(50) }
        }
    }
    
    private func appendPreset(_ amount: Int) {
        let current = Int(keypadValueString) ?? 0
        keypadValueString = "\(current + amount)"
    }
    
    // MARK: - Teclado Numérico 3D Mecânico
    
    private var keypad3DGrid: some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                Tactile3DKeypadKey(label: "1") { appendChar("1") }
                Tactile3DKeypadKey(label: "2") { appendChar("2") }
                Tactile3DKeypadKey(label: "3") { appendChar("3") }
            }
            HStack(spacing: 6) {
                Tactile3DKeypadKey(label: "4") { appendChar("4") }
                Tactile3DKeypadKey(label: "5") { appendChar("5") }
                Tactile3DKeypadKey(label: "6") { appendChar("6") }
            }
            HStack(spacing: 6) {
                Tactile3DKeypadKey(label: "7") { appendChar("7") }
                Tactile3DKeypadKey(label: "8") { appendChar("8") }
                Tactile3DKeypadKey(label: "9") { appendChar("9") }
            }
            HStack(spacing: 6) {
                Tactile3DKeypadKey(label: "00", isSpecial: true) { appendChar("00") }
                Tactile3DKeypadKey(label: "0") { appendChar("0") }
                Tactile3DBackspaceKey {
                    if !keypadValueString.isEmpty {
                        keypadValueString.removeLast()
                    }
                }
            }
        }
    }
    
    private func appendChar(_ char: String) {
        if keypadValueString.count < 8 {
            if keypadValueString == "0" {
                keypadValueString = char == "00" ? "0" : char
            } else {
                keypadValueString += char
            }
        }
    }
    
    // MARK: - Botões de Ação 3D Chunky com Afundamento Físico
    
    private var action3DButtonsSection: some View {
        Group {
            if selectedTab == 0 {
                // Aba Banco (+ / -) com 2 Botões 3D Chunky
                HStack(spacing: 10) {
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
                // Aba Transferência para Amigo em 3D Chunky
                Tactile3DActionButton(
                    title: targetPlayer != nil
                    ? "Transferir \(currentAmount > 0 ? currentAmount.asCurrency : "") para \(targetPlayer!.name)"
                    : "Selecione o Destinatário",
                    icon: "arrow.up.right.circle.fill",
                    gradient: AppTheme.actionCoralGradient,
                    depthColor: AppTheme.actionCoralDark,
                    isDisabled: currentAmount <= 0 || targetPlayer == nil
                ) {
                    executeTransferOperation()
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    private func executeBankOperation(isPositive: Bool) {
        guard currentAmount > 0 else { return }
        let delta = isPositive ? currentAmount : -currentAmount
        withAnimation {
            viewModel.adjustBalance(for: activePlayer.id, delta: delta)
            showFeedback(delta > 0 ? "+\(currentAmount.asCurrency)" : "-\(currentAmount.asCurrency)")
            keypadValueString = ""
        }
    }
    
    private func executeTransferOperation() {
        guard currentAmount > 0, let target = targetPlayer else { return }
        withAnimation {
            if viewModel.transferMoney(from: activePlayer.id, to: target.id, amount: currentAmount) {
                showFeedback("Transferido!")
                keypadValueString = ""
            }
        }
    }
    
    private func showFeedback(_ text: String) {
        withAnimation {
            operationFeedbackText = text
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                operationFeedbackText = nil
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
    return IntegratedOperationPanel(viewModel: vm, selectedPlayerId: .constant(vm.players[0].id))
        .padding()
        .background(AppTheme.canvasBackground)
}
