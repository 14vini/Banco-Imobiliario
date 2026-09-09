//
//  TransactionRowView.swift
//  BancoImo
//
//  Created by iOS Senior Developer.
//

import SwiftUI

/// Linha de exibição de uma transação no extrato no padrão Neo-Fintech com suporte total a Dark Mode.
struct TransactionRowView: View {
    let transaction: Transaction
    
    var body: some View {
        HStack(spacing: 14) {
            // Ícone estilo Neo-Fintech (círculo escuro com ícone vibrante)
            ZStack {
                Circle()
                    .fill(AppTheme.darkCard)
                    .frame(width: 42, height: 42)
                    .overlay(
                        Circle().stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
                
                Image(systemName: transaction.type.iconName)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(iconColor)
            }
            
            // Descrição da Transação
            VStack(alignment: .leading, spacing: 3) {
                Text(transaction.title)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
                
                Text(transaction.subtitle)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            // Valor e Hora
            VStack(alignment: .trailing, spacing: 3) {
                if transaction.type != .bankruptcy {
                    Text(amountPrefix + transaction.amount.asCurrency)
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .foregroundStyle(amountColor)
                }
                
                Text(transaction.formattedTime)
                    .font(.caption2)
                    .foregroundStyle(AppTheme.textSecondary.opacity(0.8))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppTheme.borderSubtle, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.02), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Helpers Visuais
    
    private var iconColor: Color {
        switch transaction.type {
        case .salary, .bankDeposit, .propertyMortgage, .houseSell:
            return AppTheme.limeAccent
        case .bankPayment, .houseBuild, .propertyUnmortgage:
            return .red
        case .propertyPurchase, .propertySale:
            return .blue
        case .transfer, .rentPayment:
            return .purple
        case .initialBalance:
            return .yellow
        case .bankruptcy:
            return .orange
        }
    }
    
    private var amountColor: Color {
        switch transaction.type {
        case .salary, .bankDeposit, .propertyMortgage, .houseSell:
            return Color.green
        case .bankPayment, .houseBuild, .propertyUnmortgage, .propertyPurchase:
            return Color.red.opacity(0.85)
        case .transfer, .propertySale, .rentPayment:
            return AppTheme.textPrimary
        case .initialBalance:
            return AppTheme.textSecondary
        case .bankruptcy:
            return Color.secondary
        }
    }
    
    private var amountPrefix: String {
        switch transaction.type {
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
    VStack(spacing: 10) {
        TransactionRowView(
            transaction: Transaction(
                type: .salary,
                amount: 200,
                receiverName: "Kauã",
                title: "Passou pelo Início (+200)",
                subtitle: "Kauã recebeu o salário da rodada do Banco"
            )
        )
        TransactionRowView(
            transaction: Transaction(
                type: .transfer,
                amount: 150,
                senderName: "Mariana",
                receiverName: "Kauã",
                title: "Aluguel / Pagamento",
                subtitle: "Mariana pagou R$ 150 para Kauã"
            )
        )
    }
    .padding()
    .background(AppTheme.canvasBackground)
}
