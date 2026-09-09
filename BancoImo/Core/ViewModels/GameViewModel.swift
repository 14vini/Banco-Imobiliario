//
//  GameViewModel.swift
//  BancoImo
//
//  Created by iOS Senior Developer.
//

import SwiftUI
import Observation
import MultipeerConnectivity

/// ViewModel central responsável por gerenciar o estado da partida, histórico de transações, regras, dados, cronômetro e persistência.
@Observable
@MainActor
final class GameViewModel {
    // MARK: - Estado da Partida
    
    var players: [Player] = []
    var properties: [Property] = Property.defaultProperties()
    var transactions: [Transaction] = []
    var initialBalance: Decimal = 1500
    var isGameActive: Bool = false {
        didSet {
            updateScreenAwakeState()
            if isGameActive {
                startTimer()
            } else {
                stopTimer()
            }
        }
    }
    var errorMessage: String? = nil
    var showResetConfirmation: Bool = false
    
    // MARK: - Cronômetro da Partida (Game Timer)
    
    var elapsedTime: TimeInterval = 0
    private var timerTask: Task<Void, Never>? = nil
    
    // MARK: - Configurações e Acessibilidade (iPad UX)
    
    var isSoundEnabled: Bool = true {
        didSet {
            SoundManager.isMuted = !isSoundEnabled
            saveToUserDefaults()
        }
    }
    
    var isDiceEnabled: Bool = true {
        didSet {
            saveToUserDefaults()
        }
    }
    
    var isDiceExpanded: Bool = true
    
    var isKeepScreenAwakeEnabled: Bool = true {
        didSet {
            updateScreenAwakeState()
            saveToUserDefaults()
        }
    }
    
    // MARK: - Estado do Sistema de Desfazer (Undo)
    
    var undoToastMessage: String? = nil
    var lastUndoneTransaction: Transaction? = nil
    
    // MARK: - Estado dos Dados Virtuais (Dice Roller)
    
    var dice1: Int = 3
    var dice2: Int = 4
    var isRollingDice: Bool = false
    var consecutiveDoublesCount: Int = 0
    var diceBannerMessage: String? = nil
    
    // MARK: - Peão do Anfitrião (iPad / Mesa Central)
    
    var hostPlayerId: UUID? = nil
    
    // MARK: - Notificações Flutuantes de Ações Remotas (Toasts em tempo real no iPad)
    
    var remoteActionNotification: ActionNotification? = nil
    private var notificationDismissTask: Task<Void, Never>? = nil
    
    // MARK: - Limites
    
    let minPlayers: Int = 2
    let maxPlayers: Int = 8
    
    // MARK: - Dependências
    
    private let storageService: GameStorageServiceProtocol
    
    // MARK: - Inicialização
    
    init(storageService: GameStorageServiceProtocol = UserDefaultsGameStorageService()) {
        self.storageService = storageService
        loadFromUserDefaults()
        SoundManager.isMuted = !isSoundEnabled
        updateScreenAwakeState()
        setupMultipeerHandler()
        if isGameActive {
            startTimer()
        }
        
        // Inicia a transmissão da sala imediatamente para permitir emparelhamento durante o setup
        if MultipeerGameService.shared.role == .idle {
            MultipeerGameService.shared.startHosting(gameId: UUID())
        }
    }
    
    // MARK: - Propriedades Computadas
    
    /// Tempo de jogo formatado em "00:45:12" ou "23:45".
    var formattedElapsedTime: String {
        let totalSeconds = Int(elapsedTime)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    /// Indica se existe uma partida previamente salva com jogadores cadastrados.
    var hasSavedGame: Bool {
        !players.isEmpty
    }
    
    /// Indica se há alguma transação que pode ser desfeita.
    var canUndo: Bool {
        !transactions.isEmpty
    }
    
    /// Última transação realizada na mesa.
    var lastTransaction: Transaction? {
        transactions.first
    }
    
    /// Lista de cores que ainda não foram escolhidas por nenhum jogador cadastrado.
    var availableColors: [PlayerColor] {
        let usedColors = Set(players.map { $0.color })
        let available = PlayerColor.allCases.filter { !usedColors.contains($0) }
        return available.isEmpty ? PlayerColor.allCases : available
    }
    
    /// Próxima cor recomendada para o novo jogador a ser cadastrado.
    var nextSuggestedColor: PlayerColor {
        availableColors.first ?? .blue
    }
    
    /// Indica se a quantidade mínima de jogadores para iniciar a partida foi atingida.
    var canStartGame: Bool {
        players.count >= minPlayers
    }
    
    /// Total de dinheiro em circulação na partida.
    var totalMoneyInCirculation: Decimal {
        players.reduce(Decimal.zero) { $0 + $1.balance }
    }
    
    /// Média de saldo por jogador.
    var averageBalancePerPlayer: Decimal {
        guard !players.isEmpty else { return 0 }
        return totalMoneyInCirculation / Decimal(players.count)
    }
    
    /// Maior transação única registrada na partida.
    var highestSingleTransaction: Transaction? {
        transactions.filter { $0.type != .initialBalance && $0.type != .bankruptcy }
            .max(by: { $0.amount < $1.amount })
    }
    
    /// Jogadores ativos que não faliram.
    var activePlayers: [Player] {
        players.filter { !$0.isBankrupt }
    }
    
    /// Jogador mais rico em saldo líquido no momento.
    var richestPlayer: Player? {
        activePlayers.max(by: { $0.balance < $1.balance })
    }
    
    /// Jogador mais rico considerando Patrimônio Líquido Total (Dinheiro + Imóveis + Casas).
    var richestPlayerByNetWorth: Player? {
        activePlayers.max(by: { calculateNetWorth(for: $0) < calculateNetWorth(for: $1) })
    }
    
    /// Total de propriedades compradas por jogadores.
    var totalPropertiesOwnedCount: Int {
        properties.filter { $0.isOwned }.count
    }
    
    /// Total de casas construídas na mesa (excluindo hotéis).
    var totalHousesBuilt: Int {
        properties.reduce(0) { $0 + ($1.housesCount > 0 && $1.housesCount <= 4 ? $1.housesCount : 0) }
    }
    
    /// Total de hotéis construídos na mesa.
    var totalHotelsBuilt: Int {
        properties.reduce(0) { $0 + ($1.housesCount == 5 ? 1 : 0) }
    }
    
    /// Imóveis que ainda estão disponíveis no Banco para compra.
    var unownedProperties: [Property] {
        properties.filter { !$0.isOwned }
    }
    
    /// Retorna todos os imóveis pertencentes a um jogador específico.
    func properties(for playerId: UUID) -> [Property] {
        properties.filter { $0.ownerId == playerId }
    }
    
    /// Verifica se o jogador possui todas as propriedades de um determinado grupo de bairro (Monopólio).
    func hasMonopoly(for group: PropertyGroupType, playerId: UUID) -> Bool {
        guard group != .company else { return false }
        let groupProps = properties.filter { $0.group == group }
        guard !groupProps.isEmpty else { return false }
        return groupProps.allSatisfy { $0.ownerId == playerId }
    }
    
    /// Retorna a quantidade de companhias de serviços públicos pertencentes a um jogador.
    func ownedCompaniesCount(for playerId: UUID) -> Int {
        properties.filter { $0.group == .company && $0.ownerId == playerId }.count
    }
    
    /// Calcula o Patrimônio Líquido Total de um jogador (Saldo + Imóveis + Construções).
    func calculateNetWorth(for player: Player) -> Decimal {
        let playerProps = properties.filter { $0.ownerId == player.id }
        let propertiesValuation = playerProps.reduce(Decimal.zero) { $0 + $1.totalValuation }
        return player.balance + propertiesValuation
    }
    
    // MARK: - Gerenciamento de Cronômetro
    
    func startTimer() {
        stopTimer()
        guard isGameActive else { return }
        
        timerTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard let self = self, self.isGameActive else { break }
                self.elapsedTime += 1
                
                // Salva automaticamente no disco a cada 60s
                if Int(self.elapsedTime) % 60 == 0 {
                    self.saveToUserDefaults()
                }
            }
        }
    }
    
    func stopTimer() {
        timerTask?.cancel()
        timerTask = nil
    }
    
    // MARK: - Cálculo Histórico para Swift Charts (Linha de Patrimônio)
    
    /// Reconstrói a linha do tempo do patrimônio de cada jogador desde o início da partida.
    func calculateBalanceHistory() -> [BalanceHistoryPoint] {
        guard !players.isEmpty else { return [] }
        
        var points: [BalanceHistoryPoint] = []
        
        // Saldos iniciais no Step 0 ("Início")
        var runningBalances: [UUID: Decimal] = [:]
        for player in players {
            runningBalances[player.id] = initialBalance
            points.append(
                BalanceHistoryPoint(
                    stepIndex: 0,
                    stepLabel: "Início",
                    timestamp: Date().addingTimeInterval(-elapsedTime),
                    playerId: player.id,
                    playerName: player.name,
                    playerColor: player.color,
                    balance: NSDecimalNumber(decimal: initialBalance).doubleValue
                )
            )
        }
        
        // Replay cronológico (do mais antigo para o mais recente)
        let chronTransactions = transactions.reversed()
        var stepCounter = 1
        
        for tx in chronTransactions {
            // Ignora setup inicial repetido
            if tx.type == .initialBalance { continue }
            
            // Aplica mutação
            switch tx.type {
            case .salary, .bankDeposit, .propertyMortgage, .houseSell:
                if let recId = tx.receiverId {
                    runningBalances[recId, default: 0] += tx.amount
                }
            case .bankPayment, .houseBuild, .propertyUnmortgage:
                if let sendId = tx.senderId {
                    runningBalances[sendId, default: 0] -= tx.amount
                }
            case .propertyPurchase:
                if let recId = tx.receiverId {
                    runningBalances[recId, default: 0] -= tx.amount
                }
            case .transfer, .rentPayment:
                if let sendId = tx.senderId {
                    runningBalances[sendId, default: 0] -= tx.amount
                }
                if let recId = tx.receiverId {
                    runningBalances[recId, default: 0] += tx.amount
                }
            case .propertySale:
                if let sendId = tx.senderId {
                    runningBalances[sendId, default: 0] += tx.amount
                }
                if let recId = tx.receiverId {
                    runningBalances[recId, default: 0] -= tx.amount
                }
            case .bankruptcy, .initialBalance:
                break
            }
            
            // Registra os pontos de todos os jogadores neste momento
            for player in players {
                let currentBal = runningBalances[player.id] ?? initialBalance
                points.append(
                    BalanceHistoryPoint(
                        stepIndex: stepCounter,
                        stepLabel: "T\(stepCounter)",
                        timestamp: tx.timestamp,
                        playerId: player.id,
                        playerName: player.name,
                        playerColor: player.color,
                        balance: NSDecimalNumber(decimal: currentBal).doubleValue
                    )
                )
            }
            stepCounter += 1
        }
        
        return points
    }
    
    // MARK: - Gerenciamento de Tela Sempre Ativa (Keep Screen Awake)
    
    func updateScreenAwakeState() {
        let shouldKeepAwake = isGameActive && isKeepScreenAwakeEnabled
        UIApplication.shared.isIdleTimerDisabled = shouldKeepAwake
    }
    
    // MARK: - Ações de Controle da Sessão e Persistência
    
    /// Pausa a partida atual e volta ao menu principal MANTENDO TODOS OS DADOS SALVOS no disco (incluindo o tempo de jogo).
    func pauseGame() {
        isGameActive = false
        stopTimer()
        saveToUserDefaults()
        HapticManager.impact(.light)
        SoundManager.play(.buttonTap)
    }
    
    /// Retoma a partida salva de onde os amigos pararam, preservando o tempo decorrido.
    func resumeGame() {
        guard canStartGame else { return }
        isGameActive = true
        startTimer()
        saveToUserDefaults()
        HapticManager.notification(.success)
        SoundManager.play(.salary)
    }
    
    /// Inicia ou continua uma partida validando a quantidade mínima de participantes.
    /// Preserva o cronômetro caso seja a continuação de uma partida em andamento.
    func startGame() {
        guard canStartGame else {
            errorMessage = "É necessário adicionar pelo menos \(minPlayers) jogadores para iniciar."
            HapticManager.notification(.warning)
            SoundManager.play(.bankruptcy)
            return
        }
        
        isGameActive = true
        errorMessage = nil
        
        // Se for uma partida totalmente nova sem transações registradas, zera o cronômetro
        if transactions.isEmpty {
            elapsedTime = 0
            for player in players {
                logTransaction(
                    type: .initialBalance,
                    amount: initialBalance,
                    receiverId: player.id,
                    receiverName: player.name,
                    receiverColor: player.color,
                    title: "Saldo Inicial",
                    subtitle: "\(player.name) iniciou com \(initialBalance.asCurrency)"
                )
            }
        }
        
        startTimer()
        saveToUserDefaults()
        HapticManager.notification(.success)
        SoundManager.play(.salary)
    }
    
    /// Chamado quando o app entra em segundo plano para garantir persistência do cronômetro
    func handleAppBackgrounded() {
        saveToUserDefaults()
    }
    
    /// Chamado quando o app volta para primeiro plano
    func handleAppForegrounded() {
        if isGameActive && timerTask == nil {
            startTimer()
        }
    }
    
    /// Encerra e apaga definitivamente a partida salva (usado apenas se o usuário quiser recomeçar do zero).
    func resetGame() {
        stopTimer()
        players = []
        properties = Property.defaultProperties()
        transactions = []
        initialBalance = 1500
        isGameActive = false
        elapsedTime = 0
        errorMessage = nil
        showResetConfirmation = false
        consecutiveDoublesCount = 0
        diceBannerMessage = nil
        undoToastMessage = nil
        HapticManager.notification(.warning)
        SoundManager.play(.bankruptcy)
        storageService.clear()
        updateScreenAwakeState()
    }
    
    // MARK: - Sistema de Desfazer (Undo Last Transaction)
    
    /// Desfaz a última transação realizada, restaurando os saldos e o estado anterior.
    func undoLastTransaction() {
        guard let lastTx = transactions.first else { return }
        
        // 1. Reversão dos saldos e propriedades com base no tipo
        switch lastTx.type {
        case .salary, .bankDeposit:
            if let recId = lastTx.receiverId, let idx = players.firstIndex(where: { $0.id == recId }) {
                players[idx].balance -= lastTx.amount
            }
            
        case .bankPayment:
            if let sendId = lastTx.senderId, let idx = players.firstIndex(where: { $0.id == sendId }) {
                players[idx].balance += lastTx.amount
            }
            
        case .transfer, .rentPayment:
            if let sendId = lastTx.senderId, let sendIdx = players.firstIndex(where: { $0.id == sendId }) {
                players[sendIdx].balance += lastTx.amount
            }
            if let recId = lastTx.receiverId, let recIdx = players.firstIndex(where: { $0.id == recId }) {
                players[recIdx].balance -= lastTx.amount
            }
            
        case .bankruptcy:
            if let sendId = lastTx.senderId, let idx = players.firstIndex(where: { $0.id == sendId }) {
                players[idx].isBankrupt.toggle()
            }
            
        case .propertyPurchase:
            if let recId = lastTx.receiverId, let playerIdx = players.firstIndex(where: { $0.id == recId }) {
                players[playerIdx].balance += lastTx.amount
            }
            if let propId = lastTx.propertyId, let propIdx = properties.firstIndex(where: { $0.id == propId }) {
                properties[propIdx].ownerId = nil
                properties[propIdx].housesCount = 0
                properties[propIdx].isMortgaged = false
            }
            
        case .propertySale:
            if let sendId = lastTx.senderId, let sendIdx = players.firstIndex(where: { $0.id == sendId }) {
                players[sendIdx].balance += lastTx.amount
            }
            if let recId = lastTx.receiverId, let recIdx = players.firstIndex(where: { $0.id == recId }) {
                players[recIdx].balance -= lastTx.amount
            }
            if let propId = lastTx.propertyId, let propIdx = properties.firstIndex(where: { $0.id == propId }) {
                properties[propIdx].ownerId = lastTx.previousOwnerId
            }
            
        case .houseBuild:
            if let sendId = lastTx.senderId, let idx = players.firstIndex(where: { $0.id == sendId }) {
                players[idx].balance += lastTx.amount
            }
            if let propId = lastTx.propertyId, let propIdx = properties.firstIndex(where: { $0.id == propId }) {
                properties[propIdx].housesCount = lastTx.previousHousesCount ?? max(0, properties[propIdx].housesCount - 1)
            }
            
        case .houseSell:
            if let recId = lastTx.receiverId, let idx = players.firstIndex(where: { $0.id == recId }) {
                players[idx].balance -= lastTx.amount
            }
            if let propId = lastTx.propertyId, let propIdx = properties.firstIndex(where: { $0.id == propId }) {
                properties[propIdx].housesCount = lastTx.previousHousesCount ?? min(5, properties[propIdx].housesCount + 1)
            }
            
        case .propertyMortgage:
            if let recId = lastTx.receiverId, let idx = players.firstIndex(where: { $0.id == recId }) {
                players[idx].balance -= lastTx.amount
            }
            if let propId = lastTx.propertyId, let propIdx = properties.firstIndex(where: { $0.id == propId }) {
                properties[propIdx].isMortgaged = false
            }
            
        case .propertyUnmortgage:
            if let sendId = lastTx.senderId, let idx = players.firstIndex(where: { $0.id == sendId }) {
                players[idx].balance += lastTx.amount
            }
            if let propId = lastTx.propertyId, let propIdx = properties.firstIndex(where: { $0.id == propId }) {
                properties[propIdx].isMortgaged = true
            }
            
        case .initialBalance:
            break
        }
        
        // 2. Remove o registro do topo do histórico
        let removedTx = transactions.removeFirst()
        lastUndoneTransaction = removedTx
        
        // 3. Feedback Sonoro, Tátil e Visual (Toast)
        SoundManager.play(.undo)
        HapticManager.notification(.warning)
        
        let amountStr = removedTx.amount > 0 ? " (\(removedTx.amount.asCurrency))" : ""
        showUndoToast(message: "Desfeito: \(removedTx.title)\(amountStr)")
        
        saveToUserDefaults()
    }
    
    private func showUndoToast(message: String) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            undoToastMessage = message
        }
        
        // Auto-dismiss após 3.5 segundos
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) { [weak self] in
            guard let self = self else { return }
            if self.undoToastMessage == message {
                withAnimation(.easeOut(duration: 0.25)) {
                    self.undoToastMessage = nil
                }
            }
        }
    }
    
    // MARK: - Dados Virtuais (Dice Roller)
    
    /// Rola os 2 dados com animação física realista, detecção de duplos e som de rolagem.
    func rollDice() {
        guard !isRollingDice else { return }
        
        isRollingDice = true
        SoundManager.play(.diceRoll)
        HapticManager.impact(.medium)
        
        Task { @MainActor in
            // Sequência de rolagem com desaceleração física (rápido -> médio -> desaceleração -> pouso)
            let stepDelays: [UInt64] = [
                45_000_000,
                50_000_000,
                60_000_000,
                75_000_000,
                95_000_000,
                125_000_000,
                160_000_000,
                200_000_000
            ]
            
            for (idx, delay) in stepDelays.enumerated() {
                try? await Task.sleep(nanoseconds: delay)
                guard self.isRollingDice else { return }
                
                self.dice1 = Int.random(in: 1...6)
                self.dice2 = Int.random(in: 1...6)
                
                if idx % 2 == 0 {
                    HapticManager.impact(.light)
                }
            }
            
            self.finishDiceRoll()
        }
    }
    
    private func finishDiceRoll() {
        isRollingDice = false
        let total = dice1 + dice2
        let isDouble = (dice1 == dice2)
        
        if isDouble {
            consecutiveDoublesCount += 1
            
            if consecutiveDoublesCount >= 3 {
                diceBannerMessage = "3º DUPLO CONSECUTIVO! Vá direto para a Prisão!"
                SoundManager.play(.bankruptcy)
                HapticManager.notification(.error)
                consecutiveDoublesCount = 0
            } else {
                diceBannerMessage = "DUPLO \(dice1) (Total: \(total))! Jogue novamente!"
                SoundManager.play(.diceDouble)
                HapticManager.notification(.success)
            }
        } else {
            consecutiveDoublesCount = 0
            diceBannerMessage = "Total tirado: \(total)"
            SoundManager.play(.buttonTap)
            HapticManager.impact(.medium)
        }
        
        broadcastCurrentState()
    }
    
    // MARK: - Ações de Configuração (Setup)
    
    /// Adiciona um novo jogador validando nome, duplicidade, cor e limites.
    @discardableResult
    func addPlayer(name: String, color: PlayerColor? = nil) -> Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedName.isEmpty else {
            errorMessage = "O nome do jogador não pode ficar em branco."
            HapticManager.notification(.error)
            SoundManager.play(.bankruptcy)
            return false
        }
        
        guard players.count < maxPlayers else {
            errorMessage = "O limite máximo de \(maxPlayers) jogadores foi atingido."
            HapticManager.notification(.warning)
            SoundManager.play(.bankruptcy)
            return false
        }
        
        let isDuplicate = players.contains { $0.name.localizedCaseInsensitiveCompare(trimmedName) == .orderedSame }
        guard !isDuplicate else {
            errorMessage = "Já existe um jogador com o nome \"\(trimmedName)\"."
            HapticManager.notification(.warning)
            SoundManager.play(.bankruptcy)
            return false
        }
        
        let chosenColor: PlayerColor
        if let color = color, !players.contains(where: { $0.color == color }) {
            chosenColor = color
        } else {
            chosenColor = nextSuggestedColor
        }
        
        let newPlayer = Player(
            name: trimmedName,
            balance: initialBalance,
            color: chosenColor
        )
        
        players.append(newPlayer)
        if hostPlayerId == nil {
            hostPlayerId = newPlayer.id
            MultipeerGameService.shared.hostPlayerId = newPlayer.id
        }
        
        errorMessage = nil
        HapticManager.notification(.success)
        SoundManager.play(.payment)
        saveToUserDefaults()
        broadcastCurrentState()
        return true
    }
    
    /// Define qual jogador da mesa é o próprio Anfitrião (iPad / Mesa Central)
    func setHostPlayer(id: UUID) {
        self.hostPlayerId = id
        MultipeerGameService.shared.hostPlayerId = id
        SoundManager.play(.buttonTap)
        HapticManager.selection()
        broadcastCurrentState()
    }
    
    /// Remove um jogador da lista no setup.
    func removePlayer(id: UUID) {
        players.removeAll { $0.id == id }
        if hostPlayerId == id {
            hostPlayerId = players.first?.id
            MultipeerGameService.shared.hostPlayerId = hostPlayerId
        }
        errorMessage = nil
        HapticManager.impact(.light)
        SoundManager.play(.buttonTap)
        saveToUserDefaults()
        broadcastCurrentState()
    }
    
    /// Atualiza o saldo inicial padrão e sincroniza para os jogadores.
    func updateInitialBalance(_ newBalance: Decimal) {
        guard !isGameActive else { return }
        initialBalance = max(100, newBalance)
        for index in players.indices {
            players[index].balance = initialBalance
        }
        HapticManager.selection()
        SoundManager.play(.keypadTap)
        saveToUserDefaults()
    }
    
    // MARK: - Ações Durante o Jogo
    
    /// Concede o salário da rodada ao passar pelo Ponto de Partida (+2.000).
    func receiveSalary(for playerId: UUID, amount: Decimal = 2000) {
        guard let index = players.firstIndex(where: { $0.id == playerId }) else { return }
        let player = players[index]
        players[index].balance += amount
        
        logTransaction(
            type: .salary,
            amount: amount,
            receiverId: player.id,
            receiverName: player.name,
            receiverColor: player.color,
            title: "Passou pelo Início (+\(amount.asCurrency))",
            subtitle: "\(player.name) recebeu \(amount.asCurrency) do Banco"
        )
        
        HapticManager.impact(.medium)
        SoundManager.play(.moneyIn)
        saveToUserDefaults()
    }
    
    /// Ajusta o saldo de um jogador com o Banco (Depósito ou Pagamento).
    func adjustBalance(for playerId: UUID, delta: Decimal, customReason: String? = nil) {
        guard let index = players.firstIndex(where: { $0.id == playerId }) else { return }
        let player = players[index]
        players[index].balance += delta
        
        let isDeposit = delta > 0
        let absAmount = abs(delta)
        
        logTransaction(
            type: isDeposit ? .bankDeposit : .bankPayment,
            amount: absAmount,
            senderId: isDeposit ? nil : player.id,
            senderName: isDeposit ? "Banco" : player.name,
            senderColor: isDeposit ? nil : player.color,
            receiverId: isDeposit ? player.id : nil,
            receiverName: isDeposit ? player.name : "Banco",
            receiverColor: isDeposit ? player.color : nil,
            title: isDeposit ? "Recebido do Banco" : "Pago ao Banco",
            subtitle: customReason ?? (isDeposit ? "\(player.name) recebeu \(absAmount.asCurrency) do Banco" : "\(player.name) pagou \(absAmount.asCurrency) ao Banco")
        )
        
        HapticManager.impact(isDeposit ? .medium : .light)
        SoundManager.play(isDeposit ? .moneyIn : .moneyOut)
        saveToUserDefaults()
    }
    
    /// Alterna o status de falência de um jogador.
    func toggleBankruptcy(for playerId: UUID) {
        guard let index = players.firstIndex(where: { $0.id == playerId }) else { return }
        players[index].isBankrupt.toggle()
        let player = players[index]
        
        logTransaction(
            type: .bankruptcy,
            amount: player.balance,
            senderId: player.id,
            senderName: player.name,
            senderColor: player.color,
            title: player.isBankrupt ? "Falência Declarada" : "Falência Cancelada",
            subtitle: player.isBankrupt ? "\(player.name) foi à falência e saiu do jogo" : "\(player.name) retornou à partida"
        )
        
        HapticManager.notification(player.isBankrupt ? .error : .success)
        SoundManager.play(player.isBankrupt ? .bankruptcy : .moneyIn)
        saveToUserDefaults()
    }
    
    /// Transfere dinheiro entre dois jogadores (ex: Aluguel de propriedade).
    @discardableResult
    func transferMoney(from senderId: UUID, to receiverId: UUID, amount: Decimal) -> Bool {
        guard amount > 0,
              let senderIndex = players.firstIndex(where: { $0.id == senderId }),
              let receiverIndex = players.firstIndex(where: { $0.id == receiverId }),
              senderId != receiverId else {
            HapticManager.notification(.error)
            SoundManager.play(.bankruptcy)
            return false
        }
        
        let sender = players[senderIndex]
        let receiver = players[receiverIndex]
        
        players[senderIndex].balance -= amount
        players[receiverIndex].balance += amount
        
        logTransaction(
            type: .transfer,
            amount: amount,
            senderId: sender.id,
            senderName: sender.name,
            senderColor: sender.color,
            receiverId: receiver.id,
            receiverName: receiver.name,
            receiverColor: receiver.color,
            title: "Aluguel / Pagamento",
            subtitle: "\(sender.name) pagou \(amount.asCurrency) para \(receiver.name)"
        )
        
        HapticManager.notification(.success)
        SoundManager.play(.moneyOut)
        saveToUserDefaults()
        return true
    }
    
    // MARK: - Operações Imobiliárias (Property Management)
    
    /// Compra um imóvel do Banco para um jogador.
    @discardableResult
    func buyProperty(propertyId: UUID, by playerId: UUID) -> Bool {
        guard let propIndex = properties.firstIndex(where: { $0.id == propertyId }),
              let playerIndex = players.firstIndex(where: { $0.id == playerId }) else {
            return false
        }
        
        let property = properties[propIndex]
        let player = players[playerIndex]
        
        guard !property.isOwned else {
            errorMessage = "\(property.name) já pertence a outro jogador."
            HapticManager.notification(.error)
            SoundManager.play(.bankruptcy)
            return false
        }
        
        guard player.balance >= property.price else {
            errorMessage = "\(player.name) não possui saldo suficiente (\(property.price.asCurrency)) para comprar \(property.name)."
            HapticManager.notification(.error)
            SoundManager.play(.bankruptcy)
            return false
        }
        
        players[playerIndex].balance -= property.price
        properties[propIndex].ownerId = player.id
        
        logTransaction(
            type: .propertyPurchase,
            amount: property.price,
            senderId: nil,
            senderName: "Banco",
            senderColor: nil,
            receiverId: player.id,
            receiverName: player.name,
            receiverColor: player.color,
            title: "Compra de Imóvel",
            subtitle: "\(player.name) comprou \(property.name) por \(property.price.asCurrency)",
            propertyId: property.id,
            propertyName: property.name,
            previousOwnerId: nil,
            previousHousesCount: 0,
            newHousesCount: 0
        )
        
        HapticManager.notification(.success)
        SoundManager.play(.moneyOut)
        saveToUserDefaults()
        return true
    }
    
    /// Constrói uma casa (1..4) ou Hotel (5) em um imóvel.
    @discardableResult
    func buildHouse(propertyId: UUID) -> Bool {
        guard let propIndex = properties.firstIndex(where: { $0.id == propertyId }) else { return false }
        let property = properties[propIndex]
        
        guard let ownerId = property.ownerId,
              let playerIndex = players.firstIndex(where: { $0.id == ownerId }) else {
            errorMessage = "O imóvel precisa ter um proprietário para construir."
            return false
        }
        
        guard property.canBuildHouse else {
            errorMessage = "Não é possível construir mais casas neste imóvel."
            HapticManager.notification(.warning)
            return false
        }
        
        let player = players[playerIndex]
        guard player.balance >= property.houseCost else {
            errorMessage = "\(player.name) não possui saldo (\(property.houseCost.asCurrency)) para construir."
            HapticManager.notification(.error)
            SoundManager.play(.bankruptcy)
            return false
        }
        
        let oldHouses = property.housesCount
        let newHouses = oldHouses + 1
        
        players[playerIndex].balance -= property.houseCost
        properties[propIndex].housesCount = newHouses
        
        let isHotel = newHouses == 5
        let title = isHotel ? "Construção de Hotel 🏨" : "Construção de Casa 🏠"
        let subtitle = isHotel
            ? "\(player.name) construiu um Hotel em \(property.name) por \(property.houseCost.asCurrency)"
            : "\(player.name) construiu a \(newHouses)ª casa em \(property.name) por \(property.houseCost.asCurrency)"
        
        logTransaction(
            type: .houseBuild,
            amount: property.houseCost,
            senderId: player.id,
            senderName: player.name,
            senderColor: player.color,
            receiverId: nil,
            receiverName: "Banco",
            receiverColor: nil,
            title: title,
            subtitle: subtitle,
            propertyId: property.id,
            propertyName: property.name,
            previousOwnerId: player.id,
            previousHousesCount: oldHouses,
            newHousesCount: newHouses
        )
        
        HapticManager.notification(.success)
        SoundManager.play(.moneyOut)
        saveToUserDefaults()
        return true
    }
    
    /// Vende/desmonta uma casa ou hotel de um imóvel, reembolsando 50% do custo de construção.
    @discardableResult
    func sellHouse(propertyId: UUID) -> Bool {
        guard let propIndex = properties.firstIndex(where: { $0.id == propertyId }) else { return false }
        let property = properties[propIndex]
        
        guard let ownerId = property.ownerId,
              let playerIndex = players.firstIndex(where: { $0.id == ownerId }) else {
            return false
        }
        
        guard property.canSellHouse else {
            errorMessage = "Não há construções para vender neste imóvel."
            return false
        }
        
        let oldHouses = property.housesCount
        let newHouses = oldHouses - 1
        let refund = property.houseSellRefund
        
        players[playerIndex].balance += refund
        properties[propIndex].housesCount = newHouses
        
        let wasHotel = oldHouses == 5
        let title = wasHotel ? "Venda de Hotel" : "Venda de Casa"
        let subtitle = wasHotel
            ? "\(players[playerIndex].name) vendeu o Hotel de \(property.name) e recebeu \(refund.asCurrency)"
            : "\(players[playerIndex].name) vendeu uma casa de \(property.name) e recebeu \(refund.asCurrency)"
        
        logTransaction(
            type: .houseSell,
            amount: refund,
            senderId: nil,
            senderName: "Banco",
            senderColor: nil,
            receiverId: players[playerIndex].id,
            receiverName: players[playerIndex].name,
            receiverColor: players[playerIndex].color,
            title: title,
            subtitle: subtitle,
            propertyId: property.id,
            propertyName: property.name,
            previousOwnerId: players[playerIndex].id,
            previousHousesCount: oldHouses,
            newHousesCount: newHouses
        )
        
        HapticManager.impact(.medium)
        SoundManager.play(.moneyIn)
        saveToUserDefaults()
        return true
    }
    
    /// Hipoteca um imóvel sem casas, recebendo 50% do valor de compra do Banco.
    @discardableResult
    func mortgageProperty(propertyId: UUID) -> Bool {
        guard let propIndex = properties.firstIndex(where: { $0.id == propertyId }) else { return false }
        let property = properties[propIndex]
        
        guard let ownerId = property.ownerId,
              let playerIndex = players.firstIndex(where: { $0.id == ownerId }) else {
            return false
        }
        
        guard property.canMortgage else {
            errorMessage = property.housesCount > 0
                ? "É necessário vender todas as casas antes de hipotecar."
                : "Imóvel já está hipotecado."
            HapticManager.notification(.warning)
            return false
        }
        
        let mortgageAmount = property.mortgageValue
        players[playerIndex].balance += mortgageAmount
        properties[propIndex].isMortgaged = true
        
        logTransaction(
            type: .propertyMortgage,
            amount: mortgageAmount,
            senderId: nil,
            senderName: "Banco",
            senderColor: nil,
            receiverId: players[playerIndex].id,
            receiverName: players[playerIndex].name,
            receiverColor: players[playerIndex].color,
            title: "Hipoteca de Imóvel 📄",
            subtitle: "\(players[playerIndex].name) hipotecou \(property.name) por \(mortgageAmount.asCurrency)",
            propertyId: property.id,
            propertyName: property.name,
            previousOwnerId: players[playerIndex].id,
            previousHousesCount: 0,
            newHousesCount: 0
        )
        
        HapticManager.impact(.medium)
        SoundManager.play(.moneyIn)
        saveToUserDefaults()
        return true
    }
    
    /// Resgata um imóvel hipotecado pagando o valor da hipoteca + 10% de juros ao Banco.
    @discardableResult
    func unmortgageProperty(propertyId: UUID) -> Bool {
        guard let propIndex = properties.firstIndex(where: { $0.id == propertyId }) else { return false }
        let property = properties[propIndex]
        
        guard let ownerId = property.ownerId,
              let playerIndex = players.firstIndex(where: { $0.id == ownerId }) else {
            return false
        }
        
        guard property.canUnmortgage else {
            errorMessage = "O imóvel não está hipotecado."
            return false
        }
        
        let cost = property.unmortgageCost
        let player = players[playerIndex]
        
        guard player.balance >= cost else {
            errorMessage = "\(player.name) não possui saldo (\(cost.asCurrency)) para resgatar a hipoteca de \(property.name)."
            HapticManager.notification(.error)
            SoundManager.play(.bankruptcy)
            return false
        }
        
        players[playerIndex].balance -= cost
        properties[propIndex].isMortgaged = false
        
        logTransaction(
            type: .propertyUnmortgage,
            amount: cost,
            senderId: player.id,
            senderName: player.name,
            senderColor: player.color,
            receiverId: nil,
            receiverName: "Banco",
            receiverColor: nil,
            title: "Resgate de Hipoteca",
            subtitle: "\(player.name) resgatou \(property.name) pagando \(cost.asCurrency)",
            propertyId: property.id,
            propertyName: property.name,
            previousOwnerId: player.id,
            previousHousesCount: 0,
            newHousesCount: 0
        )
        
        HapticManager.notification(.success)
        SoundManager.play(.moneyOut)
        saveToUserDefaults()
        return true
    }
    
    /// Negocia/transfere uma propriedade entre dois jogadores por um preço combinado.
    @discardableResult
    func transferProperty(propertyId: UUID, to receiverId: UUID, price: Decimal) -> Bool {
        guard let prop = properties.first(where: { $0.id == propertyId }), let ownerId = prop.ownerId else { return false }
        return transferProperty(propertyId: propertyId, from: ownerId, to: receiverId, price: price)
    }
    
    /// Negocia/transfere uma propriedade entre dois jogadores por um preço combinado especificando vendedor.
    @discardableResult
    func transferProperty(propertyId: UUID, from senderId: UUID, to receiverId: UUID, price: Decimal) -> Bool {
        guard let propIndex = properties.firstIndex(where: { $0.id == propertyId }),
              let senderIndex = players.firstIndex(where: { $0.id == senderId }),
              let receiverIndex = players.firstIndex(where: { $0.id == receiverId }),
              senderId != receiverId else {
            return false
        }
        
        let property = properties[propIndex]
        guard property.ownerId == senderId else {
            errorMessage = "O vendedor não é dono de \(property.name)."
            return false
        }
        
        let buyer = players[receiverIndex]
        let seller = players[senderIndex]
        
        if price > 0 {
            guard buyer.balance >= price else {
                errorMessage = "\(buyer.name) não possui saldo (\(price.asCurrency)) para comprar de \(seller.name)."
                HapticManager.notification(.error)
                return false
            }
            players[receiverIndex].balance -= price
            players[senderIndex].balance += price
        }
        
        properties[propIndex].ownerId = receiverId
        
        logTransaction(
            type: .propertySale,
            amount: price,
            senderId: seller.id,
            senderName: seller.name,
            senderColor: seller.color,
            receiverId: buyer.id,
            receiverName: buyer.name,
            receiverColor: buyer.color,
            title: "Transferência de Imóvel",
            subtitle: price > 0
                ? "\(seller.name) vendeu \(property.name) para \(buyer.name) por \(price.asCurrency)"
                : "\(seller.name) transferiu \(property.name) para \(buyer.name)",
            propertyId: property.id,
            propertyName: property.name,
            previousOwnerId: seller.id,
            previousHousesCount: property.housesCount,
            newHousesCount: property.housesCount
        )
        
        HapticManager.notification(.success)
        SoundManager.play(.moneyOut)
        saveToUserDefaults()
        return true
    }
    
    /// Cobra e transfere o aluguel exato calculado para um imóvel onde um jogador caiu.
    @discardableResult
    func chargeRent(propertyId: UUID, paidBy payerId: UUID, diceSum: Int? = nil) -> Bool {
        guard let propIndex = properties.firstIndex(where: { $0.id == propertyId }) else { return false }
        let property = properties[propIndex]
        
        guard let ownerId = property.ownerId,
              let ownerIndex = players.firstIndex(where: { $0.id == ownerId }),
              let payerIndex = players.firstIndex(where: { $0.id == payerId }),
              ownerId != payerId else {
            return false
        }
        
        guard !property.isMortgaged else {
            errorMessage = "\(property.name) está hipotecada. Não há cobrança de aluguel."
            HapticManager.notification(.warning)
            return false
        }
        
        let monopoly = hasMonopoly(for: property.group, playerId: ownerId)
        let companiesCount = ownedCompaniesCount(for: ownerId)
        let rentAmount = property.calculateRent(hasMonopoly: monopoly, diceSum: diceSum, ownedCompaniesCount: companiesCount)
        
        guard rentAmount > 0 else { return false }
        
        let payer = players[payerIndex]
        let owner = players[ownerIndex]
        
        players[payerIndex].balance -= rentAmount
        players[ownerIndex].balance += rentAmount
        
        let detailNote: String
        if property.isCompany {
            detailNote = "Aluguel da Cia (\(companiesCount) cias)"
        } else if property.isHotel {
            detailNote = "Aluguel com Hotel 🏨"
        } else if property.housesCount > 0 {
            detailNote = "Aluguel (\(property.housesCount)🏠)"
        } else if monopoly {
            detailNote = "Aluguel c/ Monopólio 2x"
        } else {
            detailNote = "Aluguel Simples"
        }
        
        logTransaction(
            type: .rentPayment,
            amount: rentAmount,
            senderId: payer.id,
            senderName: payer.name,
            senderColor: payer.color,
            receiverId: owner.id,
            receiverName: owner.name,
            receiverColor: owner.color,
            title: "Aluguel: \(property.name)",
            subtitle: "\(payer.name) pagou \(rentAmount.asCurrency) para \(owner.name) (\(detailNote))",
            propertyId: property.id,
            propertyName: property.name,
            previousOwnerId: owner.id,
            previousHousesCount: property.housesCount,
            newHousesCount: property.housesCount
        )
        
        HapticManager.notification(.success)
        SoundManager.play(.moneyOut)
        saveToUserDefaults()
        return true
    }
    
    // MARK: - Histórico & Transações
    
    private func logTransaction(
        type: TransactionType,
        amount: Decimal,
        senderId: UUID? = nil,
        senderName: String? = nil,
        senderColor: PlayerColor? = nil,
        receiverId: UUID? = nil,
        receiverName: String? = nil,
        receiverColor: PlayerColor? = nil,
        title: String,
        subtitle: String,
        propertyId: UUID? = nil,
        propertyName: String? = nil,
        previousOwnerId: UUID? = nil,
        previousHousesCount: Int? = nil,
        newHousesCount: Int? = nil
    ) {
        let transaction = Transaction(
            type: type,
            amount: amount,
            senderId: senderId,
            senderName: senderName,
            senderColor: senderColor,
            receiverId: receiverId,
            receiverName: receiverName,
            receiverColor: receiverColor,
            title: title,
            subtitle: subtitle,
            propertyId: propertyId,
            propertyName: propertyName,
            previousOwnerId: previousOwnerId,
            previousHousesCount: previousHousesCount,
            newHousesCount: newHousesCount
        )
        transactions.insert(transaction, at: 0) // Mais recentes no topo
    }
    
    /// Retorna as transações filtradas por jogador ou todas se nil.
    func transactions(for playerId: UUID?) -> [Transaction] {
        guard let playerId = playerId else { return transactions }
        return transactions.filter { $0.senderId == playerId || $0.receiverId == playerId }
    }
    
    // MARK: - Persistência
    
    /// Salva o estado atual e o histórico no UserDefaults.
    func saveToUserDefaults() {
        let config = GameConfig(
            initialBalance: initialBalance,
            players: players,
            transactions: transactions,
            properties: properties,
            isGameActive: isGameActive,
            isDiceEnabled: isDiceEnabled,
            isSoundEnabled: isSoundEnabled,
            isKeepScreenAwakeEnabled: isKeepScreenAwakeEnabled,
            elapsedTime: elapsedTime,
            updatedAt: Date()
        )
        
        do {
            try storageService.save(config: config)
        } catch {
            errorMessage = "Falha ao salvar a partida no dispositivo."
        }
        
        broadcastCurrentState()
    }
    
    /// Carrega os dados persistidos previamente.
    func loadFromUserDefaults() {
        if let config = storageService.load() {
            self.initialBalance = config.initialBalance
            self.players = config.players
            self.transactions = config.transactions
            self.properties = config.properties.isEmpty ? Property.defaultProperties() : config.properties
            self.isGameActive = config.isGameActive
            self.isDiceEnabled = config.isDiceEnabled
            self.isSoundEnabled = config.isSoundEnabled
            self.isKeepScreenAwakeEnabled = config.isKeepScreenAwakeEnabled
            self.elapsedTime = config.elapsedTime
            SoundManager.isMuted = !config.isSoundEnabled
            updateScreenAwakeState()
        }
    }
    
    // MARK: - Modo Multi-Aparelho Local (P2P Host & Sync)
    
    /// Configura o ouvinte de ações remotas originadas das Carteiras dos jogadores (iPhones).
    private func setupMultipeerHandler() {
        MultipeerGameService.shared.onReceiveActionFromClient = { [weak self] action, peerID in
            guard let self = self else { return }
            self.handleRemoteAction(action, from: peerID)
        }
        
        MultipeerGameService.shared.onPeerConnected = { [weak self] in
            guard let self = self else { return }
            self.broadcastCurrentState()
        }
    }
    
    /// Exibe um toast flutuante no topo da Mesa Central para notificar ações dos iPhones
    func triggerRemoteNotification(title: String, subtitle: String, icon: String, colorName: String) {
        notificationDismissTask?.cancel()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            self.remoteActionNotification = ActionNotification(
                title: title,
                subtitle: subtitle,
                icon: icon,
                colorName: colorName
            )
        }
        
        notificationDismissTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 3_500_000_000)
            if !Task.isCancelled {
                withAnimation(.easeOut(duration: 0.25)) {
                    self.remoteActionNotification = nil
                }
            }
        }
    }
    
    /// Processa a intenção de ação remota recebida de um iPhone conectado.
    private func handleRemoteAction(_ action: PlayerNetworkAction, from peerID: MCPeerID) {
        switch action {
        case .claimPlayer(let playerId, let deviceName):
            if let p = players.first(where: { $0.id == playerId }) {
                triggerRemoteNotification(
                    title: "Peão Conectado 📱",
                    subtitle: "\(p.name) foi assumido por \(deviceName)",
                    icon: "person.badge.shield.checkmark.fill",
                    colorName: "green"
                )
            }
            broadcastCurrentState()
            
        case .releasePlayer(let playerId):
            if let p = players.first(where: { $0.id == playerId }) {
                triggerRemoteNotification(
                    title: "Peão Liberado 🔓",
                    subtitle: "\(p.name) voltou a ser controlado pela Mesa",
                    icon: "person.crop.circle.badge.xmark",
                    colorName: "yellow"
                )
            }
            broadcastCurrentState()
            
        case .receiveSalary(let playerId, let amount):
            if let p = players.first(where: { $0.id == playerId }) {
                triggerRemoteNotification(
                    title: "Salário Recebido 💰",
                    subtitle: "\(p.name) passou pelo Início e recebeu \(amount.asCurrency)",
                    icon: "arrow.counterclockwise.circle.fill",
                    colorName: "green"
                )
            }
            receiveSalary(for: playerId, amount: amount)
            
        case .adjustBalance(let playerId, let delta, let reason):
            if let p = players.first(where: { $0.id == playerId }) {
                if delta > 0 {
                    triggerRemoteNotification(
                        title: "Recebimento do Banco 🏦",
                        subtitle: "\(p.name) recebeu \(delta.asCurrency)\(reason.map { " (\($0))" } ?? "")",
                        icon: "banknote.fill",
                        colorName: "green"
                    )
                } else {
                    triggerRemoteNotification(
                        title: "Pagamento ao Banco 💳",
                        subtitle: "\(p.name) pagou \((-delta).asCurrency)\(reason.map { " (\($0))" } ?? "")",
                        icon: "creditcard.fill",
                        colorName: "coral"
                    )
                }
            }
            adjustBalance(for: playerId, delta: delta, customReason: reason)
            
        case .transferMoney(let fromPlayerId, let toPlayerId, let amount):
            let sender = players.first(where: { $0.id == fromPlayerId })?.name ?? "Jogador"
            let receiver = players.first(where: { $0.id == toPlayerId })?.name ?? "Jogador"
            triggerRemoteNotification(
                title: "Transferência Direta 🤝",
                subtitle: "\(sender) pagou \(amount.asCurrency) para \(receiver)",
                icon: "paperplane.fill",
                colorName: "blue"
            )
            transferMoney(from: fromPlayerId, to: toPlayerId, amount: amount)
            
        case .buyProperty(let propertyId, let playerId):
            let player = players.first(where: { $0.id == playerId })?.name ?? "Jogador"
            let prop = properties.first(where: { $0.id == propertyId })?.name ?? "Imóvel"
            triggerRemoteNotification(
                title: "Compra de Imóvel 🏢",
                subtitle: "\(player) comprou \(prop)",
                icon: "building.2.fill",
                colorName: "yellow"
            )
            buyProperty(propertyId: propertyId, by: playerId)
            
        case .buildHouse(let propertyId, let playerId):
            let player = players.first(where: { $0.id == playerId })?.name ?? "Jogador"
            let prop = properties.first(where: { $0.id == propertyId })?.name ?? "Imóvel"
            triggerRemoteNotification(
                title: "Construção de Imóvel 🏠",
                subtitle: "\(player) construiu em \(prop)",
                icon: "hammer.fill",
                colorName: "green"
            )
            buildHouse(propertyId: propertyId)
            
        case .sellHouse(let propertyId, let playerId):
            let player = players.first(where: { $0.id == playerId })?.name ?? "Jogador"
            let prop = properties.first(where: { $0.id == propertyId })?.name ?? "Imóvel"
            triggerRemoteNotification(
                title: "Venda de Casa 🔨",
                subtitle: "\(player) vendeu uma construção em \(prop)",
                icon: "arrow.down.square.fill",
                colorName: "yellow"
            )
            sellHouse(propertyId: propertyId)
            
        case .mortgageProperty(let propertyId, let playerId):
            let player = players.first(where: { $0.id == playerId })?.name ?? "Jogador"
            let prop = properties.first(where: { $0.id == propertyId })?.name ?? "Imóvel"
            triggerRemoteNotification(
                title: "Hipoteca 📑",
                subtitle: "\(player) hipotecou \(prop)",
                icon: "doc.text.fill",
                colorName: "coral"
            )
            mortgageProperty(propertyId: propertyId)
            
        case .unmortgageProperty(let propertyId, let playerId):
            let player = players.first(where: { $0.id == playerId })?.name ?? "Jogador"
            let prop = properties.first(where: { $0.id == propertyId })?.name ?? "Imóvel"
            triggerRemoteNotification(
                title: "Resgate de Hipoteca 🔓",
                subtitle: "\(player) resgatou \(prop)",
                icon: "lock.open.fill",
                colorName: "green"
            )
            unmortgageProperty(propertyId: propertyId)
            
        case .chargeRent(let propertyId, let payerId, let diceSum):
            let payer = players.first(where: { $0.id == payerId })?.name ?? "Jogador"
            let prop = properties.first(where: { $0.id == propertyId })
            let owner = players.first(where: { $0.id == prop?.ownerId })?.name ?? "Dono"
            triggerRemoteNotification(
                title: "Aluguel Pago 💸",
                subtitle: "\(payer) pagou aluguel de \(prop?.name ?? "Imóvel") para \(owner)",
                icon: "dollarsign.circle.fill",
                colorName: "purple"
            )
            chargeRent(propertyId: propertyId, paidBy: payerId, diceSum: diceSum)
            
        case .transferProperty(let propertyId, let fromPlayerId, let toPlayerId, let price):
            let sender = players.first(where: { $0.id == fromPlayerId })?.name ?? "Jogador"
            let receiver = players.first(where: { $0.id == toPlayerId })?.name ?? "Jogador"
            let prop = properties.first(where: { $0.id == propertyId })?.name ?? "Imóvel"
            triggerRemoteNotification(
                title: "Transferência de Imóvel 📜",
                subtitle: "\(sender) vendeu \(prop) para \(receiver) por \(price.asCurrency)",
                icon: "arrow.left.arrow.right",
                colorName: "blue"
            )
            transferProperty(propertyId: propertyId, from: fromPlayerId, to: toPlayerId, price: price)
            
        case .rollDice:
            triggerRemoteNotification(
                title: "Dados Rolados 🎲",
                subtitle: "\(peerID.displayName) rolou os dados na mesa",
                icon: "die.face.5.fill",
                colorName: "yellow"
            )
            rollDice()
            
        case .toggleBankruptcy(let playerId):
            let p = players.first(where: { $0.id == playerId })?.name ?? "Jogador"
            triggerRemoteNotification(
                title: "Status de Jogo ⚠️",
                subtitle: "Alterado status de falência de \(p)",
                icon: "xmark.octagon.fill",
                colorName: "coral"
            )
            toggleBankruptcy(for: playerId)
        }
    }
    
    /// Transmite o snapshot completo do jogo para todos os iPhones conectados via Multipeer P2P.
    func broadcastCurrentState(lastMessage: String? = nil) {
        guard MultipeerGameService.shared.role == .host else { return }
        
        let packet = GameSyncPacket(
            gameId: UUID(),
            sessionId: MultipeerGameService.shared.currentSessionId,
            hostDeviceName: MultipeerGameService.shared.myPeerID.displayName,
            players: players,
            properties: properties,
            transactions: transactions,
            initialBalance: initialBalance,
            elapsedTime: elapsedTime,
            isGameActive: isGameActive,
            dice1: dice1,
            dice2: dice2,
            isRollingDice: isRollingDice,
            consecutiveDoublesCount: consecutiveDoublesCount,
            diceBannerMessage: diceBannerMessage,
            lastActionMessage: lastMessage,
            hostPlayerId: hostPlayerId,
            claimedPlayerDeviceNames: MultipeerGameService.shared.claimedPlayerDeviceMap,
            isGameSetupPhase: !isGameActive
        )
        
        MultipeerGameService.shared.broadcastGameState(packet)
    }
}
