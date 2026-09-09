//
//  PlayerDashboardCard.swift
//  BancoImo
//
//  Created by iOS Senior Developer.
//

import SwiftUI

/// Card individual de jogador para a mesa com suporte a ações rápidas 3D táteis diretas, ranking e estética Neo-Brutalist física.
struct PlayerDashboardCard: View {
    let player: Player
    var properties: [Property] = []
    let rank: Int?
    let isSelected: Bool
    let onSelect: () -> Void
    let onQuickAddSalary: () -> Void
    let onOpenActions: () -> Void
    let onToggleBankruptcy: () -> Void
    
    // Propriedades do jogador
    private var playerProperties: [Property] {
        properties.filter { $0.ownerId == player.id }
    }
    
    private var playerHousesCount: Int {
        playerProperties.filter { $0.housesCount < 5 }.reduce(0) { $0 + $1.housesCount }
    }
    
    private var playerHotelsCount: Int {
        playerProperties.filter { $0.housesCount == 5 }.count
    }
    
    private var netWorth: Decimal {
        var total: Decimal = player.balance
        for p in playerProperties {
            let base = p.isMortgaged ? (p.price * 0.5) : p.price
            let bld = Decimal(p.housesCount) * p.houseCost
            total += (base + bld)
        }
        return total
    }
    
    var body: some View {
        Button(action: {
            SoundManager.play(.buttonTap)
            HapticManager.impact(.light)
            onSelect()
        }) {
            // Corpo do Cartão
            VStack(spacing: 12) {
                // MARK: - Linha Superior: Rank, Avatar 3D, Nome e Saldo
                HStack(spacing: 10) {
                    // Posição no Ranking
                    if let rank = rank, !player.isBankrupt {
                        HStack(spacing: 2) {
                            if rank == 1 {
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 11))
                                    .foregroundStyle(AppTheme.actionYellow)
                            }
                            Text("\(rank)º")
                                .font(.system(size: 12, weight: .black, design: .rounded))
                                .foregroundStyle(rank == 1 ? AppTheme.strokeBlack : AppTheme.textSecondary)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(rank == 1 ? AppTheme.actionYellow : Color.black.opacity(0.06))
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().stroke(AppTheme.strokeBlack, lineWidth: rank == 1 ? 1.5 : 1)
                        )
                    }
                    
                    // Avatar 3D Token com Relevo
                    ZStack {
                        // Base de profundidade
                        Circle()
                            .fill(player.isBankrupt ? Color.gray : player.color.color.opacity(0.8))
                            .frame(width: 42, height: 42)
                            .offset(y: 2)
                        
                        // Face do Token
                        Circle()
                            .fill(player.isBankrupt ? Color.gray.gradient : player.color.color.gradient)
                            .frame(width: 42, height: 42)
                            .overlay(
                                Circle().stroke(AppTheme.strokeBlack, lineWidth: 2)
                            )
                            .overlay(
                                Circle()
                                    .strokeBorder(Color.white.opacity(0.4), lineWidth: 1.5)
                                    .padding(1.5)
                            )
                        
                        Text(String(player.name.prefix(1)).uppercased())
                            .font(.system(size: 17, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .shadow(color: Color.black.opacity(0.3), radius: 1, x: 0, y: 1)
                    }
                    
                    // Nome e Cor
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Text(player.name)
                                .font(.system(size: 15, weight: .black, design: .rounded))
                                .foregroundStyle(player.isBankrupt ? .secondary : AppTheme.textPrimary)
                                .strikethrough(player.isBankrupt, color: .red)
                                .lineLimit(1)
                            
                            if isSelected && !player.isBankrupt {
                                Text("VEZ")
                                    .font(.system(size: 8, weight: .black))
                                    .foregroundStyle(AppTheme.strokeBlack)
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 2)
                                    .background(AppTheme.actionYellow)
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule().stroke(AppTheme.strokeBlack, lineWidth: 1)
                                    )
                            }
                        }
                        
                        HStack(spacing: 6) {
                            Text(player.color.displayName)
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(AppTheme.textSecondary)
                            
                            if let deviceName = MultipeerGameService.shared.claimedPlayerDeviceMap[player.id] {
                                HStack(spacing: 2.5) {
                                    Circle()
                                        .fill(AppTheme.actionGreen)
                                        .frame(width: 5, height: 5)
                                    Text("📱 \(deviceName)")
                                        .font(.system(size: 8.5, weight: .black, design: .rounded))
                                        .lineLimit(1)
                                }
                                .foregroundStyle(AppTheme.strokeBlack)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1.5)
                                .background(AppTheme.actionGreen.opacity(0.2))
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(AppTheme.strokeBlack.opacity(0.3), lineWidth: 0.8))
                            }
                            
                            if !playerProperties.isEmpty {
                                HStack(spacing: 4) {
                                    HStack(spacing: 1.5) {
                                        Image(systemName: "building.2.fill")
                                            .font(.system(size: 8))
                                        Text("\(playerProperties.count)")
                                            .font(.system(size: 8.5, weight: .black))
                                    }
                                    if playerHousesCount > 0 {
                                        Text("🏠\(playerHousesCount)")
                                            .font(.system(size: 8.5, weight: .bold))
                                    }
                                    if playerHotelsCount > 0 {
                                        Text("🏨\(playerHotelsCount)")
                                            .font(.system(size: 8.5, weight: .bold))
                                    }
                                }
                                .foregroundStyle(AppTheme.strokeBlack)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1.5)
                                .background(AppTheme.actionBlue.opacity(0.18))
                                .clipShape(Capsule())
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Saldo e Patrimônio
                    VStack(alignment: .trailing, spacing: 1) {
                        Text(player.balance.asCurrency)
                            .font(.system(size: 17, weight: .heavy, design: .rounded))
                            .foregroundStyle(
                                player.isBankrupt
                                ? Color.secondary
                                : (player.balance >= 0 ? AppTheme.textPrimary : Color.red)
                            )
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        
                        if !playerProperties.isEmpty && !player.isBankrupt {
                            Text("Patr: \(netWorth.asCurrency)")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundStyle(AppTheme.textSecondary)
                                .lineLimit(1)
                        } else if player.isBankrupt {
                            Text("FALIDO")
                                .font(.system(size: 9, weight: .black))
                                .foregroundStyle(AppTheme.actionCoral)
                        }
                    }
                }
                
                // MARK: - Botões Táteis 3D com Cores Dedicadas
                if !player.isBankrupt {
                    HStack(spacing: 8) {
                        // 🟢 Botão Verde 3D: Receber +2.000 Início
                        Tactile3DButton(
                            faceGradient: AppTheme.actionGreenGradient,
                            depthColor: AppTheme.actionGreenDark,
                            cornerRadius: 12,
                            depth: 4.0,
                            strokeWidth: 1.8,
                            highlightColor: Color.white.opacity(0.4),
                            action: onQuickAddSalary
                        ) {
                            HStack(spacing: 4) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 11, weight: .heavy))
                                Text("+2.000")
                                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                            }
                            .foregroundStyle(Color.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 7)
                        }
                        
                        // 🔴 Botão Coral 3D: Pagar / Transferir
                        Tactile3DButton(
                            faceGradient: AppTheme.actionCoralGradient,
                            depthColor: AppTheme.actionCoralDark,
                            cornerRadius: 12,
                            depth: 4.0,
                            strokeWidth: 1.8,
                            highlightColor: Color.white.opacity(0.4),
                            action: onOpenActions
                        ) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 10, weight: .heavy))
                                Text("Pagar")
                                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                            }
                            .foregroundStyle(Color.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 7)
                        }
                    }
                } else {
                    // Botão Reativar
                    Tactile3DButton(
                        faceGradient: AppTheme.actionGreenGradient,
                        depthColor: AppTheme.actionGreenDark,
                        cornerRadius: 12,
                        depth: 4.0,
                        strokeWidth: 1.8,
                        highlightColor: Color.white.opacity(0.4),
                        action: onToggleBankruptcy
                    ) {
                        Text("Reativar Jogador")
                            .font(.caption.weight(.heavy))
                            .foregroundStyle(Color.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 7)
                    }
                }
            }
            .padding(12)
            .background(
                isSelected && !player.isBankrupt
                ? AnyShapeStyle(player.color.color.opacity(0.07))
                : AnyShapeStyle(AppTheme.cardBackground)
            )
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(
                        isSelected ? AppTheme.strokeBlack : AppTheme.strokeBlack.opacity(0.18),
                        lineWidth: isSelected ? 2.5 : 1.5
                    )
            )
            .shadow(
                color: Color.black.opacity(isSelected ? 0.16 : 0.06),
                radius: isSelected ? 6 : 3,
                x: 0,
                y: isSelected ? 3 : 2
            )
            .opacity(player.isBankrupt ? 0.6 : 1.0)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                onQuickAddSalary()
            } label: {
                Label("Adicionar +2.000 (Início)", systemImage: "plus.circle")
            }
            
            Button {
                onOpenActions()
            } label: {
                Label("Abrir Operações", systemImage: "dollarsign.arrow.circlepath")
            }
            
            Divider()
            
            Button(role: player.isBankrupt ? .none : .destructive) {
                onToggleBankruptcy()
            } label: {
                Label(
                    player.isBankrupt ? "Reativar Jogador" : "Declarar Falência",
                    systemImage: player.isBankrupt ? "checkmark.circle" : "xmark.octagon"
                )
            }
        }
    }
}

#Preview {
    VStack(spacing: 14) {
        PlayerDashboardCard(
            player: Player(name: "Kauã Vinícius", balance: 3200, color: .blue),
            rank: 1,
            isSelected: true,
            onSelect: {},
            onQuickAddSalary: {},
            onOpenActions: {},
            onToggleBankruptcy: {}
        )
        PlayerDashboardCard(
            player: Player(name: "Mariana Souza", balance: 1400, color: .purple),
            rank: 2,
            isSelected: false,
            onSelect: {},
            onQuickAddSalary: {},
            onOpenActions: {},
            onToggleBankruptcy: {}
        )
    }
    .padding()
    .background(AppTheme.gamePeriwinkle)
}

