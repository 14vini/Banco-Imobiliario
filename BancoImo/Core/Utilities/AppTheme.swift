//
//  AppTheme.swift
//  BancoImo
//
//  Created by iOS Senior Developer.
//

import SwiftUI
import UIKit

/// Paleta de cores Playful Game / Neo-Brutalist inspirada na identidade visual de jogos de tabuleiro modernos (estilo MyWallet).
enum AppTheme {
    // MARK: - Cores Primárias da Identidade Visual
    
    /// Azul Periwinkle / Lavanda vibrante característico da tela de Cards
    static let gamePeriwinkle = Color(red: 0.44, green: 0.52, blue: 0.87)
    
    /// Amarelo Ouro Solar das moedas de ação e cards principais
    static let gameYellow = Color(red: 0.99, green: 0.72, blue: 0.20)
    
    /// Coral / Salmão lúdico para despesas, barras e falência
    static let gameCoral = Color(red: 0.94, green: 0.40, blue: 0.33)
    
    /// Verde Folha / Menta para receitas e salários
    static let gameGreen = Color(red: 0.38, green: 0.79, blue: 0.44)
    
    /// Lavanda Suave para detalhes secundários
    static let gameLavender = Color(red: 0.71, green: 0.76, blue: 0.96)
    
    /// Contorno preto/carvão expressivo dos botões e cards (Neo-Brutalism)
    static let strokeBlack = Color(red: 0.11, green: 0.11, blue: 0.13)
    
    // MARK: - Cores Dinâmicas Adaptativas (Light / Dark)
    
    /// Fundo geral da tela (Light: Azul Periwinkle vibrante / Dark: Midnight Periwinkle profundo)
    static var canvasBackground: Color {
        Color(uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.10, green: 0.13, blue: 0.22, alpha: 1.0)
            : UIColor(red: 0.44, green: 0.52, blue: 0.87, alpha: 1.0)
        })
    }
    
    /// Fundo dos cards e contêineres secundários (Light: Branco puro / Dark: Midnight Card)
    static var cardBackground: Color {
        Color(uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.15, green: 0.18, blue: 0.28, alpha: 1.0)
            : UIColor.white
        })
    }
    
    /// Cor do texto principal em superfícies brancas/claras
    static var textPrimary: Color {
        Color(uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
            ? UIColor.white
            : UIColor(red: 0.10, green: 0.10, blue: 0.12, alpha: 1.0)
        })
    }
    
    /// Cor do texto secundário atenuado
    static var textSecondary: Color {
        Color(uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
            ? UIColor(white: 0.75, alpha: 1.0)
            : UIColor(red: 0.35, green: 0.38, blue: 0.45, alpha: 1.0)
        })
    }
    
    /// Texto claro sobre o fundo azul/escuro
    static var textOnCanvas: Color {
        .white
    }
    
    /// Bordas sutis adaptativas
    static var borderSubtle: Color {
        strokeBlack.opacity(0.18)
    }
    
    /// Bordas fortes estilo Neo-Brutalist
    static var borderStrong: Color {
        strokeBlack
    }
    
    // MARK: - Cores Semânticas Dedicadas para Ações 3D (Reconhecimento Instantâneo)
    
    /// 🟢 VERDE ESMERALDA = Receber Salário / Início (+2.000)
    static let actionGreen = Color(red: 0.18, green: 0.80, blue: 0.44)
    static let actionGreenDark = Color(red: 0.14, green: 0.65, blue: 0.35)
    static var actionGreenGradient: LinearGradient {
        LinearGradient(
            colors: [Color(red: 0.22, green: 0.86, blue: 0.48), Color(red: 0.15, green: 0.72, blue: 0.38)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    /// 🔴 CORAL / VERMELHO VIBRANTE = Pagar / Transferir / Despesas
    static let actionCoral = Color(red: 1.0, green: 0.28, blue: 0.34)
    static let actionCoralDark = Color(red: 0.86, green: 0.18, blue: 0.24)
    static var actionCoralGradient: LinearGradient {
        LinearGradient(
            colors: [Color(red: 1.0, green: 0.38, blue: 0.44), Color(red: 0.90, green: 0.20, blue: 0.26)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    /// 🟡 AMARELO OURO SOLAR = Rolar Dados 3D / Sorte do Turno
    static let actionYellow = Color(red: 1.0, green: 0.68, blue: 0.05)
    static let actionYellowDark = Color(red: 0.88, green: 0.54, blue: 0.0)
    static var actionYellowGradient: LinearGradient {
        LinearGradient(
            colors: [Color(red: 1.0, green: 0.78, blue: 0.18), Color(red: 0.98, green: 0.62, blue: 0.02)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    /// 🟣 ROXO NEON / ÍNDIGO = Extrato Geral & Gráficos Analíticos
    static let actionPurple = Color(red: 0.46, green: 0.31, blue: 0.91)
    static let actionPurpleDark = Color(red: 0.35, green: 0.22, blue: 0.75)
    static var actionPurpleGradient: LinearGradient {
        LinearGradient(
            colors: [Color(red: 0.54, green: 0.38, blue: 0.98), Color(red: 0.40, green: 0.25, blue: 0.84)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    /// 🔵 AZUL ROYAL / OCEANO = Gestão de Imóveis & Títulos de Propriedade
    static let actionBlue = Color(red: 0.18, green: 0.52, blue: 0.98)
    static let actionBlueDark = Color(red: 0.10, green: 0.36, blue: 0.78)
    static var actionBlueGradient: LinearGradient {
        LinearGradient(
            colors: [Color(red: 0.28, green: 0.65, blue: 1.0), Color(red: 0.12, green: 0.44, blue: 0.94)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    /// ⚪ BRANCO PÉROLA = Controles de Mesa / Neutros
    static let actionWhite = Color.white
    static let actionWhiteDark = Color(red: 0.82, green: 0.84, blue: 0.88)
    
    // MARK: - Aliases de Compatibilidade
    
    static var limeAccent: Color {
        actionYellow
    }
    
    static var limeSoft: Color {
        actionYellow.opacity(0.25)
    }
    
    static var charcoalBlack: Color {
        textPrimary
    }
    
    static var darkCard: Color {
        Color(red: 0.14, green: 0.16, blue: 0.22)
    }
    
    static var darkCardGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.16, green: 0.18, blue: 0.26),
                Color(red: 0.10, green: 0.12, blue: 0.18)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Gradientes dos Cartões Físicos
    
    /// Gradiente branco puro com toque pérola para o cartão flutuante
    static var cardPearlGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.white,
                Color(red: 0.96, green: 0.97, blue: 0.99)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    /// Gradiente ouro solar
    static var goldGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 1.0, green: 0.78, blue: 0.28),
                Color(red: 0.98, green: 0.65, blue: 0.15)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
