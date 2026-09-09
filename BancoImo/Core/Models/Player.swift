//
//  Player.swift
//  BancoImo
//
//  Created by iOS Senior Developer.
//

import Foundation

/// Modelo que representa um jogador individual na partida.
struct Player: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var name: String
    var balance: Decimal
    var color: PlayerColor
    var isBankrupt: Bool
    
    init(
        id: UUID = UUID(),
        name: String,
        balance: Decimal,
        color: PlayerColor,
        isBankrupt: Bool = false
    ) {
        self.id = id
        self.name = name
        self.balance = balance
        self.color = color
        self.isBankrupt = isBankrupt
    }
}
