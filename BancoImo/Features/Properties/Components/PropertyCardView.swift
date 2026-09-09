//
//  PropertyCardView.swift
//  BancoImo
//
//  Created by iOS Senior Developer.
//

import SwiftUI

/// Cartela clássica física de Título de Propriedade em 3D Neo-Brutalist,
/// com cabeçalho colorido, tabela de aluguel por casa/hotel, badges de monopólio e botões de ação tátil.
struct PropertyCardView: View {
    @Bindable var viewModel: GameViewModel
    let property: Property
    var onOpenRentCalculator: ((Property) -> Void)? = nil
    
    @State private var showActionOptions: Bool = false
    @State private var showBuyerPicker: Bool = false
    @State private var showTransferSheet: Bool = false
    @State private var transferBuyerId: UUID? = nil
    @State private var transferPriceString: String = ""
    
    private var owner: Player? {
        guard let id = property.ownerId else { return nil }
        return viewModel.players.first(where: { $0.id == id })
    }
    
    private var hasMonopoly: Bool {
        guard let ownerId = property.ownerId else { return false }
        return viewModel.hasMonopoly(for: property.group, playerId: ownerId)
    }
    
    private var otherPlayers: [Player] {
        guard let ownerId = property.ownerId else { return viewModel.players }
        return viewModel.players.filter { $0.id != ownerId && !$0.isBankrupt }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // MARK: - 1. Cabeçalho Colorido do Bairro / Título
            cardHeaderView
            
            // MARK: - 2. Corpo do Título de Propriedade
            VStack(spacing: 10) {
                // Badge de Dono Atual / Status do Banco
                ownerStatusBadge
                
                // Tabela de Aluguéis e Construções
                if property.isCompany {
                    companyRentTableView
                } else {
                    standardPropertyRentTableView
                }
                
                Divider()
                
                // Rodapé com Custos de Casas e Hipoteca
                propertyCostFooterView
                
                // MARK: - 3. Botões de Ação Rápida Táteis 3D
                actionButtonsRow
                    .padding(.top, 4)
            }
            .padding(14)
            .background(AppTheme.cardBackground)
        }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(AppTheme.strokeBlack, lineWidth: 2.0)
        )
        .shadow(color: Color.black.opacity(0.10), radius: 6, x: 0, y: 3)
        // Sheet de Comprador (quando a propriedade está no Banco)
        .confirmationDialog(
            "Quem está comprando \(property.name)?",
            isPresented: $showBuyerPicker,
            titleVisibility: .visible
        ) {
            ForEach(viewModel.activePlayers) { player in
                
                Button("\(player.name) (\(player.balance.asCurrency))") {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        _ = viewModel.buyProperty(propertyId: property.id, by: player.id)
                    }
                }
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Valor de compra oficial: \(property.price.asCurrency)")
        }
        // Sheet de Negociação entre Jogadores
        .sheet(isPresented: $showTransferSheet) {
            propertyTransferSheet
        }
    }
    
    // MARK: - Cabeçalho do Cartão
    
    private var cardHeaderView: some View {
        ZStack {
            Rectangle()
                .fill(property.group.headerGradient)
                .frame(height: 52)
                .overlay(
                    Rectangle()
                        .stroke(AppTheme.strokeBlack, lineWidth: 1.5)
                )
            
            VStack(spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: property.group.iconName)
                        .font(.system(size: 9, weight: .bold))
                    Text(property.group.displayName.uppercased())
                        .font(.system(size: 8.5, weight: .black, design: .rounded))
                        .tracking(1)
                }
                .foregroundStyle(property.group.textColor.opacity(0.85))
                
                Text(property.name)
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundStyle(property.group.textColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .padding(.horizontal, 10)
        }
    }
    
    // MARK: - Badge de Proprietário
    
    private var ownerStatusBadge: some View {
        HStack(spacing: 8) {
            if let owner = owner {
                HStack(spacing: 6) {
                    Circle()
                        .fill(owner.color.color.gradient)
                        .frame(width: 14, height: 14)
                        .overlay(Circle().stroke(AppTheme.strokeBlack, lineWidth: 1))
                    
                    Text("Dono: \(owner.name)")
                        .font(.system(size: 11.5, weight: .black, design: .rounded))
                        .foregroundStyle(AppTheme.strokeBlack)
                        .lineLimit(1)
                    
                    if hasMonopoly {
                        Text("MONOPÓLIO 2x")
                            .font(.system(size: 8, weight: .black))
                            .foregroundStyle(AppTheme.strokeBlack)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(AppTheme.actionYellow)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(AppTheme.strokeBlack, lineWidth: 0.8))
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(owner.color.color.opacity(0.12))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(AppTheme.strokeBlack.opacity(0.15), lineWidth: 1))
            } else {
                HStack(spacing: 4) {
                    Image(systemName: "banknote.fill")
                        .font(.system(size: 10, weight: .bold))
                    Text("Disponível no Banco")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                }
                .foregroundStyle(AppTheme.strokeBlack)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(AppTheme.actionGreen.opacity(0.18))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(AppTheme.actionGreenDark.opacity(0.4), lineWidth: 1))
            }
            
            Spacer()
            
            // Indicador de Construção Atual / Hipoteca
            if property.isMortgaged {
                Text("HIPOTECADO 📄")
                    .font(.system(size: 9, weight: .black))
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(AppTheme.actionCoral)
                    .clipShape(Capsule())
            } else if property.isHotel {
                HStack(spacing: 2) {
                    Text("🏨")
                    Text("HOTEL")
                        .font(.system(size: 9, weight: .black))
                }
                .foregroundStyle(AppTheme.strokeBlack)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(AppTheme.actionCoral.opacity(0.2))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(AppTheme.actionCoral, lineWidth: 1))
            } else if property.housesCount > 0 {
                HStack(spacing: 2) {
                    ForEach(0..<property.housesCount, id: \.self) { _ in
                        Text("🏠")
                            .font(.system(size: 10))
                    }
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(AppTheme.actionGreen.opacity(0.15))
                .clipShape(Capsule())
            }
        }
    }
    
    // MARK: - Tabela de Aluguéis Padrão
    
    private var standardPropertyRentTableView: some View {
        VStack(spacing: 4) {
            rentRow(label: "Aluguel Simples (Terreno)", amount: property.baseRent, isCurrentLevel: property.housesCount == 0 && !hasMonopoly && property.isOwned)
            rentRow(label: "Com Conjunto Completo (Monopólio)", amount: property.rentWithColorGroup, isCurrentLevel: property.housesCount == 0 && hasMonopoly)
            rentRow(label: "Com 1 Casa 🏠", amount: property.rentWith1House, isCurrentLevel: property.housesCount == 1)
            rentRow(label: "Com 2 Casas 🏠🏠", amount: property.rentWith2Houses, isCurrentLevel: property.housesCount == 2)
            rentRow(label: "Com 3 Casas 🏠🏠🏠", amount: property.rentWith3Houses, isCurrentLevel: property.housesCount == 3)
            rentRow(label: "Com 4 Casas 🏠🏠🏠🏠", amount: property.rentWith4Houses, isCurrentLevel: property.housesCount == 4)
            rentRow(label: "Com Hotel 🏨", amount: property.rentWithHotel, isCurrentLevel: property.housesCount == 5, isHighlight: true)
        }
        .padding(.vertical, 2)
    }
    
    // MARK: - Tabela de Aluguéis de Companhias
    
    private var companyRentTableView: some View {
        VStack(spacing: 4) {
            rentRow(label: "Se tiver 1 Companhia de Serviço", amount: property.baseRent, isCurrentLevel: viewModel.ownedCompaniesCount(for: property.ownerId ?? UUID()) == 1)
            rentRow(label: "Se tiver 2 Companhias", amount: property.rentWith1House, isCurrentLevel: viewModel.ownedCompaniesCount(for: property.ownerId ?? UUID()) == 2)
            rentRow(label: "Se tiver 3 Companhias", amount: property.rentWith2Houses, isCurrentLevel: viewModel.ownedCompaniesCount(for: property.ownerId ?? UUID()) == 3)
            rentRow(label: "Se tiver 4 Companhias", amount: property.rentWith3Houses, isCurrentLevel: viewModel.ownedCompaniesCount(for: property.ownerId ?? UUID()) == 4)
            rentRow(label: "Se tiver 5 ou 6 Companhias", amount: property.rentWithHotel, isCurrentLevel: viewModel.ownedCompaniesCount(for: property.ownerId ?? UUID()) >= 5, isHighlight: true)
        }
        .padding(.vertical, 2)
    }
    
    private func rentRow(label: String, amount: Decimal, isCurrentLevel: Bool = false, isHighlight: Bool = false) -> some View {
        HStack {
            HStack(spacing: 4) {
                if isCurrentLevel {
                    Circle()
                        .fill(AppTheme.actionGreen)
                        .frame(width: 6, height: 6)
                }
                Text(label)
                    .font(.system(size: 11, weight: isCurrentLevel ? .black : (isHighlight ? .bold : .medium), design: .rounded))
                    .foregroundStyle(isCurrentLevel ? AppTheme.strokeBlack : AppTheme.textSecondary)
            }
            
            Spacer()
            
            Text(amount.asCurrency)
                .font(.system(size: 11.5, weight: isCurrentLevel ? .black : .bold, design: .monospaced))
                .foregroundStyle(isCurrentLevel ? AppTheme.actionGreenDark : (isHighlight ? AppTheme.actionCoral : AppTheme.textPrimary))
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2.5)
        .background(isCurrentLevel ? AppTheme.actionGreen.opacity(0.14) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
    
    // MARK: - Rodapé de Custos
    
    private var propertyCostFooterView: some View {
        VStack(spacing: 4) {
            HStack {
                Text("Preço do Terreno:")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(AppTheme.textSecondary)
                Spacer()
                Text(property.price.asCurrency)
                    .font(.caption.weight(.heavy))
                    .foregroundStyle(AppTheme.textPrimary)
            }
            
            if !property.isCompany {
                HStack {
                    Text("Custo por Casa / Hotel:")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(AppTheme.textSecondary)
                    Spacer()
                    Text(property.houseCost.asCurrency)
                        .font(.caption.weight(.heavy))
                        .foregroundStyle(AppTheme.textPrimary)
                }
            }
            
            HStack {
                Text("Valor de Hipoteca:")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(AppTheme.textSecondary)
                Spacer()
                Text(property.mortgageValue.asCurrency)
                    .font(.caption.weight(.heavy))
                    .foregroundStyle(AppTheme.textPrimary)
            }
        }
    }
    
    // MARK: - Botões de Ação
    
    private var actionButtonsRow: some View {
        Group {
            if !property.isOwned {
                // Botão de Compra Direta do Banco
                Tactile3DButton(
                    faceGradient: AppTheme.actionGreenGradient,
                    depthColor: AppTheme.actionGreenDark,
                    cornerRadius: 14,
                    depth: 4.5,
                    strokeWidth: 1.8,
                    highlightColor: Color.white.opacity(0.4),
                    action: {
                        showBuyerPicker = true
                    }
                ) {
                    HStack(spacing: 6) {
                        Image(systemName: "cart.fill")
                            .font(.system(size: 12, weight: .black))
                        Text("Comprar do Banco (\(property.price.asCurrency))")
                            .font(.system(size: 13, weight: .heavy, design: .rounded))
                    }
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
            } else {
                // Ações para o Dono / Cobrança
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        // Botão 1: Cobrar Aluguel 💸
                        Tactile3DButton(
                            faceGradient: property.isMortgaged
                                ? LinearGradient(colors: [Color(white: 0.88), Color(white: 0.80)], startPoint: .top, endPoint: .bottom)
                                : AppTheme.actionCoralGradient,
                            depthColor: property.isMortgaged ? Color(white: 0.70) : AppTheme.actionCoralDark,
                            cornerRadius: 12,
                            depth: 3.5,
                            strokeWidth: 1.6,
                            action: {
                                onOpenRentCalculator?(property)
                            }
                        ) {
                            HStack(spacing: 4) {
                                Image(systemName: "dollarsign.circle.fill")
                                    .font(.system(size: 11, weight: .black))
                                Text("Cobrar")
                                    .font(.system(size: 11.5, weight: .heavy, design: .rounded))
                            }
                            .foregroundStyle(property.isMortgaged ? Color.gray : Color.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                        }
                        .disabled(property.isMortgaged)
                        
                        // Botão 2: +Casa / +Hotel
                        if property.canBuildHouse {
                            Tactile3DButton(
                                faceGradient: AppTheme.actionYellowGradient,
                                depthColor: AppTheme.actionYellowDark,
                                cornerRadius: 12,
                                depth: 3.5,
                                strokeWidth: 1.6,
                                action: {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                        _ = viewModel.buildHouse(propertyId: property.id)
                                    }
                                }
                            ) {
                                HStack(spacing: 3) {
                                    Image(systemName: "hammer.fill")
                                        .font(.system(size: 10, weight: .black))
                                    Text(property.housesCount == 4 ? "+Hotel" : "+Casa")
                                        .font(.system(size: 11, weight: .black, design: .rounded))
                                }
                                .foregroundStyle(AppTheme.strokeBlack)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                            }
                        }
                        
                        // Botão 3: -Casa se houver construções
                        if property.canSellHouse {
                            Tactile3DButton(
                                faceColor: Color.white,
                                depthColor: Color(red: 0.82, green: 0.84, blue: 0.88),
                                cornerRadius: 12,
                                depth: 3.5,
                                strokeWidth: 1.5,
                                action: {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                        _ = viewModel.sellHouse(propertyId: property.id)
                                    }
                                }
                            ) {
                                HStack(spacing: 2) {
                                    Image(systemName: "minus")
                                        .font(.system(size: 9, weight: .black))
                                    Text("Casa")
                                        .font(.system(size: 10.5, weight: .bold, design: .rounded))
                                }
                                .foregroundStyle(AppTheme.strokeBlack)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                            }
                        }
                    }
                    
                    // Linha Secundária: Hipotecar / Negociar
                    HStack(spacing: 8) {
                        // Hipoteca / Resgate
                        if property.isMortgaged {
                            Button {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    _ = viewModel.unmortgageProperty(propertyId: property.id)
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.seal.fill")
                                        .font(.system(size: 10))
                                    Text("Resgatar (\(property.unmortgageCost.asCurrency))")
                                        .font(.system(size: 10.5, weight: .bold, design: .rounded))
                                }
                                .foregroundStyle(AppTheme.actionGreenDark)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 5)
                                .background(AppTheme.actionGreen.opacity(0.12))
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(AppTheme.actionGreenDark.opacity(0.3), lineWidth: 1))
                            }
                        } else if property.canMortgage {
                            Button {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    _ = viewModel.mortgageProperty(propertyId: property.id)
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "doc.text.fill")
                                        .font(.system(size: 10))
                                    Text("Hipotecar (+\(property.mortgageValue.asCurrency))")
                                        .font(.system(size: 10.5, weight: .bold, design: .rounded))
                                }
                                .foregroundStyle(AppTheme.actionCoral)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 5)
                                .background(AppTheme.actionCoral.opacity(0.10))
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(AppTheme.actionCoral.opacity(0.3), lineWidth: 1))
                            }
                        }
                        
                        // Transferir para amigo
                        Button {
                            showTransferSheet = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.left.arrow.right")
                                    .font(.system(size: 9, weight: .bold))
                                Text("Negociar")
                                    .font(.system(size: 10.5, weight: .bold, design: .rounded))
                            }
                            .foregroundStyle(AppTheme.strokeBlack)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 5)
                            .background(Color.black.opacity(0.05))
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(AppTheme.strokeBlack.opacity(0.2), lineWidth: 1))
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Sheet de Transferência de Imóvel
    
    private var propertyTransferSheet: some View {
        NavigationStack {
            ZStack {
                AppTheme.canvasBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    Text("Vender \(property.name)")
                        .font(.headline.weight(.heavy))
                        .foregroundStyle(Color.white)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Selecione o Comprador:")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(AppTheme.textSecondary)
                        
                        ForEach(otherPlayers) { other in
                            let isSelected = transferBuyerId == other.id
                            buyerSelectionRow(other: other, isSelected: isSelected)
                        }
                        
                        Text("Valor Acordado (R$):")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(AppTheme.textSecondary)
                            .padding(.top, 8)
                        
                        TextField("Valor de venda (opcional)", text: $transferPriceString)
                            .keyboardType(.numberPad)
                            .font(.body.weight(.bold))
                            .padding(10)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.strokeBlack, lineWidth: 1.5))
                    }
                    .padding(16)
                    .background(AppTheme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    
                    Spacer()
                    
                    Tactile3DButton(
                        faceGradient: AppTheme.actionGreenGradient,
                        depthColor: AppTheme.actionGreenDark,
                        cornerRadius: 16,
                        depth: 4.5,
                        strokeWidth: 2,
                        action: {
                            guard let buyerId = transferBuyerId else { return }
                            let price = Decimal(string: transferPriceString) ?? 0
                            viewModel.transferProperty(propertyId: property.id, to: buyerId, price: price)
                            showTransferSheet = false
                        }
                    ) {
                        Text("Confirmar Transferência")
                            .font(.headline.weight(.heavy))
                            .foregroundStyle(Color.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                    }
                    .disabled(transferBuyerId == nil)
                }
                .padding(20)
            }
            .navigationTitle("Negociação de Imóvel")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fechar") {
                        showTransferSheet = false
                    }
                    .foregroundStyle(Color.white)
                }
            }
            .onAppear {
                transferBuyerId = otherPlayers.first?.id
                transferPriceString = "\(property.price)"
            }
        }
        .presentationDetents([.medium, .large])
    }
    
    private func buyerSelectionRow(other: Player, isSelected: Bool) -> some View {
        Button {
            transferBuyerId = other.id
            HapticManager.selection()
        } label: {
            HStack(spacing: 8) {
                Circle()
                    .fill(other.color.color)
                    .frame(width: 14, height: 14)
                
                Text(other.name)
                    .font(.subheadline.weight(.heavy))
                    .foregroundStyle(AppTheme.strokeBlack)
                
                Spacer()
                
                Text("Saldo: \(other.balance.asCurrency)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppTheme.textSecondary)
            }
            .padding(10)
            .background(isSelected ? AppTheme.actionYellow.opacity(0.3) : Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? AppTheme.actionYellow : AppTheme.strokeBlack.opacity(0.15), lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}
