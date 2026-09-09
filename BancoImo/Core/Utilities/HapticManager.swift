//
//  HapticManager.swift
//  BancoImo
//
//  Created by iOS Senior Developer.
//

import UIKit

/// Gerenciador centralizado de feedback tátil (Haptics) para interações no aplicativo.
enum HapticManager {
    /// Dispara uma resposta de impacto tátil (leve, médio ou pesado).
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
    
    /// Dispara uma notificação tátil de sucesso, erro ou alerta.
    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
    
    /// Dispara feedback de seleção (útil para seletores e chips).
    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }
}
