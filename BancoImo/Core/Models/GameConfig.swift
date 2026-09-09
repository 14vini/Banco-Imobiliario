//
//  GameConfig.swift
//  BancoImo
//
//  Created by iOS Senior Developer.
//

import Foundation

/// Modelo que encapsula a configuração, o estado completo e o histórico de transações da partida.
struct GameConfig: Identifiable, Codable, Equatable {
    let id: UUID
    var initialBalance: Decimal
    var players: [Player]
    var transactions: [Transaction]
    var properties: [Property]
    var isGameActive: Bool
    var isDiceEnabled: Bool
    var isSoundEnabled: Bool
    var isKeepScreenAwakeEnabled: Bool
    var elapsedTime: TimeInterval
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        initialBalance: Decimal = 1500,
        players: [Player] = [],
        transactions: [Transaction] = [],
        properties: [Property] = Property.defaultProperties(),
        isGameActive: Bool = false,
        isDiceEnabled: Bool = true,
        isSoundEnabled: Bool = true,
        isKeepScreenAwakeEnabled: Bool = true,
        elapsedTime: TimeInterval = 0,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.initialBalance = initialBalance
        self.players = players
        self.transactions = transactions
        self.properties = properties
        self.isGameActive = isGameActive
        self.isDiceEnabled = isDiceEnabled
        self.isSoundEnabled = isSoundEnabled
        self.isKeepScreenAwakeEnabled = isKeepScreenAwakeEnabled
        self.elapsedTime = elapsedTime
        self.updatedAt = updatedAt
    }
    
    enum CodingKeys: String, CodingKey {
        case id, initialBalance, players, transactions, properties, isGameActive, isDiceEnabled, isSoundEnabled, isKeepScreenAwakeEnabled, elapsedTime, updatedAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.initialBalance = try container.decodeIfPresent(Decimal.self, forKey: .initialBalance) ?? 1500
        self.players = try container.decodeIfPresent([Player].self, forKey: .players) ?? []
        self.transactions = try container.decodeIfPresent([Transaction].self, forKey: .transactions) ?? []
        self.properties = try container.decodeIfPresent([Property].self, forKey: .properties) ?? Property.defaultProperties()
        self.isGameActive = try container.decodeIfPresent(Bool.self, forKey: .isGameActive) ?? false
        self.isDiceEnabled = try container.decodeIfPresent(Bool.self, forKey: .isDiceEnabled) ?? true
        self.isSoundEnabled = try container.decodeIfPresent(Bool.self, forKey: .isSoundEnabled) ?? true
        self.isKeepScreenAwakeEnabled = try container.decodeIfPresent(Bool.self, forKey: .isKeepScreenAwakeEnabled) ?? true
        self.elapsedTime = try container.decodeIfPresent(TimeInterval.self, forKey: .elapsedTime) ?? 0
        self.updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
    }
}
