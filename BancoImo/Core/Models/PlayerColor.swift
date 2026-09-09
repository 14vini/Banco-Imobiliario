//
//  PlayerColor.swift
//  BancoImo
//
//  Created by iOS Senior Developer.
//

import SwiftUI

/// Cores disponíveis para identificar visualmente cada jogador na mesa.
enum PlayerColor: String, Codable, CaseIterable, Identifiable, Equatable, Hashable {
    case red = "red"
    case blue = "blue"
    case green = "green"
    case yellow = "yellow"
    case purple = "purple"
    case orange = "orange"
    case cyan = "cyan"
    case pink = "pink"
    
    var id: String { rawValue }
    
    /// Nome amigável em português para exibição e acessibilidade.
    var displayName: String {
        switch self {
        case .red: return "Vermelho"
        case .blue: return "Azul"
        case .green: return "Verde"
        case .yellow: return "Amarelo"
        case .purple: return "Roxo"
        case .orange: return "Laranja"
        case .cyan: return "Ciano"
        case .pink: return "Rosa"
        }
    }
    
    /// Cor nativa correspondente no SwiftUI.
    var color: Color {
        switch self {
        case .red: return Color.red
        case .blue: return Color.blue
        case .green: return Color.green
        case .yellow: return Color.yellow
        case .purple: return Color.purple
        case .orange: return Color.orange
        case .cyan: return Color.cyan
        case .pink: return Color.pink
        }
    }
    
    /// Código Hexadecimal correspondente para persistência ou estilização customizada.
    var hexCode: String {
        switch self {
        case .red: return "#FF3B30"
        case .blue: return "#007AFF"
        case .green: return "#34C759"
        case .yellow: return "#FFCC00"
        case .purple: return "#AF52DE"
        case .orange: return "#FF9500"
        case .cyan: return "#32ADE6"
        case .pink: return "#FF2D55"
        }
    }
    
    // MARK: - Estilização Visual do Cartão 3D (Hero Card)
    
    /// Gradiente de alta vibração e contraste para o corpo do cartão 3D.
    var cardGradient: LinearGradient {
        switch self {
        case .red:
            return LinearGradient(
                colors: [Color(red: 0.96, green: 0.26, blue: 0.26), Color(red: 0.76, green: 0.08, blue: 0.12)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .blue:
            return LinearGradient(
                colors: [Color(red: 0.22, green: 0.54, blue: 0.98), Color(red: 0.08, green: 0.28, blue: 0.84)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .green:
            return LinearGradient(
                colors: [Color(red: 0.18, green: 0.80, blue: 0.44), Color(red: 0.06, green: 0.54, blue: 0.26)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .yellow:
            return LinearGradient(
                colors: [Color(red: 1.0, green: 0.86, blue: 0.22), Color(red: 0.96, green: 0.70, blue: 0.08)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .purple:
            return LinearGradient(
                colors: [Color(red: 0.68, green: 0.36, blue: 0.94), Color(red: 0.46, green: 0.14, blue: 0.76)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .orange:
            return LinearGradient(
                colors: [Color(red: 1.0, green: 0.60, blue: 0.14), Color(red: 0.88, green: 0.38, blue: 0.04)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .cyan:
            return LinearGradient(
                colors: [Color(red: 0.18, green: 0.76, blue: 0.94), Color(red: 0.06, green: 0.52, blue: 0.78)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .pink:
            return LinearGradient(
                colors: [Color(red: 1.0, green: 0.32, blue: 0.56), Color(red: 0.84, green: 0.08, blue: 0.36)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    /// Cor escura correspondente para a camada de profundidade chanfrada 3D.
    var cardDepthColor: Color {
        switch self {
        case .red: return Color(red: 0.46, green: 0.04, blue: 0.06)
        case .blue: return Color(red: 0.04, green: 0.14, blue: 0.48)
        case .green: return Color(red: 0.03, green: 0.32, blue: 0.14)
        case .yellow: return Color(red: 0.66, green: 0.44, blue: 0.02)
        case .purple: return Color(red: 0.28, green: 0.06, blue: 0.48)
        case .orange: return Color(red: 0.56, green: 0.20, blue: 0.02)
        case .cyan: return Color(red: 0.02, green: 0.30, blue: 0.50)
        case .pink: return Color(red: 0.52, green: 0.04, blue: 0.20)
        }
    }
    
    /// Cor do texto principal do cartão para contraste nítido e legível.
    var cardTextColor: Color {
        switch self {
        case .yellow:
            return AppTheme.strokeBlack
        default:
            return Color.white
        }
    }
    
    /// Cor do texto secundário do cartão.
    var cardSubtextColor: Color {
        switch self {
        case .yellow:
            return Color.black.opacity(0.70)
        default:
            return Color.white.opacity(0.88)
        }
    }
    
    /// Cor de contorno da marca no topo do cartão.
    var cardBrandAccentColor: Color {
        switch self {
        case .yellow:
            return AppTheme.strokeBlack
        default:
            return Color.white
        }
    }
}
