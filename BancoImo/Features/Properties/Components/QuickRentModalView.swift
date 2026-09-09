//
//  QuickRentModalView.swift
//  BancoImo
//
//  Created by iOS Senior Developer.
//

import SwiftUI

/// Modal de Cobrança Rápida de Aluguel em 1 Toque com cálculo automático baseado em casas e monopólio.
struct QuickRentModalView: View {
    @Bindable var viewModel: GameViewModel
    let property: Property
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedPayerId: UUID? = nil
    @State private var companyDiceSum: Int = 7
    @State private var wasPaid: Bool = false
    
    private var owner: Player? {
        guard let id = property.ownerId else { return nil }
        return viewModel.players.first(where: { $0.id == id })
    }
    
    private var eligiblePayers: [Player] {
        guard let ownerId = property.ownerId else { return [] }
        return viewModel.players.filter { $0.id != ownerId && !$0.isBankrupt }
    }
    
    private var hasMonopoly: Bool {
        guard let ownerId = property.ownerId else { return false }
        return viewModel.hasMonopoly(for: property.group, playerId: ownerId)
    }
    
    private var calculatedRent: Decimal {
        guard let ownerId = property.ownerId else { return 0 }
        let companiesCount = viewModel.ownedCompaniesCount(for: ownerId)
        return property.calculateRent(
            hasMonopoly: hasMonopoly,
            diceSum: property.isCompany ? companyDiceSum : nil,
            ownedCompaniesCount: companiesCount
        )
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.canvasBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    // MARK: - 1. Cartão do Imóvel & Dono
                    VStack(spacing: 10) {
                        // Header com Cor do Bairro
                        HStack(spacing: 8) {
                            Circle()
                                .fill(property.group.headerColor)
                                .frame(width: 14, height: 14)
                                .overlay(Circle().stroke(AppTheme.strokeBlack, lineWidth: 1))
                            
                            Text(property.name)
                                .font(.headline.weight(.heavy))
                                .foregroundStyle(AppTheme.textPrimary)
                            
                            Spacer()
                            
                            if property.isHotel {
                                Text("HOTEL 🏨")
                                    .font(.caption2.weight(.black))
                                    .foregroundStyle(Color.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(AppTheme.actionCoral)
                                    .clipShape(Capsule())
                            } else if property.housesCount > 0 {
                                Text("\(property.housesCount) CASAS 🏠")
                                    .font(.caption2.weight(.black))
                                    .foregroundStyle(AppTheme.strokeBlack)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(AppTheme.actionGreen.opacity(0.3))
                                    .clipShape(Capsule())
                            } else if hasMonopoly {
                                Text("MONOPÓLIO 2x")
                                    .font(.caption2.weight(.black))
                                    .foregroundStyle(AppTheme.strokeBlack)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(AppTheme.actionYellow)
                                    .clipShape(Capsule())
                            }
                        }
                        
                        Divider()
                        
                        // Dono
                        if let owner = owner {
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(owner.color.color.gradient)
                                    .frame(width: 24, height: 24)
                                    .overlay(Circle().stroke(AppTheme.strokeBlack, lineWidth: 1.2))
                                
                                VStack(alignment: .leading, spacing: 1) {
                                    Text("Proprietário: \(owner.name)")
                                        .font(.subheadline.weight(.bold))
                                        .foregroundStyle(AppTheme.textPrimary)
                                    Text("Receberá o aluguel no caixa")
                                        .font(.caption2)
                                        .foregroundStyle(AppTheme.textSecondary)
                                }
                                Spacer()
                            }
                        }
                    }
                    .padding(16)
                    .background(AppTheme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(AppTheme.strokeBlack, lineWidth: 2))
                    
                    // MARK: - 2. Visor 3D do Aluguel Calculado
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [Color(red: 0.08, green: 0.09, blue: 0.13), Color(red: 0.14, green: 0.16, blue: 0.22)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppTheme.strokeBlack, lineWidth: 2))
                        
                        VStack(spacing: 2) {
                            Text("VALOR EXATO DO ALUGUEL")
                                .font(.system(size: 9.5, weight: .black, design: .rounded))
                                .foregroundStyle(Color.white.opacity(0.7))
                                .tracking(1)
                            
                            Text(calculatedRent.asCurrency)
                                .font(.system(size: 34, weight: .heavy, design: .rounded))
                                .foregroundStyle(AppTheme.actionYellow)
                                .shadow(color: AppTheme.actionYellow.opacity(0.4), radius: 4)
                        }
                        .padding(12)
                    }
                    .frame(height: 78)
                    
                    // MARK: - 3. Seletor de Quem Pagará o Aluguel
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Quem caiu neste imóvel?")
                            .font(.subheadline.weight(.black))
                            .foregroundStyle(Color.white)
                        
                        if eligiblePayers.isEmpty {
                            Text("Não há outros jogadores ativos para cobrar.")
                                .font(.caption)
                                .foregroundStyle(Color.white.opacity(0.8))
                        } else {
                            VStack(spacing: 6) {
                                ForEach(eligiblePayers) { player in
                                    let isSelected = selectedPayerId == player.id
                                    Button {
                                        HapticManager.selection()
                                        SoundManager.play(.buttonTap)
                                        selectedPayerId = player.id
                                    } label: {
                                        HStack(spacing: 10) {
                                            Circle()
                                                .fill(player.color.color.gradient)
                                                .frame(width: 22, height: 22)
                                                .overlay(Circle().stroke(AppTheme.strokeBlack, lineWidth: 1.2))
                                            
                                            Text(player.name)
                                                .font(.subheadline.weight(.heavy))
                                                .foregroundStyle(AppTheme.strokeBlack)
                                            
                                            Spacer()
                                            
                                            Text("Saldo: \(player.balance.asCurrency)")
                                                .font(.caption.weight(.bold))
                                                .foregroundStyle(AppTheme.textSecondary)
                                            
                                            if isSelected {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundStyle(AppTheme.actionGreen)
                                            }
                                        }
                                        .padding(10)
                                        .background(isSelected ? AppTheme.actionCoral.opacity(0.18) : Color.white)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(isSelected ? AppTheme.actionCoral : AppTheme.strokeBlack.opacity(0.15), lineWidth: isSelected ? 2 : 1)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // MARK: - 4. Botão de Pagamento 3D Tátil
                    Tactile3DButton(
                        faceGradient: AppTheme.actionCoralGradient,
                        depthColor: AppTheme.actionCoralDark,
                        cornerRadius: 18,
                        depth: 5.0,
                        strokeWidth: 2.0,
                        action: {
                            guard let payerId = selectedPayerId else { return }
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                _ = viewModel.chargeRent(propertyId: property.id, paidBy: payerId, diceSum: companyDiceSum)
                                dismiss()
                            }
                        }
                    ) {
                        HStack(spacing: 8) {
                            Image(systemName: "dollarsign.arrow.circlepath")
                                .font(.system(size: 16, weight: .black))
                            Text("Pagar Aluguel (\(calculatedRent.asCurrency))")
                                .font(.system(size: 15, weight: .heavy, design: .rounded))
                        }
                        .foregroundStyle(Color.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                    }
                    .disabled(selectedPayerId == nil)
                }
                .padding(20)
            }
            .navigationTitle("Cobrança de Aluguel")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancelar") {
                        dismiss()
                    }
                    .foregroundStyle(Color.white)
                    .font(.subheadline.weight(.bold))
                }
            }
            .onAppear {
                selectedPayerId = eligiblePayers.first?.id
                companyDiceSum = viewModel.dice1 + viewModel.dice2
            }
        }
        .presentationDetents([.medium, .large])
    }
}
