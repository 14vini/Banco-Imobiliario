//
//  BalanceHistoryPoint.swift
//  BancoImo
//
//  Created by iOS Senior Developer.
//

import Foundation

/// Ponto de dados temporal para o Gráfico de Linha de Evolução Patrimonial (Swift Charts).
struct BalanceHistoryPoint: Identifiable, Equatable {
    let id: UUID
    let stepIndex: Int
    let stepLabel: String
    let timestamp: Date
    let playerId: UUID
    let playerName: String
    let playerColor: PlayerColor
    let balance: Double
    
    init(
        id: UUID = UUID(),
        stepIndex: Int,
        stepLabel: String,
        timestamp: Date = Date(),
        playerId: UUID,
        playerName: String,
        playerColor: PlayerColor,
        balance: Double
    ) {
        self.id = id
        self.stepIndex = stepIndex
        self.stepLabel = stepLabel
        self.timestamp = timestamp
        self.playerId = playerId
        self.playerName = playerName
        self.playerColor = playerColor
        self.balance = balance
    }
}
