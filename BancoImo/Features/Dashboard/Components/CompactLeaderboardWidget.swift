//
//  CompactLeaderboardWidget.swift
//  BancoImo
//
//  Created by iOS Senior Developer.
//

import SwiftUI

/// Widget compacto posicionado ao lado do Cartão 3D que exibe os saldos de todos os jogadores
/// e destaca visualmente quem está ganhando a partida em tempo real.
struct CompactLeaderboardWidget: View {
    let players: [Player]
    var properties: [Property] = []
    let selectedPlayerId: UUID?
    let onSelectPlayer: (Player) -> Void
    
    // Jogadores ordenados por maior saldo
    private var rankedPlayers: [Player] {
        players.sorted { p1, p2 in
            if p1.isBankrupt != p2.isBankrupt {
                return !p1.isBankrupt // Não-falidos primeiro
            }
            return p1.balance > p2.balance
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // MARK: - Cabeçalho do Placar
            HStack(spacing: 6) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(AppTheme.actionYellow)
                
                Text("PLACAR DA MESA")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundStyle(Color.white)
                    .tracking(0.8)
                
                Spacer()
                
                if let leader = rankedPlayers.first, !leader.isBankrupt {
                    HStack(spacing: 4) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(AppTheme.strokeBlack)
                        Text(leader.name)
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .foregroundStyle(AppTheme.strokeBlack)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2.5)
                    .background(AppTheme.actionYellow)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(AppTheme.strokeBlack, lineWidth: 1)
                    )
                }
            }
            .padding(.horizontal, 4)
            .padding(.top, 2)
            
            // MARK: - Lista de Saldos dos Jogadores
            VStack(spacing: 5) {
                ForEach(Array(rankedPlayers.enumerated()), id: \.element.id) { index, player in
                    let isLeader = index == 0 && !player.isBankrupt
                    let isSelected = selectedPlayerId == player.id
                    
                    Button {
                        HapticManager.selection()
                        SoundManager.play(.buttonTap)
                        onSelectPlayer(player)
                    } label: {
                        HStack(spacing: 8) {
                            // Posição no Ranking / Coroa
                            ZStack {
                                Circle()
                                    .fill(isLeader ? AppTheme.actionYellow : Color.white.opacity(0.18))
                                    .frame(width: 20, height: 20)
                                    .overlay(
                                        Circle().stroke(AppTheme.strokeBlack, lineWidth: isLeader ? 1.2 : 0.8)
                                    )
                                
                                if isLeader {
                                    Image(systemName: "crown.fill")
                                        .font(.system(size: 9, weight: .black))
                                        .foregroundStyle(AppTheme.strokeBlack)
                                } else {
                                    Text("\(index + 1)º")
                                        .font(.system(size: 9, weight: .black, design: .rounded))
                                        .foregroundStyle(Color.white)
                                }
                            }
                            
                            // Avatar Token
                            Circle()
                                .fill(player.color.color)
                                .frame(width: 14, height: 14)
                                .overlay(
                                    Circle().stroke(AppTheme.strokeBlack, lineWidth: 1.2)
                                )
                            
                            // Nome e Tag Ganhando
                            HStack(spacing: 4) {
                                Text(player.name)
                                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                                    .foregroundStyle(Color.white)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                                
                                let propCount = properties.filter { $0.ownerId == player.id }.count
                                if propCount > 0 {
                                    HStack(spacing: 2) {
                                        Image(systemName: "building.2.fill")
                                            .font(.system(size: 7))
                                        Text("\(propCount)")
                                            .font(.system(size: 8, weight: .black))
                                    }
                                    .foregroundStyle(Color.white.opacity(0.9))
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 1)
                                    .background(Color.white.opacity(0.18))
                                    .clipShape(Capsule())
                                }
                                
                                if isLeader {
                                    Text("LÍDER")
                                        .font(.system(size: 8, weight: .black))
                                        .foregroundStyle(AppTheme.strokeBlack)
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 1.5)
                                        .background(AppTheme.actionYellow)
                                        .clipShape(Capsule())
                                }
                                
                                if player.isBankrupt {
                                    Text("FALIDO")
                                        .font(.system(size: 8, weight: .black))
                                        .foregroundStyle(Color.white)
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 1.5)
                                        .background(AppTheme.actionCoral)
                                        .clipShape(Capsule())
                                }
                            }
                            
                            Spacer()
                            
                            // Saldo
                            Text(player.balance.asCurrency)
                                .font(.system(size: 13, weight: .heavy, design: .rounded))
                                .foregroundStyle(
                                    player.isBankrupt
                                    ? Color.white.opacity(0.4)
                                    : (isLeader ? AppTheme.actionYellow : Color.white)
                                )
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(
                            isSelected
                            ? Color.white.opacity(0.28)
                            : (isLeader ? Color.black.opacity(0.32) : Color.black.opacity(0.16))
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(
                                    isSelected
                                    ? Color.white
                                    : (isLeader ? AppTheme.actionYellow.opacity(0.5) : Color.white.opacity(0.08)),
                                    lineWidth: isSelected ? 1.5 : 1
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .top)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(red: 0.12, green: 0.15, blue: 0.24).opacity(0.92))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(AppTheme.strokeBlack, lineWidth: 1.8)
        )
        .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 3)
    }
}
