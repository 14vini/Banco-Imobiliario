//
//  GameDashboardView.swift
//  BancoImo
//
//  Created by iOS Senior Developer.
//

import SwiftUI

/// Dashboard principal da partida com estética lúdica Neo-Brutalist (estilo MyWallet),
/// suporte adaptativo total para iPad e iPhone, Cartão 3D Inclinado, Moedas de Ação Amarelas, Cronômetro, Áudio FX e Desfazer.
struct GameDashboardView: View {
    @Bindable var viewModel: GameViewModel
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    // Jogador atualmente selecionado na rodada
    @State private var selectedPlayerId: UUID? = nil
    
    // Modal de transação para iPhone ou toque detalhado
    @State private var activePlayerForTransaction: Player? = nil
    
    // Sheet de Extrato Geral e Gráficos
    @State private var showTransactionHistory: Bool = false
    
    // Sheet de Gestão de Imóveis & Títulos de Propriedade
    @State private var showPropertiesSheet: Bool = false
    
    // Sheet de Configurações da Mesa
    @State private var showSettingsSheet: Bool = false
    
    // Modal de Mesa Remota P2P & QR Code
    @State private var showMultiplayerHostModal: Bool = false
    @State private var multipeerService = MultipeerGameService.shared
    
    /// Indica se a interface deve utilizar a visualização ampla de 2 colunas para iPad.
    private var isPadLayout: Bool {
        horizontalSizeClass == .regular
    }
    
    // Jogadores ordenados por maior saldo (Ranking da mesa)
    private var rankedPlayers: [Player] {
        viewModel.players.sorted { p1, p2 in
            if p1.isBankrupt != p2.isBankrupt {
                return !p1.isBankrupt // Não-falidos primeiro
            }
            return p1.balance > p2.balance
        }
    }
    
    // Jogador ativo em destaque
    private var activePlayer: Player {
        if let id = selectedPlayerId, let found = viewModel.players.first(where: { $0.id == id }) {
            return found
        }
        return viewModel.players.first ?? Player(name: "Jogador", balance: 1500, color: .blue)
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                // Fundo Lúdico Periwinkle
                AppTheme.canvasBackground
                    .ignoresSafeArea()
                
                if isPadLayout {
                    // MARK: - Layout iPad (2 Colunas / Mesa Lúdica)
                    ipadTwoColumnLayout
                } else {
                    // MARK: - Layout iPhone (Fluxo Vertical Lúdico)
                    iphoneSingleColumnLayout
                }
                
                // MARK: - Toast Flutuante de Ação Remota na Mesa Central (iPhone -> iPad)
                if let notif = viewModel.remoteActionNotification {
                    remoteActionNotificationView(notif)
                        .padding(.top, 12)
                        .transition(.asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity).combined(with: .scale(scale: 0.9)),
                            removal: .move(edge: .top).combined(with: .opacity)
                        ))
                        .zIndex(200)
                }
                
                // MARK: - Toast Flutuante de Ação Desfeita (Undo)
                if let undoMsg = viewModel.undoToastMessage {
                    UndoToastView(message: undoMsg) {
                        withAnimation {
                            viewModel.undoToastMessage = nil
                        }
                    }
                    .padding(.top, 8)
                    .zIndex(100)
                }
                
                // MARK: - Dock Flutuante (Apenas iPhone)
                if !isPadLayout {
                    VStack {
                        Spacer()
                        floatingBottomDock
                    }
                    .zIndex(50)
                }
            }
            .navigationBarHidden(true)
            // Diálogo de confirmação de reset
            .confirmationDialog(
                "Encerrar Partida",
                isPresented: $viewModel.showResetConfirmation,
                titleVisibility: .visible
            ) {
                Button("Encerrar e Apagar Jogo", role: .destructive) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                        viewModel.resetGame()
                    }
                }
                Button("Continuar Jogando", role: .cancel) {}
            } message: {
                Text("Deseja realmente apagar a partida e todo o extrato da mesa?")
            }
            // Sheet de Transações e Ajustes
            .sheet(item: $activePlayerForTransaction) { player in
                TransactionModalView(viewModel: viewModel, player: player)
            }
            // Sheet de Gestão de Imóveis & Títulos
            .sheet(isPresented: $showPropertiesSheet) {
                PropertyCatalogView(viewModel: viewModel)
            }
            // Sheet de Extrato Geral e Gráficos Swift Charts
            .sheet(isPresented: $showTransactionHistory) {
                TransactionHistoryView(viewModel: viewModel)
            }
            // Sheet de Configurações da Mesa (iPad / iPhone)
            .sheet(isPresented: $showSettingsSheet) {
                tableSettingsSheet
            }
            // Sheet de Mesa Remota P2P & QR Code do Host
            .sheet(isPresented: $showMultiplayerHostModal) {
                MultiplayerHostModalView(viewModel: viewModel)
            }
            .onAppear {
                if selectedPlayerId == nil {
                    selectedPlayerId = viewModel.players.first?.id
                }
                if multipeerService.role != .host {
                    multipeerService.startHosting(gameId: UUID())
                }
            }
        }
    }
    
    // MARK: - Layout iPad Multi-Coluna (Split View com Cartão 3D Hero, Placar Compacto e Caixa Full Height)
    
    private var ipadTwoColumnLayout: some View {
        VStack(spacing: 12) {
            // Barra Superior de Status, Cronômetro e Atalhos Globais
            topNavBar
            
            HStack(alignment: .top, spacing: 20) {
                // Coluna Esquerda: Cartão 3D Hero + Placar Compacto ao Lado + 4 Moedas + Dados + Extrato Inline
                VStack{
                    VStack(alignment: .center, spacing: 18) {
                        // 1. Linha Superior: Cartão Hero 3D Inclinado + Lista Compacta de Saldos com Quem Está Ganhando
                        HStack(alignment: .top, spacing: 16) {
                            // Cartão Hero 3D Inclinado com Seletor de Peões
                            PlayfulHeroCardView(
                                player: activePlayer,
                                players: viewModel.players,
                                properties: viewModel.properties,
                                onSelectPlayer: { p in
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                        selectedPlayerId = p.id
                                    }
                                },
                                onOpenCardActions: {
                                    selectedPlayerId = activePlayer.id
                                }
                            )
                            
                            // Lista Compacta de Saldos & Quem está Ganhando
                            CompactLeaderboardWidget(
                                players: viewModel.players,
                                properties: viewModel.properties,
                                selectedPlayerId: selectedPlayerId,
                                onSelectPlayer: { p in
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                        selectedPlayerId = p.id
                                    }
                                }
                            )
                        }
                        .padding(.horizontal, 4)
                        
                        // 2. 5 Moedas 3D de Ação Rápida
                        fiveActionCoinsRow
                            .padding(.horizontal, 6)
                        
                        // 3. Dados Virtuais (se ativados)
                        if viewModel.isDiceEnabled {
                            DiceRollerView(viewModel: viewModel)
                                .transition(.asymmetric(
                                    insertion: .scale(scale: 0.96).combined(with: .opacity).combined(with: .move(edge: .top)),
                                    removal: .scale(scale: 0.96).combined(with: .opacity)
                                ))
                                .padding(.horizontal, 4)
                        }
                        
                        // 4. Extrato em Tempo Real Embutido (Abaixo dos dados)
                        InlineStatementCardView(
                            viewModel: viewModel,
                            onOpenFullCharts: {
                                showTransactionHistory = true
                            }
                        )
                        .padding(.horizontal, 4)
                    }
                    .padding(.bottom, 16)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                
                // Coluna Direita: Caixa / Painel Integrado de Operações ocupando todo o height
                IntegratedOperationPanel(
                    viewModel: viewModel,
                    selectedPlayerId: $selectedPlayerId
                )
                .frame(width: 370)
                .frame(maxHeight: .infinity)
            }
            .frame(maxHeight: .infinity)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .frame(maxHeight: .infinity)
    }
    
    // MARK: - Layout iPhone (Coluna Única Lúdica)
    
    private var iphoneSingleColumnLayout: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 20) {
                // Top Bar
                topNavBar
                
                // Cartão Hero 3D Inclinado
                PlayfulHeroCardView(
                    player: activePlayer,
                    players: viewModel.players,
                    properties: viewModel.properties,
                    onSelectPlayer: { p in
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            selectedPlayerId = p.id
                        }
                    },
                    onOpenCardActions: {
                        activePlayerForTransaction = activePlayer
                    }
                )
                
                // 5 Moedas de Ação Amarelas com Contorno Preto
                fiveActionCoinsRow
                
                // Dados Virtuais (se ativados)
                if viewModel.isDiceEnabled {
                    DiceRollerView(viewModel: viewModel)
                        .padding(.horizontal, 4)
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.96).combined(with: .opacity).combined(with: .move(edge: .top)),
                            removal: .scale(scale: 0.96).combined(with: .opacity)
                        ))
                }
                
                // Extrato em Tempo Real Embutido (Abaixo dos dados)
                InlineStatementCardView(
                    viewModel: viewModel,
                    onOpenFullCharts: {
                        showTransactionHistory = true
                    }
                )
                
                // Classificação e Saldos de Toda a Mesa
                tableLeaderboardSection
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)
            .padding(.bottom, 70)
        }
    }
    
    // MARK: - Subviews de Componentes
    
    /// Top Bar com status, cronômetro de partida, botão Desfazer, Dados, Extrato, Som, Configurações e Pausar
    private var topNavBar: some View {
        HStack(alignment: .center, spacing: isPadLayout ? 8 : 6) {
            VStack(alignment: .leading, spacing: 1) {
                Text("BANCO DIGITAL")
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.85))
                    .tracking(1)
                
                HStack(spacing: 5) {
                    Circle()
                        .fill(AppTheme.actionGreen)
                        .frame(width: 7, height: 7)
                        .overlay(
                            Circle().stroke(AppTheme.strokeBlack, lineWidth: 1)
                        )
                    
                    Text("\(viewModel.activePlayers.count) amigos")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundStyle(Color.white)
                }
            }
            
            Spacer(minLength: 4)
            
            // Pílula do Cronômetro ao Vivo
            HStack(spacing: 4) {
                Image(systemName: "stopwatch.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(AppTheme.strokeBlack)
                
                Text(viewModel.formattedElapsedTime)
                    .font(.system(size: 11.5, weight: .black, design: .monospaced))
                    .foregroundStyle(AppTheme.strokeBlack)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(Color.white)
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(AppTheme.strokeBlack, lineWidth: 1.5)
            )
            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
            
            // Botão Desfazer (Undo)
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    viewModel.undoLastTransaction()
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.system(size: 11, weight: .black))
                    if isPadLayout {
                        Text("Desfazer")
                            .font(.caption.weight(.black))
                    }
                }
                .foregroundStyle(viewModel.canUndo ? AppTheme.strokeBlack : Color.black.opacity(0.3))
                .padding(.horizontal, 9)
                .padding(.vertical, 6)
                .background(viewModel.canUndo ? AppTheme.actionYellow : Color.white.opacity(0.6))
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(AppTheme.strokeBlack, lineWidth: 1.5)
                )
            }
            .disabled(!viewModel.canUndo)
            .keyboardShortcut("z", modifiers: .command)
            
            // Botão Mesa P2P / QR Code (iPad e iPhone)
            Button {
                showMultiplayerHostModal = true
                SoundManager.play(.buttonTap)
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "qrcode.viewfinder")
                        .font(.system(size: 11, weight: .black))
                    if isPadLayout {
                        Text("PIN: \(multipeerService.currentSessionId)")
                            .font(.system(size: 11, weight: .black, design: .monospaced))
                        if !multipeerService.connectedDevices.isEmpty {
                            Text("(\(multipeerService.connectedDevices.count) 📱)")
                                .font(.caption2.weight(.heavy))
                        }
                    } else {
                        Text(multipeerService.currentSessionId)
                            .font(.system(size: 10, weight: .black, design: .monospaced))
                    }
                }
                .foregroundStyle(AppTheme.strokeBlack)
                .padding(.horizontal, isPadLayout ? 10 : 8)
                .padding(.vertical, 6)
                .background(multipeerService.connectedDevices.isEmpty ? AppTheme.actionYellow : AppTheme.actionGreen)
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(AppTheme.strokeBlack, lineWidth: 1.5)
                )
            }
            
            // Controles Exclusivos de Mesa Ampla (iPad)
            if isPadLayout {
                // Botão Dados Virtuais
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        viewModel.isDiceEnabled.toggle()
                        if viewModel.isDiceEnabled {
                            viewModel.rollDice()
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "die.face.5.fill")
                            .font(.system(size: 12, weight: .black))
                        Text("Dados")
                            .font(.caption.weight(.black))
                    }
                    .foregroundStyle(AppTheme.strokeBlack)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .background(viewModel.isDiceEnabled ? AppTheme.actionYellow : Color.white)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(AppTheme.strokeBlack, lineWidth: 1.5)
                    )
                }
                
                // Botão Imóveis & Títulos
                Button {
                    showPropertiesSheet = true
                    SoundManager.play(.buttonTap)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "building.2.fill")
                            .font(.system(size: 11, weight: .black))
                        Text("Imóveis")
                            .font(.caption.weight(.black))
                    }
                    .foregroundStyle(AppTheme.strokeBlack)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .background(AppTheme.actionBlue.opacity(0.2))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(AppTheme.strokeBlack, lineWidth: 1.5)
                    )
                }
                
                // Botão Gráficos & Extrato
                Button {
                    showTransactionHistory = true
                    SoundManager.play(.buttonTap)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 11, weight: .black))
                        Text("Extrato")
                            .font(.caption.weight(.black))
                    }
                    .foregroundStyle(AppTheme.strokeBlack)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .background(AppTheme.actionPurple.opacity(0.2))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(AppTheme.strokeBlack, lineWidth: 1.5)
                    )
                }
                
                // Botão de Áudio (Mudo / Som)
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        viewModel.isSoundEnabled.toggle()
                        if viewModel.isSoundEnabled {
                            SoundManager.play(.buttonTap)
                        }
                    }
                } label: {
                    Image(systemName: viewModel.isSoundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(AppTheme.strokeBlack)
                        .frame(width: 30, height: 30)
                        .background(Color.white)
                        .clipShape(Circle())
                        .overlay(
                            Circle().stroke(AppTheme.strokeBlack, lineWidth: 1.5)
                        )
                }
                
                // Botão de Opções / Configurações da Mesa
                Button {
                    showSettingsSheet = true
                    SoundManager.play(.buttonTap)
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(AppTheme.strokeBlack)
                        .frame(width: 30, height: 30)
                        .background(Color.white)
                        .clipShape(Circle())
                        .overlay(
                            Circle().stroke(AppTheme.strokeBlack, lineWidth: 1.5)
                        )
                }
            }
            
            // Botão "Pausar & Salvar" (iPad e iPhone)
            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                    viewModel.pauseGame()
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "pause.fill")
                        .font(.system(size: 9, weight: .black))
                    Text("Pausar")
                        .font(.system(size: 11.5, weight: .black, design: .rounded))
                }
                .foregroundStyle(AppTheme.strokeBlack)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.white)
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(AppTheme.strokeBlack, lineWidth: 1.5)
                )
                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
            }
        }
        .padding(.top, 2)
    }
    
    /// 5 Moedas 3D Táteis com Cores Dedicadas (🟢 Salário, 🔴 Pagar, 🏢 Imóveis, 🟡 Dados, 🟣 Extrato)
    private var fiveActionCoinsRow: some View {
        HStack(spacing: isPadLayout ? 12 : 8) {
            // 1. 🟢 Salário +2.000 ao passar pelo Início
            GameActionCoinButton(
                icon: "plus.circle.fill",
                label: "+2.000",
                theme: .green
            ) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                    viewModel.receiveSalary(for: activePlayer.id)
                }
            }
            
            // 2. 🔴 Pagar / Transferir para Amigo ou Banco
            GameActionCoinButton(
                icon: "dollarsign.arrow.circlepath",
                label: "Pagar",
                theme: .coral
            ) {
                activePlayerForTransaction = activePlayer
            }
            
            // 3. 🏢 Imóveis & Títulos de Propriedade
            GameActionCoinButton(
                icon: "building.2.fill",
                label: "Imóveis",
                theme: .blue
            ) {
                showPropertiesSheet = true
            }
            
            // 4. 🟡 Dados Virtuais (Lança ou Ativa)
            GameActionCoinButton(
                icon: "die.face.5.fill",
                label: "Dados",
                theme: .yellow
            ) {
                if !viewModel.isDiceEnabled {
                    viewModel.isDiceEnabled = true
                }
                viewModel.rollDice()
            }
            
            // 5. 🟣 Extrato & Gráficos
            GameActionCoinButton(
                icon: "chart.line.uptrend.xyaxis",
                label: "Extrato",
                theme: .purple
            ) {
                showTransactionHistory = true
            }
        }
        .padding(.horizontal, 2)
    }
    
    /// Lista de Todos os Jogadores na Mesa (iPhone)
    private var tableLeaderboardSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Mesa de Amigos (Saldos)")
                    .font(.headline.weight(.heavy))
                    .foregroundStyle(Color.white)
                
                Spacer()
                
                Text("Total: \(viewModel.totalMoneyInCirculation.asCurrency)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.white.opacity(0.85))
            }
            
            LazyVStack(spacing: 10) {
                ForEach(Array(rankedPlayers.enumerated()), id: \.element.id) { index, player in
                    let isSelected = activePlayer.id == player.id
                    PlayerDashboardCard(
                        player: player,
                        properties: viewModel.properties,
                        rank: index + 1,
                        isSelected: isSelected,
                        onSelect: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                selectedPlayerId = player.id
                                activePlayerForTransaction = player
                                HapticManager.impact(.light)
                            }
                        },
                        onQuickAddSalary: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                viewModel.receiveSalary(for: player.id)
                            }
                        },
                        onOpenActions: {
                            activePlayerForTransaction = player
                        },
                        onToggleBankruptcy: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                viewModel.toggleBankruptcy(for: player.id)
                            }
                        }
                    )
                }
            }
        }
    }
    
    /// Dock Flutuante na base da tela (iPhone)
    private var floatingBottomDock: some View {
        HStack(spacing: 12) {
            // Imóveis & Títulos 3D
            Tactile3DButton(
                faceGradient: LinearGradient(colors: [Color.white, Color(white: 0.93)], startPoint: .top, endPoint: .bottom),
                depthColor: AppTheme.actionWhiteDark,
                cornerRadius: 20,
                depth: 4.0,
                strokeWidth: 1.8,
                highlightColor: Color.white.opacity(0.8),
                action: {
                    showPropertiesSheet = true
                }
            ) {
                Image(systemName: "building.2.fill")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(AppTheme.actionBlue)
                    .frame(width: 36, height: 32)
            }
            
            // Extrato e Gráficos 3D
            Tactile3DButton(
                faceGradient: LinearGradient(colors: [Color.white, Color(white: 0.93)], startPoint: .top, endPoint: .bottom),
                depthColor: AppTheme.actionWhiteDark,
                cornerRadius: 20,
                depth: 4.0,
                strokeWidth: 1.8,
                highlightColor: Color.white.opacity(0.8),
                action: {
                    showTransactionHistory = true
                }
            ) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(AppTheme.actionPurple)
                    .frame(width: 36, height: 32)
            }
            
            // Botão Desfazer Rápido 3D
            Tactile3DButton(
                faceGradient: viewModel.canUndo ? AppTheme.actionYellowGradient : LinearGradient(colors: [Color(white: 0.95), Color(white: 0.88)], startPoint: .top, endPoint: .bottom),
                depthColor: viewModel.canUndo ? AppTheme.actionYellowDark : AppTheme.actionWhiteDark,
                cornerRadius: 20,
                depth: 4.0,
                strokeWidth: 1.8,
                highlightColor: Color.white.opacity(0.7),
                action: {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        viewModel.undoLastTransaction()
                    }
                }
            ) {
                Image(systemName: "arrow.uturn.backward")
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(viewModel.canUndo ? AppTheme.strokeBlack : Color.black.opacity(0.3))
                    .frame(width: 36, height: 32)
            }
            .disabled(!viewModel.canUndo)
            
            // Botão Central: Pagar Rápido 3D
            Tactile3DButton(
                faceGradient: AppTheme.actionCoralGradient,
                depthColor: AppTheme.actionCoralDark,
                cornerRadius: 24,
                depth: 5.0,
                strokeWidth: 2.0,
                highlightColor: Color.white.opacity(0.4),
                action: {
                    activePlayerForTransaction = activePlayer
                }
            ) {
                HStack(spacing: 5) {
                    Image(systemName: "dollarsign.arrow.circlepath")
                        .font(.system(size: 15, weight: .black))
                    Text("Pagar")
                        .font(.system(size: 13.5, weight: .black, design: .rounded))
                }
                .foregroundStyle(Color.white)
                .padding(.horizontal, 14)
                .frame(height: 36)
            }
            
            // Opções / Configurações 3D
            Tactile3DButton(
                faceGradient: LinearGradient(colors: [Color.white, Color(white: 0.93)], startPoint: .top, endPoint: .bottom),
                depthColor: AppTheme.actionWhiteDark,
                cornerRadius: 20,
                depth: 4.0,
                strokeWidth: 1.8,
                highlightColor: Color.white.opacity(0.8),
                action: {
                    showSettingsSheet = true
                }
            ) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(AppTheme.strokeBlack)
                    .frame(width: 36, height: 32)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.95))
        .clipShape(Capsule())
        .overlay(
            Capsule().stroke(AppTheme.strokeBlack, lineWidth: 2)
        )
        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
        .padding(.bottom, 8)
    }
    
    // MARK: - Sheet de Configurações da Mesa
    
    private var tableSettingsSheet: some View {
        NavigationStack {
            ZStack {
                AppTheme.canvasBackground.opacity(0.1)
                    .ignoresSafeArea()
                
                List {
                    Section("Estatísticas da Partida") {
                        HStack {
                            Label("Tempo de Partida", systemImage: "stopwatch.fill")
                            Spacer()
                            Text(viewModel.formattedElapsedTime)
                                .font(.headline.weight(.heavy))
                                .foregroundStyle(AppTheme.gameYellow)
                        }
                        
                        HStack {
                            Label("Total em Circulação", systemImage: "banknote.fill")
                            Spacer()
                            Text(viewModel.totalMoneyInCirculation.asCurrency)
                                .font(.subheadline.weight(.bold))
                        }
                    }
                    
                    Section("Recursos de Jogo no iPad") {
                        Toggle(isOn: $viewModel.isDiceEnabled) {
                            Label("Dados Virtuais (Dice Roller)", systemImage: "die.face.5.fill")
                        }
                        
                        Toggle(isOn: $viewModel.isSoundEnabled) {
                            Label("Efeitos Sonoros (Audio FX)", systemImage: "speaker.wave.2.fill")
                        }
                        
                        Toggle(isOn: $viewModel.isKeepScreenAwakeEnabled) {
                            Label("Manter Tela Sempre Ativa", systemImage: "sun.max.fill")
                        }
                    }
                    
                    Section("Ações da Partida") {
                        if viewModel.canUndo {
                            Button {
                                showSettingsSheet = false
                                viewModel.undoLastTransaction()
                            } label: {
                                Label("Desfazer Última Movimentação (⌘Z)", systemImage: "arrow.uturn.backward")
                                    .foregroundStyle(AppTheme.textPrimary)
                            }
                        }
                        
                        Button(role: .destructive) {
                            showSettingsSheet = false
                            viewModel.showResetConfirmation = true
                        } label: {
                            Label("Encerrar e Apagar Partida", systemImage: "trash.fill")
                        }
                    }
                }
            }
            .navigationTitle("Configurações da Mesa")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fechar") {
                        showSettingsSheet = false
                    }
                    .font(.headline.weight(.bold))
                    .foregroundStyle(AppTheme.textPrimary)
                }
            }
        }
        .presentationDetents([.medium])
    }
    
    // MARK: - Toast Flutuante de Ação Remota Neo-Brutalist
    
    private func remoteActionNotificationView(_ notif: ActionNotification) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(notificationColor(notif.colorName))
                    .frame(width: 38, height: 38)
                    .overlay(Circle().stroke(AppTheme.strokeBlack, lineWidth: 1.8))
                Image(systemName: notif.icon)
                    .font(.system(size: 16, weight: .black))
                    .foregroundStyle(AppTheme.strokeBlack)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(notif.title)
                    .font(.system(size: 13.5, weight: .heavy, design: .rounded))
                    .foregroundStyle(AppTheme.strokeBlack)
                Text(notif.subtitle)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(2)
            }
            
            Spacer(minLength: 4)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(maxWidth: 420)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AppTheme.strokeBlack, lineWidth: 2.2)
        )
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppTheme.strokeBlack)
                .offset(x: 3, y: 4.5)
        )
        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
    }
    
    private func notificationColor(_ name: String) -> Color {
        switch name {
        case "green": return AppTheme.actionGreen
        case "coral": return AppTheme.gameCoral
        case "yellow": return AppTheme.actionYellow
        case "blue": return AppTheme.actionBlue
        case "purple": return AppTheme.actionPurple
        default: return AppTheme.actionYellow
        }
    }
}

#Preview {
    let vm = GameViewModel()
    vm.players = [
        Player(name: "Kauã Vinícius", balance: 3200, color: .blue),
        Player(name: "Mariana Souza", balance: 2100, color: .purple),
        Player(name: "Lucas Lima", balance: 950, color: .orange)
    ]
    vm.isGameActive = true
    return GameDashboardView(viewModel: vm)
}

