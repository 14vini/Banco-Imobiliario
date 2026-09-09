//
//  PropertyCatalogView.swift
//  BancoImo
//
//  Created by iOS Senior Developer.
//

import SwiftUI

/// Catálogo Geral e Painel de Gestão de Imóveis e Títulos de Propriedade do Banco Imobiliário.
struct PropertyCatalogView: View {
    @Bindable var viewModel: GameViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchText: String = ""
    @State private var selectedFilter: PropertyFilterType = .all
    @State private var selectedPlayerIdFilter: UUID? = nil
    @State private var activePropertyForRent: Property? = nil
    
    enum PropertyFilterType: String, CaseIterable, Identifiable {
        case all = "Todos"
        case unowned = "Banco"
        case owned = "Comprados"
        case mortgaged = "Hipotecados"
        
        var id: String { rawValue }
    }
    
    private var filteredProperties: [Property] {
        var result = viewModel.properties
        
        // Filtro por Categoria
        switch selectedFilter {
        case .all:
            break
        case .unowned:
            result = result.filter { !$0.isOwned }
        case .owned:
            result = result.filter { $0.isOwned }
        case .mortgaged:
            result = result.filter { $0.isMortgaged }
        }
        
        // Filtro por Jogador Específico
        if let playerId = selectedPlayerIdFilter {
            result = result.filter { $0.ownerId == playerId }
        }
        
        // Filtro de Busca
        if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.group.displayName.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return result
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.canvasBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 12) {
                    // MARK: - 1. Métricas Rápidas do Mercado Imobiliário
                    marketSummaryCard
                        .padding(.horizontal, 16)
                        .padding(.top, 6)
                    
                    // MARK: - 2. Filtros de Categoria
                    categoryFilterPicker
                        .padding(.horizontal, 16)
                    
                    // MARK: - 3. Filtro por Jogador
                    if !viewModel.players.isEmpty {
                        playerFilterChipsRow
                    }
                    
                    // MARK: - 4. Lista de Cartões de Imóveis
                    if filteredProperties.isEmpty {
                        emptyStateView
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 14) {
                                ForEach(filteredProperties) { property in
                                    PropertyCardView(
                                        viewModel: viewModel,
                                        property: property,
                                        onOpenRentCalculator: { prop in
                                            activePropertyForRent = prop
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 4)
                            .padding(.bottom, 24)
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Buscar rua ou companhia...")
            .navigationTitle("Catálogo de Imóveis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fechar") {
                        SoundManager.play(.buttonTap)
                        dismiss()
                    }
                    .font(.headline.weight(.heavy))
                    .foregroundStyle(Color.white)
                }
            }
            .sheet(item: $activePropertyForRent) { property in
                QuickRentModalView(viewModel: viewModel, property: property)
            }
        }
    }
    
    // MARK: - Métricas Resumidas da Mesa
    
    private var marketSummaryCard: some View {
        HStack(spacing: 10) {
            summaryMetricItem(
                icon: "building.2.fill",
                title: "VENDIDOS",
                value: "\(viewModel.totalPropertiesOwnedCount)/\(viewModel.properties.count)",
                color: AppTheme.actionYellow
            )
            
            summaryMetricItem(
                icon: "house.fill",
                title: "CASAS",
                value: "\(viewModel.totalHousesBuilt)",
                color: AppTheme.actionGreen
            )
            
            summaryMetricItem(
                icon: "building.fill",
                title: "HOTÉIS",
                value: "\(viewModel.totalHotelsBuilt)",
                color: AppTheme.actionCoral
            )
        }
    }
    
    private func summaryMetricItem(icon: String, title: String, value: String, color: Color) -> some View {
        HStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 26, height: 26)
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(color)
            }
            
            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(.system(size: 8, weight: .black, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
                Text(value)
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppTheme.strokeBlack.opacity(0.12), lineWidth: 1.2))
    }
    
    // MARK: - Filtro de Categoria
    
    private var categoryFilterPicker: some View {
        Picker("Filtro", selection: $selectedFilter) {
            ForEach(PropertyFilterType.allCases) { filter in
                Text(filter.rawValue).tag(filter)
            }
        }
        .pickerStyle(.segmented)
        .onChange(of: selectedFilter) { _, _ in
            HapticManager.selection()
            SoundManager.play(.buttonTap)
        }
    }
    
    // MARK: - Filtro por Jogador
    
    private var playerFilterChipsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Chip "Todos os Donos"
                Button {
                    selectedPlayerIdFilter = nil
                    HapticManager.selection()
                } label: {
                    Text("Todos (\(viewModel.properties.count))")
                        .font(.caption.weight(.heavy))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(selectedPlayerIdFilter == nil ? AppTheme.actionYellow : Color.white.opacity(0.25))
                        .foregroundStyle(selectedPlayerIdFilter == nil ? AppTheme.strokeBlack : Color.white)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(AppTheme.strokeBlack, lineWidth: selectedPlayerIdFilter == nil ? 1.5 : 0.8))
                }
                .buttonStyle(.plain)
                
                ForEach(viewModel.players) { player in
                    let count = viewModel.properties(for: player.id).count
                    let isSelected = selectedPlayerIdFilter == player.id
                    Button {
                        selectedPlayerIdFilter = isSelected ? nil : player.id
                        HapticManager.selection()
                    } label: {
                        HStack(spacing: 5) {
                            Circle()
                                .fill(player.color.color)
                                .frame(width: 8, height: 8)
                            Text("\(player.name) (\(count))")
                                .font(.caption.weight(.heavy))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(isSelected ? AppTheme.actionYellow : Color.white.opacity(0.25))
                        .foregroundStyle(isSelected ? AppTheme.strokeBlack : Color.white)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(AppTheme.strokeBlack, lineWidth: isSelected ? 1.5 : 0.8))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 10) {
            Spacer()
            Image(systemName: "house.slash.fill")
                .font(.system(size: 40))
                .foregroundStyle(Color.white.opacity(0.6))
            Text("Nenhum imóvel encontrado")
                .font(.headline.weight(.heavy))
                .foregroundStyle(Color.white)
            Text("Tente alterar o termo da busca ou os filtros selecionados.")
                .font(.caption)
                .foregroundStyle(Color.white.opacity(0.8))
            Spacer()
        }
    }
}

#Preview {
    let vm = GameViewModel()
    return PropertyCatalogView(viewModel: vm)
}
