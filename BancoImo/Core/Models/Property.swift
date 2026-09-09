//
//  Property.swift
//  BancoImo
//
//  Created by iOS Senior Developer.
//

import SwiftUI

/// Grupos de Bairros / Cores das propriedades no tabuleiro do Banco Imobiliário.
enum PropertyGroupType: String, Codable, CaseIterable, Identifiable, Equatable, Hashable {
    case purple     // Bairro 1: Av. Sumaré, Praça da Sé
    case lightBlue  // Bairro 2: Rua 25 de Março, Av. Rio Branco, Av. do Estado
    case pink       // Bairro 3: Av. Pacaembu, Rua Augusta, Av. Europa
    case orange     // Bairro 4: Av. 9 de Julho, Av. Rebouças, Av. Brigadeiro Faria Lima
    case red        // Bairro 5: Av. Nossa Sra. de Copacabana, Av. Brig. Luís Antônio, Av. Paulista
    case yellow     // Bairro 6: Ipanema, Leblon, Flamengo
    case green      // Bairro 7: Botafogo, Morumbi, Jardim Botânico
    case darkBlue   // Bairro 8: Av. Brasil, Av. Atlântica
    case company    // Serviços Públicos / Companhias
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .purple: return "Roxo / Bairro 1"
        case .lightBlue: return "Azul Claro / Bairro 2"
        case .pink: return "Rosa / Bairro 3"
        case .orange: return "Laranja / Bairro 4"
        case .red: return "Vermelho / Bairro 5"
        case .yellow: return "Amarelo / Bairro 6"
        case .green: return "Verde / Bairro 7"
        case .darkBlue: return "Azul Escuro / Bairro 8"
        case .company: return "Companhias de Serviço"
        }
    }
    
    var iconName: String {
        switch self {
        case .purple, .lightBlue, .pink, .orange, .red, .yellow, .green, .darkBlue:
            return "house.fill"
        case .company:
            return "bolt.fill"
        }
    }
    
    var headerColor: Color {
        switch self {
        case .purple: return Color(red: 0.58, green: 0.18, blue: 0.68)
        case .lightBlue: return Color(red: 0.32, green: 0.76, blue: 0.94)
        case .pink: return Color(red: 0.94, green: 0.35, blue: 0.65)
        case .orange: return Color(red: 0.98, green: 0.54, blue: 0.12)
        case .red: return Color(red: 0.92, green: 0.22, blue: 0.22)
        case .yellow: return Color(red: 0.98, green: 0.80, blue: 0.14)
        case .green: return Color(red: 0.18, green: 0.72, blue: 0.34)
        case .darkBlue: return Color(red: 0.10, green: 0.28, blue: 0.74)
        case .company: return Color(red: 0.28, green: 0.30, blue: 0.38)
        }
    }
    
    var headerGradient: LinearGradient {
        LinearGradient(
            colors: [headerColor, headerColor.opacity(0.85)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var textColor: Color {
        switch self {
        case .yellow, .lightBlue: return AppTheme.strokeBlack
        default: return .white
        }
    }
}

/// Modelo de Título de Propriedade Imobiliária individual.
struct Property: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    let name: String
    let group: PropertyGroupType
    let price: Decimal
    let houseCost: Decimal
    let baseRent: Decimal
    let rentWithColorGroup: Decimal
    let rentWith1House: Decimal
    let rentWith2Houses: Decimal
    let rentWith3Houses: Decimal
    let rentWith4Houses: Decimal
    let rentWithHotel: Decimal
    let mortgageValue: Decimal
    let unmortgageCost: Decimal
    
    // Estado Dinâmico da Partida
    var ownerId: UUID?
    var housesCount: Int // 0: Terreno, 1..4: Casas, 5: Hotel
    var isMortgaged: Bool
    
    init(
        id: UUID = UUID(),
        name: String,
        group: PropertyGroupType,
        price: Decimal,
        houseCost: Decimal = 50,
        baseRent: Decimal,
        rentWithColorGroup: Decimal? = nil,
        rentWith1House: Decimal = 0,
        rentWith2Houses: Decimal = 0,
        rentWith3Houses: Decimal = 0,
        rentWith4Houses: Decimal = 0,
        rentWithHotel: Decimal = 0,
        mortgageValue: Decimal? = nil,
        unmortgageCost: Decimal? = nil,
        ownerId: UUID? = nil,
        housesCount: Int = 0,
        isMortgaged: Bool = false
    ) {
        self.id = id
        self.name = name
        self.group = group
        self.price = price
        self.houseCost = houseCost
        self.baseRent = baseRent
        self.rentWithColorGroup = rentWithColorGroup ?? (baseRent * 2)
        self.rentWith1House = rentWith1House
        self.rentWith2Houses = rentWith2Houses
        self.rentWith3Houses = rentWith3Houses
        self.rentWith4Houses = rentWith4Houses
        self.rentWithHotel = rentWithHotel
        
        let calculatedMortgage = mortgageValue ?? (price / 2)
        self.mortgageValue = calculatedMortgage
        self.unmortgageCost = unmortgageCost ?? (calculatedMortgage * Decimal(1.1)) // +10% juros padrão
        
        self.ownerId = ownerId
        self.housesCount = max(0, min(5, housesCount))
        self.isMortgaged = isMortgaged
    }
    
    // MARK: - Propriedades Computadas
    
    var isOwned: Bool {
        ownerId != nil
    }
    
    var isCompany: Bool {
        group == .company
    }
    
    var isHotel: Bool {
        housesCount == 5
    }
    
    var canBuildHouse: Bool {
        !isCompany && !isMortgaged && housesCount < 5 && isOwned
    }
    
    var canSellHouse: Bool {
        !isCompany && !isMortgaged && housesCount > 0 && isOwned
    }
    
    var canMortgage: Bool {
        isOwned && !isMortgaged && housesCount == 0
    }
    
    var canUnmortgage: Bool {
        isOwned && isMortgaged
    }
    
    /// Valor de liquidação de 1 casa (50% do custo de compra).
    var houseSellRefund: Decimal {
        houseCost / 2
    }
    
    /// Avaliação patrimonial total deste imóvel (preço de compra + valor investido nas casas/hotel, ou valor de hipoteca se hipotecado).
    var totalValuation: Decimal {
        if isMortgaged {
            return mortgageValue
        }
        let constructionInvested = Decimal(housesCount) * houseCost
        return price + constructionInvested
    }
    
    /// Calcula o aluguel exato com base no estado do imóvel, monopólio e dados (para companhias).
    func calculateRent(hasMonopoly: Bool = false, diceSum: Int? = nil, ownedCompaniesCount: Int = 1) -> Decimal {
        guard !isMortgaged else { return 0 }
        
        if isCompany {
            // Regra oficial para companhias: multiplicador pelo número de companhias que o dono possui
            // 1 Cia: 40x / R$ 50 base (ou 4x dados). 2+ Cias: 100x / R$ 120 (ou 10x dados).
            if let dice = diceSum, dice > 0 {
                let multiplier = ownedCompaniesCount >= 2 ? Decimal(10) : Decimal(4)
                return Decimal(dice) * multiplier * 10
            } else {
                switch ownedCompaniesCount {
                case 1: return baseRent
                case 2: return rentWith1House
                case 3: return rentWith2Houses
                case 4: return rentWith3Houses
                case 5: return rentWith4Houses
                default: return rentWithHotel
                }
            }
        }
        
        switch housesCount {
        case 1: return rentWith1House
        case 2: return rentWith2Houses
        case 3: return rentWith3Houses
        case 4: return rentWith4Houses
        case 5: return rentWithHotel
        default:
            return hasMonopoly ? rentWithColorGroup : baseRent
        }
    }
    
    // MARK: - Catálogo Oficial Completo (28 Imóveis do Banco Imobiliário Brasileiro)
    
    static func defaultProperties() -> [Property] {
        [
            // MARK: Bairro 1 (Roxo)
            Property(
                name: "Av. Sumaré",
                group: .purple,
                price: 60,
                houseCost: 50,
                baseRent: 2,
                rentWithColorGroup: 4,
                rentWith1House: 10,
                rentWith2Houses: 30,
                rentWith3Houses: 90,
                rentWith4Houses: 160,
                rentWithHotel: 250
            ),
            Property(
                name: "Praça da Sé",
                group: .purple,
                price: 60,
                houseCost: 50,
                baseRent: 4,
                rentWithColorGroup: 8,
                rentWith1House: 20,
                rentWith2Houses: 60,
                rentWith3Houses: 180,
                rentWith4Houses: 320,
                rentWithHotel: 450
            ),
            
            // MARK: Bairro 2 (Azul Claro)
            Property(
                name: "Rua 25 de Março",
                group: .lightBlue,
                price: 100,
                houseCost: 50,
                baseRent: 6,
                rentWithColorGroup: 12,
                rentWith1House: 30,
                rentWith2Houses: 90,
                rentWith3Houses: 270,
                rentWith4Houses: 400,
                rentWithHotel: 550
            ),
            Property(
                name: "Av. Rio Branco",
                group: .lightBlue,
                price: 100,
                houseCost: 50,
                baseRent: 6,
                rentWithColorGroup: 12,
                rentWith1House: 30,
                rentWith2Houses: 90,
                rentWith3Houses: 270,
                rentWith4Houses: 400,
                rentWithHotel: 550
            ),
            Property(
                name: "Av. do Estado",
                group: .lightBlue,
                price: 120,
                houseCost: 50,
                baseRent: 8,
                rentWithColorGroup: 16,
                rentWith1House: 40,
                rentWith2Houses: 100,
                rentWith3Houses: 300,
                rentWith4Houses: 450,
                rentWithHotel: 600
            ),
            
            // MARK: Bairro 3 (Rosa)
            Property(
                name: "Av. Pacaembu",
                group: .pink,
                price: 140,
                houseCost: 100,
                baseRent: 10,
                rentWithColorGroup: 20,
                rentWith1House: 50,
                rentWith2Houses: 150,
                rentWith3Houses: 450,
                rentWith4Houses: 625,
                rentWithHotel: 750
            ),
            Property(
                name: "Rua Augusta",
                group: .pink,
                price: 140,
                houseCost: 100,
                baseRent: 10,
                rentWithColorGroup: 20,
                rentWith1House: 50,
                rentWith2Houses: 150,
                rentWith3Houses: 450,
                rentWith4Houses: 625,
                rentWithHotel: 750
            ),
            Property(
                name: "Av. Europa",
                group: .pink,
                price: 160,
                houseCost: 100,
                baseRent: 12,
                rentWithColorGroup: 24,
                rentWith1House: 60,
                rentWith2Houses: 180,
                rentWith3Houses: 500,
                rentWith4Houses: 700,
                rentWithHotel: 900
            ),
            
            // MARK: Bairro 4 (Laranja)
            Property(
                name: "Av. 9 de Julho",
                group: .orange,
                price: 180,
                houseCost: 100,
                baseRent: 14,
                rentWithColorGroup: 28,
                rentWith1House: 70,
                rentWith2Houses: 200,
                rentWith3Houses: 550,
                rentWith4Houses: 750,
                rentWithHotel: 950
            ),
            Property(
                name: "Av. Rebouças",
                group: .orange,
                price: 180,
                houseCost: 100,
                baseRent: 14,
                rentWithColorGroup: 28,
                rentWith1House: 70,
                rentWith2Houses: 200,
                rentWith3Houses: 550,
                rentWith4Houses: 750,
                rentWithHotel: 950
            ),
            Property(
                name: "Av. Brigadeiro Faria Lima",
                group: .orange,
                price: 200,
                houseCost: 100,
                baseRent: 16,
                rentWithColorGroup: 32,
                rentWith1House: 80,
                rentWith2Houses: 220,
                rentWith3Houses: 600,
                rentWith4Houses: 800,
                rentWithHotel: 1000
            ),
            
            // MARK: Bairro 5 (Vermelho)
            Property(
                name: "Av. N. S. de Copacabana",
                group: .red,
                price: 220,
                houseCost: 150,
                baseRent: 18,
                rentWithColorGroup: 36,
                rentWith1House: 90,
                rentWith2Houses: 250,
                rentWith3Houses: 700,
                rentWith4Houses: 875,
                rentWithHotel: 1050
            ),
            Property(
                name: "Av. Brig. Luís Antônio",
                group: .red,
                price: 220,
                houseCost: 150,
                baseRent: 18,
                rentWithColorGroup: 36,
                rentWith1House: 90,
                rentWith2Houses: 250,
                rentWith3Houses: 700,
                rentWith4Houses: 875,
                rentWithHotel: 1050
            ),
            Property(
                name: "Av. Paulista",
                group: .red,
                price: 240,
                houseCost: 150,
                baseRent: 20,
                rentWithColorGroup: 40,
                rentWith1House: 100,
                rentWith2Houses: 300,
                rentWith3Houses: 750,
                rentWith4Houses: 925,
                rentWithHotel: 1100
            ),
            
            // MARK: Bairro 6 (Amarelo)
            Property(
                name: "Ipanema",
                group: .yellow,
                price: 260,
                houseCost: 150,
                baseRent: 22,
                rentWithColorGroup: 44,
                rentWith1House: 110,
                rentWith2Houses: 330,
                rentWith3Houses: 800,
                rentWith4Houses: 975,
                rentWithHotel: 1150
            ),
            Property(
                name: "Leblon",
                group: .yellow,
                price: 260,
                houseCost: 150,
                baseRent: 22,
                rentWithColorGroup: 44,
                rentWith1House: 110,
                rentWith2Houses: 330,
                rentWith3Houses: 800,
                rentWith4Houses: 975,
                rentWithHotel: 1150
            ),
            Property(
                name: "Flamengo",
                group: .yellow,
                price: 280,
                houseCost: 150,
                baseRent: 24,
                rentWithColorGroup: 48,
                rentWith1House: 120,
                rentWith2Houses: 360,
                rentWith3Houses: 850,
                rentWith4Houses: 1025,
                rentWithHotel: 1200
            ),
            
            // MARK: Bairro 7 (Verde)
            Property(
                name: "Botafogo",
                group: .green,
                price: 300,
                houseCost: 200,
                baseRent: 26,
                rentWithColorGroup: 52,
                rentWith1House: 130,
                rentWith2Houses: 390,
                rentWith3Houses: 900,
                rentWith4Houses: 1100,
                rentWithHotel: 1275
            ),
            Property(
                name: "Morumbi",
                group: .green,
                price: 300,
                houseCost: 200,
                baseRent: 26,
                rentWithColorGroup: 52,
                rentWith1House: 130,
                rentWith2Houses: 390,
                rentWith3Houses: 900,
                rentWith4Houses: 1100,
                rentWithHotel: 1275
            ),
            Property(
                name: "Jardim Botânico",
                group: .green,
                price: 320,
                houseCost: 200,
                baseRent: 28,
                rentWithColorGroup: 56,
                rentWith1House: 150,
                rentWith2Houses: 450,
                rentWith3Houses: 1000,
                rentWith4Houses: 1200,
                rentWithHotel: 1400
            ),
            
            // MARK: Bairro 8 (Azul Escuro)
            Property(
                name: "Av. Brasil",
                group: .darkBlue,
                price: 350,
                houseCost: 200,
                baseRent: 35,
                rentWithColorGroup: 70,
                rentWith1House: 175,
                rentWith2Houses: 500,
                rentWith3Houses: 1100,
                rentWith4Houses: 1300,
                rentWithHotel: 1500
            ),
            Property(
                name: "Av. Atlântica",
                group: .darkBlue,
                price: 400,
                houseCost: 200,
                baseRent: 50,
                rentWithColorGroup: 100,
                rentWith1House: 200,
                rentWith2Houses: 600,
                rentWith3Houses: 1400,
                rentWith4Houses: 1700,
                rentWithHotel: 2000
            ),
            
            // MARK: Companhias de Serviços Públicos
            Property(
                name: "Cia. de Eletricidade",
                group: .company,
                price: 150,
                houseCost: 0,
                baseRent: 50,
                rentWith1House: 100,
                rentWith2Houses: 150,
                rentWith3Houses: 200,
                rentWith4Houses: 250,
                rentWithHotel: 300
            ),
            Property(
                name: "Cia. de Água e Saneamento",
                group: .company,
                price: 150,
                houseCost: 0,
                baseRent: 50,
                rentWith1House: 100,
                rentWith2Houses: 150,
                rentWith3Houses: 200,
                rentWith4Houses: 250,
                rentWithHotel: 300
            ),
            Property(
                name: "Cia. Ferroviária",
                group: .company,
                price: 150,
                houseCost: 0,
                baseRent: 50,
                rentWith1House: 100,
                rentWith2Houses: 150,
                rentWith3Houses: 200,
                rentWith4Houses: 250,
                rentWithHotel: 300
            ),
            Property(
                name: "Cia. de Aviação",
                group: .company,
                price: 200,
                houseCost: 0,
                baseRent: 50,
                rentWith1House: 100,
                rentWith2Houses: 150,
                rentWith3Houses: 200,
                rentWith4Houses: 250,
                rentWithHotel: 300
            ),
            Property(
                name: "Cia. de Táxi Aéreo",
                group: .company,
                price: 150,
                houseCost: 0,
                baseRent: 50,
                rentWith1House: 100,
                rentWith2Houses: 150,
                rentWith3Houses: 200,
                rentWith4Houses: 250,
                rentWithHotel: 300
            ),
            Property(
                name: "Cia. de Navegação",
                group: .company,
                price: 150,
                houseCost: 0,
                baseRent: 50,
                rentWith1House: 100,
                rentWith2Houses: 150,
                rentWith3Houses: 200,
                rentWith4Houses: 250,
                rentWithHotel: 300
            )
        ]
    }
}
