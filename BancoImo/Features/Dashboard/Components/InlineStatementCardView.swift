//
//  InlineStatementCardView.swift
//  BancoImo
//
//  Created by iOS Senior Developer.
//

import SwiftUI

/// Componente de Extrato em Tempo Real embutido diretamente no Dashboard.
/// Permite visualizar movimentações instantaneamente, filtrar por jogador e expandir registros inline.
struct InlineStatementCardView: View {
    @Bindable var viewModel: GameViewModel
    var onOpenFullCharts: () -> Void
    
    @State private var selectedPlayerFilter: UUID? = nil
    @State private var isExpanded: Bool = false
    
    // MARK: - Computed Properties
    
    private var filteredTransactions: [Transaction] {
        viewModel.transactions(for: selectedPlayerFilter)
    }
    
    private var displayedTransactions: [Transaction] {
        isExpanded ? filteredTransactions : Array(filteredTransactions.prefix(5))
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            headerSection
                .padding(16)
            
            if !viewModel.players.isEmpty {
                playerFiltersSection
                    .padding(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
            }
            
            if filteredTransactions.isEmpty {
                VStack{
                    transactionsContentSection
                }
            } else {
                ScrollView{
                    transactionsContentSection
                }
            }
            
        }
//        .padding(16)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(AppTheme.strokeBlack, lineWidth: 1.8)
        )
        .shadow(color: Color.black.opacity(0.07), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - 1. Cabeçalho
    
    private var headerSection: some View {
        HStack(alignment: .center, spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(AppTheme.actionPurple.opacity(0.18))
                    .frame(width: 32, height: 32)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(AppTheme.strokeBlack, lineWidth: 1.2)
                    )
                
                Image(systemName: "list.bullet.rectangle.portrait.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(AppTheme.actionPurple)
            }
            
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 6) {
                    Text("Extrato da Mesa")
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .foregroundStyle(AppTheme.strokeBlack)
                    
                    Text("\(viewModel.transactions.count)")
                        .font(.system(size: 11, weight: .black, design: .monospaced))
                        .foregroundStyle(AppTheme.strokeBlack)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(AppTheme.actionYellow)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().stroke(AppTheme.strokeBlack, lineWidth: 1)
                        )
                }
                
                Text("Movimentações em tempo real")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
            }
            
            Spacer()
            
            Button(action: onOpenFullCharts) {
                HStack(spacing: 4) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 11, weight: .black))
                    Text("Gráficos")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                }
                .foregroundStyle(AppTheme.strokeBlack)
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(Color.white)
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(AppTheme.strokeBlack, lineWidth: 1.3)
                )
                .shadow(color: Color.black.opacity(0.06), radius: 2, x: 0, y: 1)
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - 2. Filtro Horizontal por Jogador
    
    private var playerFiltersSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                filterChip(
                    title: "Todos",
                    count: viewModel.transactions.count,
                    color: AppTheme.actionYellow,
                    isSelected: selectedPlayerFilter == nil
                ) {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                        selectedPlayerFilter = nil
                    }
                    HapticManager.selection()
                }
                
                ForEach(viewModel.players) { player in
                    let count = viewModel.transactions(for: player.id).count
                    filterChip(
                        title: player.name,
                        count: count,
                        color: player.color.color,
                        isSelected: selectedPlayerFilter == player.id
                    ) {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                            selectedPlayerFilter = player.id
                        }
                        HapticManager.selection()
                    }
                }
            }
            .padding(.vertical, 2)
        }
    }
    
    // MARK: - 3. Lista e Estados de Transação
    
    @ViewBuilder
    private var transactionsContentSection: some View {
        if filteredTransactions.isEmpty {
            emptyStateView
        } else {
            VStack(spacing: 8) {
                ForEach(displayedTransactions) { tx in
                    inlineTransactionRow(tx)
                }
                
                if filteredTransactions.count > 5 {
                    expandCollapseButton
                        .padding(.horizontal)
                }
            }
            .padding(.bottom, 26 )
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(AppTheme.textSecondary.opacity(0.5))
                .padding(.top, 6)
            
            Text("Nenhuma movimentação registrada")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)
            
            Text("Os pagamentos, salários e transferências serão exibidos aqui instantaneamente.")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
                .padding(.bottom, 6)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
    
    private var expandCollapseButton: some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                isExpanded.toggle()
            }
            HapticManager.selection()
        } label: {
            HStack(spacing: 6) {
                Text(isExpanded ? "Mostrar Menos" : "Ver Todas as \(filteredTransactions.count) Jogadas")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 10, weight: .black))
            }
            .foregroundStyle(AppTheme.strokeBlack)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(AppTheme.strokeBlack.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .padding(.top, 4)
    }
    
    // MARK: - Linha de Transação Compacta
    
    private func inlineTransactionRow(_ tx: Transaction) -> some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(txIconBackground(tx.type))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Circle().stroke(AppTheme.strokeBlack, lineWidth: 1.2)
                    )
                
                Image(systemName: tx.type.iconName)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(txIconForeground(tx.type))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(tx.title)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(1)
                
                Text(tx.subtitle)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(1)
            }
            
            Spacer(minLength: 4)
            
            VStack(alignment: .trailing, spacing: 1) {
                if tx.type != .bankruptcy {
                    Text(txAmountPrefix(tx.type) + tx.amount.asCurrency)
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .foregroundStyle(txAmountColor(tx.type))
                }
                
                Text(tx.formattedTime)
                    .font(.system(size: 9.5, weight: .semibold, design: .monospaced))
                    .foregroundStyle(AppTheme.textSecondary.opacity(0.8))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(AppTheme.strokeBlack.opacity(0.12), lineWidth: 1)
        )
        .padding(.horizontal)
    }
    
    // MARK: - Componente de Chip
    
    private func filterChip(
        title: String,
        count: Int,
        color: Color,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Circle()
                    .fill(color)
                    .frame(width: 7, height: 7)
                    .overlay(Circle().stroke(AppTheme.strokeBlack, lineWidth: 0.8))
                
                Text(title)
                    .font(.system(size: 11, weight: isSelected ? .heavy : .bold, design: .rounded))
                
                Text("\(count)")
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .foregroundStyle(isSelected ? AppTheme.strokeBlack : AppTheme.textSecondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(isSelected ? AppTheme.actionYellow : Color.white)
            .foregroundStyle(AppTheme.strokeBlack)
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(AppTheme.strokeBlack, lineWidth: isSelected ? 1.5 : 1)
            )
            .shadow(color: Color.black.opacity(isSelected ? 0.08 : 0.02), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Cores e Auxiliares
    
    private func txIconBackground(_ type: TransactionType) -> Color {
        switch type {
        case .salary, .bankDeposit, .propertyMortgage, .houseSell:
            return AppTheme.actionGreen.opacity(0.2)
        case .bankPayment, .houseBuild, .propertyUnmortgage:
            return AppTheme.actionCoral.opacity(0.2)
        case .propertyPurchase, .propertySale:
            return AppTheme.actionBlue.opacity(0.2)
        case .transfer, .rentPayment:
            return AppTheme.actionPurple.opacity(0.2)
        case .initialBalance:
            return AppTheme.actionYellow.opacity(0.25)
        case .bankruptcy:
            return Color.black.opacity(0.1)
        }
    }
    
    private func txIconForeground(_ type: TransactionType) -> Color {
        switch type {
        case .salary, .bankDeposit, .propertyMortgage, .houseSell:
            return AppTheme.actionGreen
        case .bankPayment, .houseBuild, .propertyUnmortgage:
            return AppTheme.actionCoral
        case .propertyPurchase, .propertySale:
            return AppTheme.actionBlue
        case .transfer, .rentPayment:
            return AppTheme.actionPurple
        case .initialBalance:
            return AppTheme.strokeBlack
        case .bankruptcy:
            return Color.red
        }
    }
    
    private func txAmountColor(_ type: TransactionType) -> Color {
        switch type {
        case .salary, .bankDeposit, .propertyMortgage, .houseSell:
            return AppTheme.actionGreen
        case .bankPayment, .houseBuild, .propertyUnmortgage, .propertyPurchase:
            return AppTheme.actionCoral
        case .transfer, .rentPayment, .propertySale:
            return AppTheme.strokeBlack
        case .initialBalance:
            return AppTheme.textSecondary
        case .bankruptcy:
            return Color.gray
        }
    }
    
    private func txAmountPrefix(_ type: TransactionType) -> String {
        switch type {
        case .salary, .bankDeposit, .propertyMortgage, .houseSell:
            return "+"
        case .bankPayment, .houseBuild, .propertyUnmortgage, .propertyPurchase:
            return "-"
        case .transfer, .propertySale, .rentPayment, .initialBalance, .bankruptcy:
            return ""
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
    return InlineStatementCardView(viewModel: vm, onOpenFullCharts: {})
        .padding()
        .background(AppTheme.canvasBackground)
}
