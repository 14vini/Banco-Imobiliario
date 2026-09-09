//
//  TransactionHistoryView.swift
//  BancoImo
//
//  Created by iOS Senior Developer.
//

import SwiftUI

/// Tela de extrato completo, estatísticas em tempo real e gráficos analíticos com suporte a Desfazer.
struct TransactionHistoryView: View {
    let viewModel: GameViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedTab: Int = 0 // 0: Extrato, 1: Gráficos & Estatísticas
    @State private var selectedPlayerIdFilter: UUID? = nil
    
    private var filteredTransactions: [Transaction] {
        viewModel.transactions(for: selectedPlayerIdFilter)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.canvasBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 12) {
                    // MARK: - Segmented Control: Extrato vs. Gráficos
                    Picker("Visualização", selection: $selectedTab) {
                        Label("Extrato", systemImage: "list.clipboard").tag(0)
                        Label("Estatísticas & Gráficos", systemImage: "chart.line.uptrend.xyaxis").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .onChange(of: selectedTab) { _, _ in
                        HapticManager.selection()
                        SoundManager.play(.buttonTap)
                    }
                    
                    if selectedTab == 0 {
                        // MARK: - Aba 1: Extrato com Filtros
                        VStack(spacing: 12) {
                            playerFilterChips
                            
                            if filteredTransactions.isEmpty {
                                emptyStateView
                            } else {
                                ScrollView {
                                    LazyVStack(spacing: 10) {
                                        ForEach(filteredTransactions) { transaction in
                                            TransactionRowView(transaction: transaction)
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.top, 4)
                                    .padding(.bottom, 20)
                                }
                            }
                        }
                    } else {
                        // MARK: - Aba 2: Gráficos Swift Charts & KPIs
                        GameChartsView(viewModel: viewModel)
                    }
                }
            }
            .navigationTitle(selectedTab == 0 ? "Extrato da Mesa" : "Estatísticas da Partida")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if viewModel.canUndo && selectedTab == 0 {
                        Button {
                            viewModel.undoLastTransaction()
                            SoundManager.play(.undo)
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.uturn.backward")
                                Text("Desfazer")
                            }
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(AppTheme.textPrimary)
                        }
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fechar") {
                        SoundManager.play(.buttonTap)
                        dismiss()
                    }
                    .font(.headline.weight(.bold))
                    .foregroundStyle(AppTheme.textPrimary)
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private var playerFilterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Chip "Todos"
                filterChip(
                    title: "Todos (\(viewModel.transactions.count))",
                    color: AppTheme.limeAccent,
                    isSelected: selectedPlayerIdFilter == nil
                ) {
                    HapticManager.selection()
                    SoundManager.play(.buttonTap)
                    selectedPlayerIdFilter = nil
                }
                
                // Chips individuais por jogador
                ForEach(viewModel.players) { player in
                    let count = viewModel.transactions(for: player.id).count
                    filterChip(
                        title: "\(player.name) (\(count))",
                        color: player.color.color,
                        isSelected: selectedPlayerIdFilter == player.id
                    ) {
                        HapticManager.selection()
                        SoundManager.play(.buttonTap)
                        selectedPlayerIdFilter = player.id
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }
    
    private func filterChip(title: String, color: Color, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Circle()
                    .fill(color.gradient)
                    .frame(width: 9, height: 9)
                    .overlay(Circle().stroke(AppTheme.strokeBlack, lineWidth: 1))
                
                Text(title)
                    .font(.caption.weight(.heavy))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(isSelected ? AppTheme.actionYellow : AppTheme.cardBackground)
            .foregroundStyle(AppTheme.strokeBlack)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(AppTheme.strokeBlack, lineWidth: isSelected ? 1.8 : 1.2)
            )
            .shadow(color: Color.black.opacity(isSelected ? 0.12 : 0.04), radius: 3, x: 0, y: 1.5)
        }
        .buttonStyle(.plain)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Spacer()
            
            Image(systemName: "list.clipboard")
                .font(.system(size: 48))
                .foregroundStyle(AppTheme.textSecondary.opacity(0.5))
            
            Text("Nenhuma movimentação registrada")
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)
            
            Text("As transações do banco e entre amigos aparecerão aqui automaticamente.")
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Spacer()
        }
    }
}

#Preview {
    let vm = GameViewModel()
    vm.players = [
        Player(name: "Kauã", balance: 3200, color: .blue),
        Player(name: "Mariana", balance: 2100, color: .purple)
    ]
    vm.transactions = [
        Transaction(type: .salary, amount: 200, receiverName: "Kauã", title: "Passou pelo Início (+200)", subtitle: "Kauã recebeu o salário do Banco"),
        Transaction(type: .bankPayment, amount: 150, senderName: "Mariana", title: "Pago ao Banco", subtitle: "Mariana pagou R$ 150 ao Banco")
    ]
    return TransactionHistoryView(viewModel: vm)
}
