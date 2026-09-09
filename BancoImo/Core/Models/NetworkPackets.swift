//
//  NetworkPackets.swift
//  BancoImo
//
//  Created by iOS Senior Developer.
//

import Foundation

// MARK: - Pacote de Sincronização Geral (Host -> Clientes)

/// Snapshot completo do estado da mesa transmitido pelo Host (iPad) para todas as Carteiras Conectadas (iPhones).
struct GameSyncPacket: Codable, Sendable {
    let gameId: UUID
    let sessionId: String
    let hostDeviceName: String
    let players: [Player]
    let properties: [Property]
    let transactions: [Transaction]
    let initialBalance: Decimal
    let elapsedTime: TimeInterval
    let isGameActive: Bool
    let dice1: Int
    let dice2: Int
    let isRollingDice: Bool
    let consecutiveDoublesCount: Int
    let diceBannerMessage: String?
    let lastActionMessage: String?
    let hostPlayerId: UUID?
    let claimedPlayerDeviceNames: [UUID: String]
    let isGameSetupPhase: Bool
    let timestamp: Date
    
    init(
        gameId: UUID,
        sessionId: String,
        hostDeviceName: String,
        players: [Player],
        properties: [Property],
        transactions: [Transaction],
        initialBalance: Decimal,
        elapsedTime: TimeInterval,
        isGameActive: Bool,
        dice1: Int,
        dice2: Int,
        isRollingDice: Bool,
        consecutiveDoublesCount: Int,
        diceBannerMessage: String?,
        lastActionMessage: String?,
        hostPlayerId: UUID? = nil,
        claimedPlayerDeviceNames: [UUID: String] = [:],
        isGameSetupPhase: Bool = false,
        timestamp: Date = Date()
    ) {
        self.gameId = gameId
        self.sessionId = sessionId
        self.hostDeviceName = hostDeviceName
        self.players = players
        self.properties = properties
        self.transactions = transactions
        self.initialBalance = initialBalance
        self.elapsedTime = elapsedTime
        self.isGameActive = isGameActive
        self.dice1 = dice1
        self.dice2 = dice2
        self.isRollingDice = isRollingDice
        self.consecutiveDoublesCount = consecutiveDoublesCount
        self.diceBannerMessage = diceBannerMessage
        self.lastActionMessage = lastActionMessage
        self.hostPlayerId = hostPlayerId
        self.claimedPlayerDeviceNames = claimedPlayerDeviceNames
        self.isGameSetupPhase = isGameSetupPhase
        self.timestamp = timestamp
    }
}

// MARK: - Notificação de Ação Remota na Mesa

struct ActionNotification: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let subtitle: String
    let icon: String
    let colorName: String // "green", "coral", "yellow", "blue", "purple"
}

// MARK: - Ações e Intenções Remotas (Cliente -> Host)

/// Ação enviada pelo iPhone do jogador para ser processada na Mesa Central (iPad).
enum PlayerNetworkAction: Codable, Sendable {
    /// Reivindica o controle de um peão/jogador na mesa
    case claimPlayer(playerId: UUID, deviceName: String)
    /// Libera o controle de um peão
    case releasePlayer(playerId: UUID)
    /// Recebe salário (+2.000 ao passar pelo Início)
    case receiveSalary(playerId: UUID, amount: Decimal)
    /// Ajusta saldo com o Banco (Pagamento ou Recebimento)
    case adjustBalance(playerId: UUID, delta: Decimal, reason: String?)
    /// Transfere dinheiro para outro jogador (Aluguel livre ou Acordo)
    case transferMoney(fromPlayerId: UUID, toPlayerId: UUID, amount: Decimal)
    /// Compra um imóvel do Banco
    case buyProperty(propertyId: UUID, playerId: UUID)
    /// Constrói uma casa ou hotel
    case buildHouse(propertyId: UUID, playerId: UUID)
    /// Vende uma casa ou hotel
    case sellHouse(propertyId: UUID, playerId: UUID)
    /// Hipoteca um imóvel
    case mortgageProperty(propertyId: UUID, playerId: UUID)
    /// Resgata um imóvel hipotecado
    case unmortgageProperty(propertyId: UUID, playerId: UUID)
    /// Cobra aluguel de um jogador que caiu na propriedade
    case chargeRent(propertyId: UUID, payerId: UUID, diceSum: Int?)
    /// Vende/transfere um imóvel para outro jogador
    case transferProperty(propertyId: UUID, fromPlayerId: UUID, toPlayerId: UUID, price: Decimal)
    /// Rola os dados físicos/virtuais na mesa central
    case rollDice(playerId: UUID)
    /// Alterna status de falência
    case toggleBankruptcy(playerId: UUID)
}

// MARK: - Dados do QR Code de Pareamento

/// Estrutura codificada dentro do QR Code gerado pelo iPad para conexão instantânea sem digitação.
struct HostQRData: Codable, Sendable {
    let sessionId: String
    let hostName: String
    let gameId: UUID
    let serviceType: String
    
    init(
        sessionId: String,
        hostName: String,
        gameId: UUID,
        serviceType: String = "bancoimo-p2p"
    ) {
        self.sessionId = sessionId
        self.hostName = hostName
        self.gameId = gameId
        self.serviceType = serviceType
    }
    
    func encodeToString() -> String? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        return data.base64EncodedString()
    }
    
    static func decodeFromString(_ string: String) -> HostQRData? {
        guard let data = Data(base64Encoded: string) else { return nil }
        return try? JSONDecoder().decode(HostQRData.self, from: data)
    }
}

// MARK: - Estado de Conexão e Informações de Dispositivos

/// Estado da conexão Multipeer
enum PeerConnectionState: Equatable, Sendable {
    case disconnected
    case browsing
    case advertising
    case connecting(peerName: String)
    case connected(peerName: String)
    case error(message: String)
    
    var isConnected: Bool {
        if case .connected = self { return true }
        return false
    }
    
    var description: String {
        switch self {
        case .disconnected:
            return "Desconectado"
        case .browsing:
            return "Procurando mesa..."
        case .advertising:
            return "Transmitindo mesa (P2P)..."
        case .connecting(let name):
            return "Conectando a \(name)..."
        case .connected(let name):
            return "Conectado a \(name)"
        case .error(let msg):
            return "Erro: \(msg)"
        }
    }
}

/// Dispositivo conectado ao Host
struct ConnectedPeerDevice: Identifiable, Sendable, Equatable {
    var id: String { peerIdName }
    let peerIdName: String
    let deviceDisplayName: String
    var claimedPlayerId: UUID?
    var claimedPlayerName: String?
    var isConnected: Bool
    
    init(
        peerIdName: String,
        deviceDisplayName: String,
        claimedPlayerId: UUID? = nil,
        claimedPlayerName: String? = nil,
        isConnected: Bool = true
    ) {
        self.peerIdName = peerIdName
        self.deviceDisplayName = deviceDisplayName
        self.claimedPlayerId = claimedPlayerId
        self.claimedPlayerName = claimedPlayerName
        self.isConnected = isConnected
    }
}
