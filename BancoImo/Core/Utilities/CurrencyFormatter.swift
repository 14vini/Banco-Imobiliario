//
//  CurrencyFormatter.swift
//  BancoImo
//
//  Created by iOS Senior Developer.
//

import Foundation

/// Utilitário centralizado para formatação de valores monetários.
enum CurrencyFormatter {
    private static let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter
    }()
    
    /// Formata um valor Decimal para o padrão de moeda brasileiro (ex: R$ 1.500 ou R$ 1.500,50).
    static func format(_ value: Decimal) -> String {
        return formatter.string(from: value as NSDecimalNumber) ?? "R$ \(value)"
    }
}

extension Decimal {
    /// Formata o valor Decimal como moeda brasileira.
    var asCurrency: String {
        CurrencyFormatter.format(self)
    }
}
