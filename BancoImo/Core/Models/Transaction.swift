//
//  Transaction.swift
//  BancoImo
//
//  Created by iOS Senior Developer.
//

import Foundation

/// Tipos de movimentação financeira na partida.
enum TransactionType: String, Codable, CaseIterable, Equatable, Hashable {
    case salary = "salary"                     // Salário por passar pelo início (+2000)
    case bankDeposit = "bankDeposit"           // Recebimento avulso do Banco
    case bankPayment = "bankPayment"           // Pagamento de taxas/impostos ao Banco
    case transfer = "transfer"                 // Transferência genérica entre jogadores
    case initialBalance = "initialBalance"     // Saldo inicial de setup
    case bankruptcy = "bankruptcy"             // Falência declarada
    case propertyPurchase = "propertyPurchase" // Compra de imóvel do Banco
    case propertySale = "propertySale"         // Venda/Negociação de imóvel entre jogadores
    case houseBuild = "houseBuild"             // Construção de Casa ou Hotel
    case houseSell = "houseSell"               // Venda/Liquidação de Casa
    case propertyMortgage = "propertyMortgage" // Hipoteca de imóvel
    case propertyUnmortgage = "propertyUnmortgage" // Resgate de Hipoteca
    case rentPayment = "rentPayment"           // Pagamento de Aluguel

    var iconName: String {
        switch self {
        case .salary: return "gift.fill"
        case .bankDeposit: return "arrow.down.left.circle.fill"
        case .bankPayment: return "arrow.up.right.circle.fill"
        case .transfer: return "arrow.left.arrow.right.circle.fill"
        case .initialBalance: return "banknote.fill"
        case .bankruptcy: return "xmark.octagon.fill"
        case .propertyPurchase: return "building.2.crop.circle.fill"
        case .propertySale: return "arrow.left.arrow.right.circle.fill"
        case .houseBuild: return "hammer.fill"
        case .houseSell: return "house.slash.fill"
        case .propertyMortgage: return "doc.text.fill"
        case .propertyUnmortgage: return "checkmark.seal.fill"
        case .rentPayment: return "dollarsign.arrow.circlepath"
        }
    }
}

/// Registro imutável de uma transação financeira ou imobiliária ocorrida durante o jogo.
struct Transaction: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    let timestamp: Date
    let type: TransactionType
    let amount: Decimal
    let senderId: UUID?
    let senderName: String?
    let senderColor: PlayerColor?
    let receiverId: UUID?
    let receiverName: String?
    let receiverColor: PlayerColor?
    let title: String
    let subtitle: String
    
    // Metadados Imobiliários (para histórico e reversão do Undo)
    let propertyId: UUID?
    let propertyName: String?
    let previousOwnerId: UUID?
    let previousHousesCount: Int?
    let newHousesCount: Int?
    
    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
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
        self.id = id
        self.timestamp = timestamp
        self.type = type
        self.amount = amount
        self.senderId = senderId
        self.senderName = senderName
        self.senderColor = senderColor
        self.receiverId = receiverId
        self.receiverName = receiverName
        self.receiverColor = receiverColor
        self.title = title
        self.subtitle = subtitle
        self.propertyId = propertyId
        self.propertyName = propertyName
        self.previousOwnerId = previousOwnerId
        self.previousHousesCount = previousHousesCount
        self.newHousesCount = newHousesCount
    }
    
    /// Hora formatada da transação (ex: "14:35:10").
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: timestamp)
    }
}
