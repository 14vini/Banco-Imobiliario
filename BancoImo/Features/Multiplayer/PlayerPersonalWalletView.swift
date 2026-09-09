//
//  PlayerPersonalWalletView.swift
//  BancoImo
//
//  Created by iOS Senior Developer.
//

import SwiftUI
import MultipeerConnectivity

/// Carteira Pessoal do Jogador no iPhone conectado via Multipeer P2P à Mesa Central (iPad).
/// Permite ao jogador controlar seu saldo, propriedades, construções de casas, cobrança de aluguéis e pagamentos com um toque.
struct PlayerPersonalWalletView: View {
    @State private var multipeerService = MultipeerGameService.shared
    let onDisconnect: () -> Void
    
    // Sheets e Modais
    @State private var showPayBankSheet: Bool = false
    @State private var showReceiveBankSheet: Bool = false
    @State private var showTransferPlayerSheet: Bool = false
    @State private var selectedPropertyForAction: Property? = nil
    @State private var showUnownedPropertiesSheet: Bool = false
    @State private var activeTab: WalletTab = .myProperties
    
    enum WalletTab: String, CaseIterable {
        case myProperties = "Minhas Escrituras"
        case bankProperties = "Comprar Imóveis"
        case liveStatement = "Extrato da Mesa"
    }
    
    // Dados reativos sincronizados do Host
    private var packet: GameSyncPacket? {
        multipeerService.latestGamePacket
    }
    
    private var myPlayer: Player? {
        guard let pId = multipeerService.myClaimedPlayerId, let packet = packet else { return nil }
        return packet.players.first(where: { $0.id == pId })
    }
    
    private var myProperties: [Property] {
        guard let pId = multipeerService.myClaimedPlayerId, let packet = packet else { return [] }
        return packet.properties.filter { $0.ownerId == pId }
    }
    
    private var unownedProperties: [Property] {
        guard let packet = packet else { return [] }
        return packet.properties.filter { !$0.isOwned }
    }
    
    private var otherPlayers: [Player] {
        guard let pId = multipeerService.myClaimedPlayerId, let packet = packet else { return [] }
        return packet.players.filter { $0.id != pId && !$0.isBankrupt }
    }
    
    private var myNetWorth: Decimal {
        guard let player = myPlayer else { return 0 }
        let propsValue = myProperties.reduce(Decimal.zero) { $0 + $1.totalValuation }
        return player.balance + propsValue
    }
    
    var body: some View {
        ZStack {
            AppTheme.canvasBackground
                .ignoresSafeArea()
            
            if let packet = packet {
                if myPlayer != nil {
                    // MARK: - Carteira Ativa do Jogador
                    walletMainContent(packet: packet)
                } else {
                    // MARK: - Seleção de Peão / Jogador
                    claimPlayerTokenSelectionView(packet: packet)
                }
            } else {
                // MARK: - Aguardando Sincronização Inicial
                waitingForSyncView
            }
        }
        .sheet(isPresented: $showPayBankSheet) {
            payBankSheetView
        }
        .sheet(isPresented: $showReceiveBankSheet) {
            receiveBankSheetView
        }
        .sheet(isPresented: $showTransferPlayerSheet) {
            transferToPlayerSheetView
        }
        .sheet(item: $selectedPropertyForAction) { prop in
            propertyDetailActionSheet(prop)
        }
    }
    
    // MARK: - 1. Conteúdo Principal da Carteira
    
    private func walletMainContent(packet: GameSyncPacket) -> some View {
        VStack(spacing: 0) {
            // Header com status da conexão e troca de peão
            walletTopBar(packet: packet)
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 12)
            
            ScrollView {
                VStack(spacing: 16) {
                    // Aviso de Sala de Espera se o host ainda estiver configurando
                    if packet.isGameSetupPhase {
                        HStack(spacing: 10) {
                            ProgressView()
                                .tint(AppTheme.strokeBlack)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("SALA DE ESPERA")
                                    .font(.system(size: 10.5, weight: .black, design: .rounded))
                                    .foregroundStyle(AppTheme.strokeBlack)
                                Text("Aguardando o anfitrião iniciar a partida na Mesa...")
                                    .font(.system(size: 11.5, weight: .bold))
                                    .foregroundStyle(AppTheme.strokeBlack.opacity(0.8))
                            }
                            Spacer()
                        }
                        .padding(12)
                        .background(AppTheme.actionYellow.opacity(0.9))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppTheme.strokeBlack, lineWidth: 1.5))
                    }
                    
                    // Card 3D do Jogador com Saldo e Patrimônio
                    if let player = myPlayer {
                        playerHeroCard(player: player)
                    }
                    
                    // Feedback Dinâmico de Rolagem de Dados
                    if let bannerMsg = packet.diceBannerMessage {
                        HStack(spacing: 10) {
                            ZStack {
                                Circle()
                                    .fill(AppTheme.actionYellow)
                                    .frame(width: 32, height: 32)
                                    .overlay(Circle().stroke(AppTheme.strokeBlack, lineWidth: 1.5))
                                Image(systemName: "die.face.5.fill")
                                    .font(.system(size: 16, weight: .black))
                                    .foregroundStyle(AppTheme.strokeBlack)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 6) {
                                    Text("DADOS NA MESA:")
                                        .font(.system(size: 9.5, weight: .black, design: .rounded))
                                        .foregroundStyle(AppTheme.strokeBlack.opacity(0.7))
                                    Text("\(packet.dice1) + \(packet.dice2) = \(packet.dice1 + packet.dice2)")
                                        .font(.system(size: 11, weight: .black, design: .rounded))
                                        .foregroundStyle(AppTheme.strokeBlack)
                                }
                                
                                Text(bannerMsg)
                                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                                    .foregroundStyle(AppTheme.strokeBlack)
                                    .lineLimit(1)
                            }
                            
                            Spacer()
                        }
                        .padding(10)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(AppTheme.strokeBlack, lineWidth: 1.8)
                        )
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(AppTheme.strokeBlack)
                                .offset(x: 2, y: 3)
                        )
                    }
                    
                    // Moedas 3D de Ações Rápidas
                    quickActionCoinsRow
                    
                    // Seletor de Abas (Minhas Escrituras / Comprar / Extrato)
                    tabSelectorHeader
                    
                    // Conteúdo da Aba Selecionada
                    Group {
                        switch activeTab {
                        case .myProperties:
                            myPropertiesTabContent
                        case .bankProperties:
                            bankPropertiesTabContent
                        case .liveStatement:
                            liveStatementTabContent(transactions: packet.transactions)
                        }
                    }
                    .padding(.bottom, 32)
                }
                .padding(.horizontal, 16)
            }
        }
    }
    
    // MARK: - Top Bar da Carteira
    
    private func walletTopBar(packet: GameSyncPacket) -> some View {
        HStack(spacing: 8) {
            // Status de Conexão com a Mesa Central
            HStack(spacing: 6) {
                Circle()
                    .fill(AppTheme.actionGreen)
                    .frame(width: 8, height: 8)
                    .overlay(Circle().stroke(AppTheme.strokeBlack, lineWidth: 1))
                
                VStack(alignment: .leading, spacing: 0) {
                    Text("MESA CENTRAL")
                        .font(.system(size: 8.5, weight: .black, design: .rounded))
                        .foregroundStyle(AppTheme.strokeBlack.opacity(0.6))
                        .tracking(0.6)
                    Text(packet.hostDeviceName)
                        .font(.system(size: 11.5, weight: .black, design: .rounded))
                        .foregroundStyle(AppTheme.strokeBlack)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.white)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(AppTheme.strokeBlack, lineWidth: 1.5))
            
            Spacer()
            
            // Botão Trocar Peão
            Button {
                SoundManager.play(.buttonTap)
                HapticManager.impact(.light)
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    multipeerService.releasePlayerToken()
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "person.2.badge.gearshape.fill")
                        .font(.system(size: 11, weight: .black))
                    Text("Peão")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                }
                .foregroundStyle(AppTheme.strokeBlack)
                .padding(.horizontal, 9)
                .padding(.vertical, 6)
                .background(AppTheme.actionYellow)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(AppTheme.strokeBlack, lineWidth: 1.5))
            }
            
            // Botão Sair / Desconectar
            Button {
                SoundManager.play(.buttonTap)
                HapticManager.impact(.medium)
                multipeerService.stopAllServices()
                onDisconnect()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(AppTheme.strokeBlack)
                    .frame(width: 28, height: 28)
                    .background(Color.white)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(AppTheme.strokeBlack, lineWidth: 1.5))
            }
        }
    }
    
    // MARK: - Cartão Hero do Jogador
    
    private func playerHeroCard(player: Player) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(player.color.color)
                        .frame(width: 20, height: 20)
                        .overlay(Circle().stroke(AppTheme.strokeBlack, lineWidth: 1.8))
                    
                    Text(player.name)
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                        .foregroundStyle(AppTheme.strokeBlack)
                }
                
                Spacer()
                
                // Badge de Falência ou Status Ativo
                if player.isBankrupt {
                    Text("FALIDO")
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .foregroundStyle(Color.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppTheme.gameCoral)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(AppTheme.strokeBlack, lineWidth: 1.5))
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "building.2.fill")
                            .font(.system(size: 10, weight: .bold))
                        Text("\(myProperties.count) imóveis")
                            .font(.system(size: 11, weight: .black, design: .rounded))
                    }
                    .foregroundStyle(AppTheme.strokeBlack)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(AppTheme.strokeBlack, lineWidth: 1.2))
                }
            }
            
            // Saldo em Dinheiro
            VStack(alignment: .leading, spacing: 2) {
                Text("SALDO EM CONTA")
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .foregroundStyle(AppTheme.strokeBlack.opacity(0.65))
                    .tracking(0.8)
                
                Text(player.balance.asCurrency)
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                    .foregroundStyle(AppTheme.strokeBlack)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            
            Divider()
                .overlay(AppTheme.strokeBlack.opacity(0.2))
            
            // Patrimônio Líquido Total
            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Patrimônio Total (Dinheiro + Imóveis)")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.strokeBlack.opacity(0.7))
                    Text(myNetWorth.asCurrency)
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .foregroundStyle(AppTheme.strokeBlack)
                }
                Spacer()
            }
        }
        .padding(18)
        .background(
            LinearGradient(
                colors: [player.color.color.opacity(0.35), Color.white],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(AppTheme.strokeBlack, lineWidth: 2.5)
        )
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(AppTheme.strokeBlack)
                .offset(x: 3.5, y: 5)
        )
    }
    
    // MARK: - Moedas 3D de Ação Rápida
    
    private var quickActionCoinsRow: some View {
        VStack(spacing: 10) {
            // Linha 1: Salário Gigante (+2.000)
            Tactile3DButton(
                faceGradient: AppTheme.actionGreenGradient,
                depthColor: AppTheme.actionGreenDark,
                cornerRadius: 16,
                depth: 4.5,
                strokeWidth: 2,
                highlightColor: Color.white.opacity(0.4),
                action: {
                    guard let pId = multipeerService.myClaimedPlayerId else { return }
                    SoundManager.play(.salary)
                    HapticManager.impact(.heavy)
                    multipeerService.sendAction(.receiveSalary(playerId: pId, amount: 2000))
                }
            ) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.counterclockwise.circle.fill")
                        .font(.system(size: 18, weight: .black))
                    Text("Passou pelo Início (+R$ 2.000)")
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                }
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity)
                .frame(height: 46)
            }
            
            // Linha 2: 4 Ações Principais (Pagar Banco, Receber Banco, Transferir Amigo, Rolar Dados)
            HStack(spacing: 8) {
                // Pagar Banco
                quickCoinButton(
                    title: "Pagar\nBanco",
                    icon: "creditcard.fill",
                    color: AppTheme.gameCoral,
                    action: { showPayBankSheet = true }
                )
                
                // Receber Banco
                quickCoinButton(
                    title: "Receber\nBanco",
                    icon: "banknote.fill",
                    color: AppTheme.actionGreen,
                    action: { showReceiveBankSheet = true }
                )
                
                // Transferir Amigo
                quickCoinButton(
                    title: "Pagar\nAmigo",
                    icon: "paperplane.fill",
                    color: AppTheme.actionBlue,
                    action: { showTransferPlayerSheet = true }
                )
                
                // Rolar Dados na Mesa
                quickCoinButton(
                    title: "Rolar\nDados",
                    icon: "die.face.5.fill",
                    color: AppTheme.actionYellow,
                    action: {
                        guard let pId = multipeerService.myClaimedPlayerId else { return }
                        SoundManager.play(.diceRoll)
                        HapticManager.impact(.medium)
                        multipeerService.sendAction(.rollDice(playerId: pId))
                    }
                )
            }
        }
    }
    
    private func quickCoinButton(
        title: String,
        icon: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            SoundManager.play(.buttonTap)
            HapticManager.impact(.medium)
            action()
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundStyle(AppTheme.strokeBlack)
                
                Text(title)
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .foregroundStyle(AppTheme.strokeBlack)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(AppTheme.strokeBlack, lineWidth: 1.8)
            )
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(AppTheme.strokeBlack)
                    .offset(x: 2, y: 3)
            )
        }
    }
    
    // MARK: - Seletor de Abas
    
    private var tabSelectorHeader: some View {
        HStack(spacing: 6) {
            ForEach(WalletTab.allCases, id: \.self) { tab in
                let isSelected = activeTab == tab
                Button {
                    SoundManager.play(.buttonTap)
                    HapticManager.selection()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        activeTab = tab
                    }
                } label: {
                    Text(tab.rawValue)
                        .font(.system(size: 11.5, weight: .black, design: .rounded))
                        .foregroundStyle(isSelected ? AppTheme.strokeBlack : Color.white.opacity(0.85))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(isSelected ? AppTheme.actionYellow : Color.white.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(isSelected ? AppTheme.strokeBlack : Color.clear, lineWidth: 1.5)
                        )
                }
            }
        }
        .padding(4)
        .background(AppTheme.strokeBlack.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    
    // MARK: - Aba 1: Minhas Propriedades
    
    private var myPropertiesTabContent: some View {
        VStack(spacing: 12) {
            if myProperties.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "building.2.slash")
                        .font(.system(size: 32))
                        .foregroundStyle(AppTheme.textSecondary.opacity(0.7))
                    Text("Você ainda não possui nenhum imóvel.")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                    
                    Button {
                        withAnimation { activeTab = .bankProperties }
                    } label: {
                        Text("Ver Imóveis à Venda")
                            .font(.system(size: 12, weight: .heavy, design: .rounded))
                            .foregroundStyle(AppTheme.strokeBlack)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(AppTheme.actionYellow)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(AppTheme.strokeBlack, lineWidth: 1.2))
                    }
                }
                .padding(.vertical, 32)
                .frame(maxWidth: .infinity)
                .background(Color.white.opacity(0.7))
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(AppTheme.strokeBlack.opacity(0.2), lineWidth: 1))
            } else {
                ForEach(myProperties) { prop in
                    propertyPortfolioRow(prop)
                }
            }
        }
    }
    
    private func propertyPortfolioRow(_ prop: Property) -> some View {
        Button {
            SoundManager.play(.buttonTap)
            selectedPropertyForAction = prop
        } label: {
            HStack(spacing: 12) {
                // Faixa Colorida do Bairro
                RoundedRectangle(cornerRadius: 6)
                    .fill(prop.group.headerColor)
                    .frame(width: 14, height: 48)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(AppTheme.strokeBlack, lineWidth: 1))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(prop.name)
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundStyle(AppTheme.strokeBlack)
                    
                    HStack(spacing: 6) {
                        if prop.isMortgaged {
                            Text("HIPOTECADO")
                                .font(.system(size: 9.5, weight: .black))
                                .foregroundStyle(Color.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(AppTheme.gameCoral)
                                .clipShape(Capsule())
                        } else if prop.isHotel {
                            Text("HOTEL 🏨")
                                .font(.system(size: 9.5, weight: .black))
                                .foregroundStyle(AppTheme.strokeBlack)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(AppTheme.gameCoral.opacity(0.2))
                                .clipShape(Capsule())
                        } else if prop.housesCount > 0 {
                            Text("\(prop.housesCount)x Casas 🏠")
                                .font(.system(size: 9.5, weight: .black))
                                .foregroundStyle(AppTheme.strokeBlack)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(AppTheme.actionGreen.opacity(0.2))
                                .clipShape(Capsule())
                        } else {
                            Text("Sem construções")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Gerenciar")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .foregroundStyle(AppTheme.strokeBlack)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(AppTheme.strokeBlack)
                }
            }
            .padding(12)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(AppTheme.strokeBlack, lineWidth: 1.8)
            )
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(AppTheme.strokeBlack)
                    .offset(x: 2, y: 3)
            )
        }
    }
    
    // MARK: - Aba 2: Comprar Imóveis do Banco
    
    private var bankPropertiesTabContent: some View {
        VStack(spacing: 10) {
            ForEach(unownedProperties) { prop in
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(prop.group.headerColor)
                        .frame(width: 14, height: 44)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(AppTheme.strokeBlack, lineWidth: 1))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(prop.name)
                            .font(.system(size: 13, weight: .heavy, design: .rounded))
                            .foregroundStyle(AppTheme.strokeBlack)
                        Text(prop.group.displayName)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    
                    Spacer()
                    
                    Button {
                        guard let pId = multipeerService.myClaimedPlayerId else { return }
                        SoundManager.play(.salary)
                        HapticManager.impact(.medium)
                        multipeerService.sendAction(.buyProperty(propertyId: prop.id, playerId: pId))
                    } label: {
                        HStack(spacing: 4) {
                            Text("Comprar")
                                .font(.system(size: 11, weight: .black, design: .rounded))
                            Text(prop.price.asCurrency)
                                .font(.system(size: 10.5, weight: .heavy, design: .rounded))
                        }
                        .foregroundStyle(AppTheme.strokeBlack)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(AppTheme.actionYellow)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(AppTheme.strokeBlack, lineWidth: 1.5))
                    }
                }
                .padding(10)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppTheme.strokeBlack, lineWidth: 1.5))
            }
        }
    }
    
    // MARK: - Aba 3: Extrato da Mesa em Tempo Real
    
    private func liveStatementTabContent(transactions: [Transaction]) -> some View {
        VStack(spacing: 8) {
            if transactions.isEmpty {
                Text("Nenhuma transação registrada ainda.")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(AppTheme.textSecondary)
                    .padding(.vertical, 24)
            } else {
                ForEach(transactions.prefix(15)) { tx in
                    HStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(AppTheme.actionYellow.opacity(0.3))
                                .frame(width: 32, height: 32)
                                .overlay(Circle().stroke(AppTheme.strokeBlack.opacity(0.2), lineWidth: 1))
                            Image(systemName: tx.type.iconName)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(AppTheme.strokeBlack)
                        }
                        
                        VStack(alignment: .leading, spacing: 1) {
                            Text(tx.title)
                                .font(.system(size: 12, weight: .heavy, design: .rounded))
                                .foregroundStyle(AppTheme.strokeBlack)
                            Text(tx.subtitle)
                                .font(.system(size: 10.5, weight: .medium))
                                .foregroundStyle(AppTheme.textSecondary)
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        if tx.amount > 0 {
                            Text(tx.amount.asCurrency)
                                .font(.system(size: 12, weight: .heavy, design: .rounded))
                                .foregroundStyle(AppTheme.strokeBlack)
                        }
                    }
                    .padding(10)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.strokeBlack.opacity(0.15), lineWidth: 1))
                }
            }
        }
    }
    
    // MARK: - 2. Tela de Seleção do Peão / Jogador
    
    private func claimPlayerTokenSelectionView(packet: GameSyncPacket) -> some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                // Status da Mesa
                HStack(spacing: 6) {
                    Circle()
                        .fill(AppTheme.actionGreen)
                        .frame(width: 8, height: 8)
                    Text("MESA: \(packet.hostDeviceName)")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundStyle(AppTheme.strokeBlack)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.white)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(AppTheme.strokeBlack, lineWidth: 1.5))
                
                Spacer()
                
                Button {
                    SoundManager.play(.buttonTap)
                    multipeerService.stopAllServices()
                    onDisconnect()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .black))
                        .foregroundStyle(AppTheme.strokeBlack)
                        .frame(width: 28, height: 28)
                        .background(Color.white)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(AppTheme.strokeBlack, lineWidth: 1.5))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            
            VStack(spacing: 6) {
                Text("Quem é você no jogo?")
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                    .foregroundStyle(AppTheme.strokeBlack)
                
                Text(packet.isGameSetupPhase
                     ? "Mesa em configuração! Escolha seu peão para entrar no lobby."
                     : "Toque no seu nome para assumir sua carteira pessoal")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            
            if packet.players.isEmpty {
                VStack(spacing: 12) {
                    ProgressView()
                        .tint(AppTheme.strokeBlack)
                    Text("O anfitrião está cadastrando os jogadores na Mesa...")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .padding(.vertical, 40)
                .frame(maxWidth: .infinity)
                .background(Color.white.opacity(0.8))
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .padding(.horizontal, 20)
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(packet.players) { player in
                            playerSelectionRow(player, packet: packet)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
            
            Spacer()
        }
    }
    
    private func playerSelectionRow(_ player: Player, packet: GameSyncPacket) -> some View {
        let isHost = (player.id == packet.hostPlayerId)
        let claimedDevice = packet.claimedPlayerDeviceNames[player.id]
        let isClaimedByMe = claimedDevice == multipeerService.myPeerID.displayName
        let isClaimedByOther = (claimedDevice != nil && !isClaimedByMe) || (isHost && !isClaimedByMe && claimedDevice == nil)
        
        return Button {
            guard !isClaimedByOther else { return }
            SoundManager.play(.buttonTap)
            HapticManager.impact(.medium)
            multipeerService.claimPlayerToken(player.id)
        } label: {
            HStack(spacing: 14) {
                // Avatar Token com Relevo
                ZStack {
                    Circle()
                        .fill(isClaimedByOther ? Color.gray.opacity(0.6) : player.color.color)
                        .frame(width: 36, height: 36)
                        .overlay(Circle().stroke(AppTheme.strokeBlack, lineWidth: 2))
                    
                    Text(String(player.name.prefix(1)).uppercased())
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .foregroundStyle(Color.white)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(player.name)
                            .font(.system(size: 16, weight: .heavy, design: .rounded))
                            .foregroundStyle(isClaimedByOther ? AppTheme.strokeBlack.opacity(0.6) : AppTheme.strokeBlack)
                        
                        Circle()
                            .fill(player.color.color)
                            .frame(width: 8, height: 8)
                            .overlay(Circle().stroke(AppTheme.strokeBlack, lineWidth: 1))
                    }
                    
                    if isHost && !isClaimedByMe {
                        HStack(spacing: 3) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 9))
                            Text("Anfitrião (Mesa Central)")
                                .font(.system(size: 11, weight: .heavy, design: .rounded))
                        }
                        .foregroundStyle(AppTheme.actionYellowDark)
                    } else if let device = claimedDevice {
                        if isClaimedByMe {
                            Text("📱 Seu peão atual")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundStyle(AppTheme.actionGreenDark)
                        } else {
                            Text("🔒 Ocupado por \(device)")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundStyle(AppTheme.gameCoral)
                        }
                    } else {
                        Text("✨ Livre • Saldo: \(player.balance.asCurrency)")
                            .font(.system(size: 11.5, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.actionGreenDark)
                    }
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    if isClaimedByOther {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 10, weight: .black))
                        Text("Ocupado")
                            .font(.system(size: 11, weight: .heavy, design: .rounded))
                    } else if isClaimedByMe {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12, weight: .bold))
                        Text("Seu Peão")
                            .font(.system(size: 11.5, weight: .heavy, design: .rounded))
                    } else {
                        Text("Escolher")
                            .font(.system(size: 12, weight: .heavy, design: .rounded))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 10, weight: .black))
                    }
                }
                .foregroundStyle(isClaimedByOther ? Color.gray : AppTheme.strokeBlack)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(
                    isClaimedByOther
                    ? Color(white: 0.92)
                    : (isClaimedByMe ? AppTheme.actionGreen : AppTheme.actionYellow)
                )
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(
                        isClaimedByOther ? Color.gray.opacity(0.5) : AppTheme.strokeBlack,
                        lineWidth: isClaimedByOther ? 1 : 1.5
                    )
                )
            }
            .padding(14)
            .background(isClaimedByOther ? Color(white: 0.96) : Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(isClaimedByOther ? Color.black.opacity(0.12) : AppTheme.strokeBlack, lineWidth: isClaimedByOther ? 1.2 : 2)
            )
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(isClaimedByOther ? Color.clear : AppTheme.strokeBlack)
                    .offset(x: isClaimedByOther ? 0 : 2.5, y: isClaimedByOther ? 0 : 3.5)
            )
        }
        .disabled(isClaimedByOther)
    }
    
    // MARK: - 3. Aguardando Sincronização
    
    private var waitingForSyncView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(AppTheme.strokeBlack)
                .scaleEffect(1.3)
            
            Text("Conectando à Mesa Central...")
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundStyle(AppTheme.strokeBlack)
            
            Text("Sincronizando dados em tempo real via P2P")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)
            
            Button("Cancelar") {
                multipeerService.stopAllServices()
                onDisconnect()
            }
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(AppTheme.gameCoral)
            .padding(.top, 12)
        }
        .padding(32)
    }
    
    // MARK: - Modal de Ações no Imóvel (Construir, Vender Casa, Hipoteca, Cobrar Aluguel)
    
    private func propertyDetailActionSheet(_ prop: Property) -> some View {
        NavigationStack {
            ZStack {
                AppTheme.canvasBackground.ignoresSafeArea()
                
                VStack(spacing: 16) {
                    // Cabeçalho da Escritura
                    VStack(spacing: 6) {
                        Text(prop.name)
                            .font(.system(size: 20, weight: .heavy, design: .rounded))
                            .foregroundStyle(AppTheme.strokeBlack)
                        
                        Text(prop.group.displayName)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(prop.group.headerColor)
                    }
                    .padding(.top, 10)
                    
                    VStack(spacing: 10) {
                        // Construir Casa
                        if prop.canBuildHouse {
                            actionSheetButton(
                                title: prop.housesCount == 4 ? "Construir Hotel 🏨" : "Construir Casa 🏠",
                                subtitle: "Custo: \(prop.houseCost.asCurrency)",
                                icon: "hammer.fill",
                                color: AppTheme.actionGreen
                            ) {
                                guard let pId = multipeerService.myClaimedPlayerId else { return }
                                SoundManager.play(.buttonTap)
                                multipeerService.sendAction(.buildHouse(propertyId: prop.id, playerId: pId))
                                selectedPropertyForAction = nil
                            }
                        }
                        
                        // Vender Casa
                        if prop.canSellHouse {
                            actionSheetButton(
                                title: "Vender Casa (-1🏠)",
                                subtitle: "Reembolso: \(prop.houseSellRefund.asCurrency)",
                                icon: "arrow.down.square.fill",
                                color: AppTheme.actionYellow
                            ) {
                                guard let pId = multipeerService.myClaimedPlayerId else { return }
                                SoundManager.play(.buttonTap)
                                multipeerService.sendAction(.sellHouse(propertyId: prop.id, playerId: pId))
                                selectedPropertyForAction = nil
                            }
                        }
                        
                        // Hipotecar / Resgatar Hipoteca
                        if prop.isMortgaged {
                            actionSheetButton(
                                title: "Resgatar Hipoteca",
                                subtitle: "Pagar ao Banco: \(prop.unmortgageCost.asCurrency)",
                                icon: "arrow.counterclockwise.circle.fill",
                                color: AppTheme.actionBlue
                            ) {
                                guard let pId = multipeerService.myClaimedPlayerId else { return }
                                SoundManager.play(.buttonTap)
                                multipeerService.sendAction(.unmortgageProperty(propertyId: prop.id, playerId: pId))
                                selectedPropertyForAction = nil
                            }
                        } else if prop.canMortgage {
                            actionSheetButton(
                                title: "Hipotecar Imóvel 📄",
                                subtitle: "Receber do Banco: \(prop.mortgageValue.asCurrency)",
                                icon: "doc.plaintext.fill",
                                color: AppTheme.gameCoral
                            ) {
                                guard let pId = multipeerService.myClaimedPlayerId else { return }
                                SoundManager.play(.buttonTap)
                                multipeerService.sendAction(.mortgageProperty(propertyId: prop.id, playerId: pId))
                                selectedPropertyForAction = nil
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Cobrar Aluguel de Amigo que Caiu Aqui
                    if !prop.isMortgaged && !otherPlayers.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("COBRAR ALUGUEL DE JOGADOR")
                                .font(.system(size: 10, weight: .black, design: .rounded))
                                .foregroundStyle(AppTheme.strokeBlack.opacity(0.7))
                                .tracking(0.6)
                            
                            ForEach(otherPlayers) { other in
                                Button {
                                    SoundManager.play(.salary)
                                    HapticManager.impact(.heavy)
                                    multipeerService.sendAction(.chargeRent(propertyId: prop.id, payerId: other.id, diceSum: nil))
                                    selectedPropertyForAction = nil
                                } label: {
                                    HStack {
                                        Circle()
                                            .fill(other.color.color)
                                            .frame(width: 14, height: 14)
                                        Text("\(other.name) caiu aqui")
                                            .font(.system(size: 13, weight: .heavy, design: .rounded))
                                            .foregroundStyle(AppTheme.strokeBlack)
                                        Spacer()
                                        Text("Cobrar")
                                            .font(.system(size: 11, weight: .black, design: .rounded))
                                            .foregroundStyle(AppTheme.strokeBlack)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 5)
                                            .background(AppTheme.actionGreen)
                                            .clipShape(Capsule())
                                            .overlay(Capsule().stroke(AppTheme.strokeBlack, lineWidth: 1.2))
                                    }
                                    .padding(12)
                                    .background(Color.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.strokeBlack, lineWidth: 1.5))
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    Spacer()
                }
            }
            .navigationTitle("Ações do Imóvel")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fechar") {
                        selectedPropertyForAction = nil
                    }
                    .font(.system(size: 13, weight: .bold))
                }
            }
        }
    }
    
    private func actionSheetButton(
        title: String,
        subtitle: String,
        icon: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(AppTheme.strokeBlack)
                    .frame(width: 36, height: 36)
                    .background(color.opacity(0.3))
                    .clipShape(Circle())
                    .overlay(Circle().stroke(AppTheme.strokeBlack, lineWidth: 1.2))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundStyle(AppTheme.strokeBlack)
                    Text(subtitle)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(AppTheme.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(AppTheme.strokeBlack)
            }
            .padding(12)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppTheme.strokeBlack, lineWidth: 1.8))
        }
    }
    
    // MARK: - Modais de Ajuste com Banco e Transferência
    
    @State private var customAmountInput: String = ""
    @State private var customReasonInput: String = ""
    
    private var payBankSheetView: some View {
        quickAmountModal(
            title: "Pagar ao Banco",
            isDeposit: false,
            onConfirm: { amount, reason in
                guard let pId = multipeerService.myClaimedPlayerId else { return }
                multipeerService.sendAction(.adjustBalance(playerId: pId, delta: -amount, reason: reason))
                showPayBankSheet = false
            }
        )
    }
    
    private var receiveBankSheetView: some View {
        quickAmountModal(
            title: "Receber do Banco",
            isDeposit: true,
            onConfirm: { amount, reason in
                guard let pId = multipeerService.myClaimedPlayerId else { return }
                multipeerService.sendAction(.adjustBalance(playerId: pId, delta: amount, reason: reason))
                showReceiveBankSheet = false
            }
        )
    }
    
    private func quickAmountModal(
        title: String,
        isDeposit: Bool,
        onConfirm: @escaping (Decimal, String?) -> Void
    ) -> some View {
        NavigationStack {
            ZStack {
                AppTheme.canvasBackground.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Text(title)
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundStyle(AppTheme.strokeBlack)
                        .padding(.top, 16)
                    
                    // Valores Rápidos
                    HStack(spacing: 8) {
                        ForEach([50, 100, 200, 500], id: \.self) { val in
                            Button {
                                SoundManager.play(.buttonTap)
                                onConfirm(Decimal(val), isDeposit ? "Recebido do Banco" : "Pago ao Banco")
                            } label: {
                                Text("R$ \(val)")
                                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                                    .foregroundStyle(AppTheme.strokeBlack)
                                    .padding(.vertical, 10)
                                    .frame(maxWidth: .infinity)
                                    .background(isDeposit ? AppTheme.actionGreen : AppTheme.actionYellow)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.strokeBlack, lineWidth: 1.5))
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Entrada de Valor Personalizado
                    VStack(alignment: .leading, spacing: 8) {
                        Text("OUTRO VALOR")
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .foregroundStyle(AppTheme.textSecondary)
                        
                        TextField("Valor (ex: 350)", text: $customAmountInput)
                            .keyboardType(.numberPad)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .padding(12)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.strokeBlack, lineWidth: 1.5))
                        
                        TextField("Motivo (ex: Prisão / Sorte ou Revés)", text: $customReasonInput)
                            .font(.system(size: 14, weight: .medium))
                            .padding(12)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.strokeBlack, lineWidth: 1.5))
                        
                        Button {
                            if let val = Decimal(string: customAmountInput), val > 0 {
                                SoundManager.play(.buttonTap)
                                onConfirm(val, customReasonInput.isEmpty ? nil : customReasonInput)
                                customAmountInput = ""
                                customReasonInput = ""
                            }
                        } label: {
                            Text("Confirmar")
                                .font(.system(size: 14, weight: .heavy, design: .rounded))
                                .foregroundStyle(AppTheme.strokeBlack)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(isDeposit ? AppTheme.actionGreen : AppTheme.actionYellow)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppTheme.strokeBlack, lineWidth: 1.8))
                        }
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancelar") {
                        showPayBankSheet = false
                        showReceiveBankSheet = false
                    }
                    .font(.system(size: 13, weight: .bold))
                }
            }
        }
    }
    
    @State private var selectedReceiverId: UUID? = nil
    @State private var transferAmountInput: String = ""
    
    private var transferToPlayerSheetView: some View {
        NavigationStack {
            ZStack {
                AppTheme.canvasBackground.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Text("Pagar Jogador")
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundStyle(AppTheme.strokeBlack)
                        .padding(.top, 16)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("SELECIONE O DESTINATÁRIO")
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .foregroundStyle(AppTheme.textSecondary)
                        
                        ForEach(otherPlayers) { other in
                            Button {
                                selectedReceiverId = other.id
                            } label: {
                                HStack {
                                    Circle()
                                        .fill(other.color.color)
                                        .frame(width: 14, height: 14)
                                    Text(other.name)
                                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                                        .foregroundStyle(AppTheme.strokeBlack)
                                    Spacer()
                                    if selectedReceiverId == other.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(AppTheme.actionGreen)
                                    }
                                }
                                .padding(12)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(selectedReceiverId == other.id ? AppTheme.actionGreen : AppTheme.strokeBlack, lineWidth: 1.8)
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("VALOR DA TRANSFERÊNCIA")
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .foregroundStyle(AppTheme.textSecondary)
                        
                        TextField("Valor em R$", text: $transferAmountInput)
                            .keyboardType(.numberPad)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .padding(12)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.strokeBlack, lineWidth: 1.5))
                        
                        Button {
                            guard let pId = multipeerService.myClaimedPlayerId,
                                  let targetId = selectedReceiverId,
                                  let amount = Decimal(string: transferAmountInput), amount > 0 else { return }
                            
                            SoundManager.play(.salary)
                            HapticManager.impact(.heavy)
                            multipeerService.sendAction(.transferMoney(fromPlayerId: pId, toPlayerId: targetId, amount: amount))
                            transferAmountInput = ""
                            selectedReceiverId = nil
                            showTransferPlayerSheet = false
                        } label: {
                            Text("Realizar Pagamento")
                                .font(.system(size: 14, weight: .heavy, design: .rounded))
                                .foregroundStyle(AppTheme.strokeBlack)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(AppTheme.actionGreen)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppTheme.strokeBlack, lineWidth: 1.8))
                        }
                        .padding(.top, 6)
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancelar") {
                        showTransferPlayerSheet = false
                    }
                    .font(.system(size: 13, weight: .bold))
                }
            }
        }
    }
}
