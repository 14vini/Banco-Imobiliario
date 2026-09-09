//
//  PlayfulHeroCardView.swift
//  BancoImo
//
//  Created by iOS Senior Developer.
//

import SwiftUI

/// Cartão físico 3D flutuante do caixa do jogador ativo com perspectiva espacial realista,
/// acabamento cerâmico perolado, chip EMV dourado, brilho especular e seletor de mesa integrado.
struct PlayfulHeroCardView: View {
    let player: Player
    let players: [Player]
    var properties: [Property] = []
    let onSelectPlayer: (Player) -> Void
    let onOpenCardActions: () -> Void
    
    // Estado de toque e inclinação tátil interativa
    @State private var isPressed: Bool = false
    @State private var dragOffset: CGSize = .zero
    
    // Propriedades do jogador ativo
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
    
    // Verifica se este jogador é o mais rico da mesa
    private var isLeader: Bool {
        guard !player.isBankrupt else { return false }
        let maxBalance = players.filter { !$0.isBankrupt }.map(\.balance).max() ?? 0
        return player.balance == maxBalance && players.count > 1
    }
    
    var body: some View {
        VStack(spacing: 14) {
            // MARK: - 1. Cartão Físico 3D do Caixa (Toque para Abrir Transações)
            Button(action: {
                SoundManager.play(.buttonTap)
                HapticManager.impact(.medium)
                onOpenCardActions()
            }) {
                ZStack(alignment: .bottomTrailing) {
                    // Sombra de Projeção no Tabuleiro (Ambient Drop Shadow)
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color.black.opacity(0.18))
                        .frame(maxWidth: 360)
                        .frame(height: 196)
                        .offset(x: 10, y: 14)
                        .blur(radius: 10)
                    
                    // Camada de Extrusão 3D Mecânica (Borda Inferior Escura Chanfrada da Cor do Jogador)
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(
                            player.isBankrupt
                            ? LinearGradient(colors: [Color(red: 0.16, green: 0.17, blue: 0.20), Color(red: 0.10, green: 0.11, blue: 0.14)], startPoint: .topLeading, endPoint: .bottomTrailing)
                            : LinearGradient(colors: [player.color.cardDepthColor, player.color.cardDepthColor.opacity(0.9)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .frame(maxWidth: 360)
                        .frame(height: 196)
                        .offset(x: 5, y: 6)
                    
                    // Corpo Principal do Cartão 3D (Cor Dinâmica do Jogador)
                    ZStack {
                        // Fundo Gradiente Vibrante da Cor do Jogador
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(
                                player.isBankrupt
                                ? LinearGradient(colors: [Color(red: 0.38, green: 0.40, blue: 0.46), Color(red: 0.24, green: 0.26, blue: 0.30)], startPoint: .topLeading, endPoint: .bottomTrailing)
                                : player.color.cardGradient
                            )
                        
                        // Brilho Holográfico Diagonal / Reflexo Especular de Luz
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.35),
                                        Color.clear,
                                        Color.white.opacity(0.12)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        // Bisel Especular de Borda Superior (Reflexo de Vidro 3D)
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.65),
                                        Color.white.opacity(0.15),
                                        Color.clear
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                            .padding(1)
                        
                        // Moldura Neo-Brutalist Fina e Precisa
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(AppTheme.strokeBlack, lineWidth: 2.0)
                        
                        // Conteúdo Interno Estruturado do Cartão
                        VStack(alignment: .leading, spacing: 0) {
                            // MARK: Top Bar (Identidade do Banco + Chip EMV + Transmissão)
                            HStack(alignment: .center) {
                                HStack(spacing: 6) {
                                    Image(systemName: "banknote.fill")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(player.color.cardTextColor)
                                    
                                    Text("BANCO IMOBILIÁRIO")
                                        .font(.system(size: 10, weight: .black, design: .rounded))
                                        .foregroundStyle(player.color.cardTextColor)
                                        .tracking(1.2)
                                    
                                    Image(systemName: "wave.3.forward")
                                        .font(.system(size: 8, weight: .bold))
                                        .foregroundStyle(player.color.cardSubtextColor)
                                }
                                
                                Spacer()
                                
                                // Chip EMV Dourado de Alta Definição
                                emvSmartChipView
                            }
                            
                            Spacer()
                            
                            // MARK: Saldo em Destaque Harmônico (Caixa do Jogador)
                            VStack(alignment: .leading, spacing: 3) {
                                HStack(spacing: 6) {
                                    Text("SALDO EM CAIXA")
                                        .font(.system(size: 9, weight: .black, design: .rounded))
                                        .foregroundStyle(player.color.cardSubtextColor)
                                        .tracking(1)
                                    
                                    if isLeader {
                                        HStack(spacing: 3) {
                                             Image(systemName: "crown.fill")
                                                 .font(.system(size: 8))
                                             Text("LÍDER")
                                                 .font(.system(size: 8, weight: .black))
                                         }
                                         .foregroundStyle(AppTheme.strokeBlack)
                                         .padding(.horizontal, 6)
                                         .padding(.vertical, 2)
                                         .background(AppTheme.actionYellow)
                                         .clipShape(Capsule())
                                         .overlay(Capsule().stroke(AppTheme.strokeBlack, lineWidth: 0.8))
                                     } else if player.isBankrupt {
                                         Text("FALÊNCIA")
                                             .font(.system(size: 8, weight: .black))
                                             .foregroundStyle(Color.white)
                                             .padding(.horizontal, 6)
                                             .padding(.vertical, 2)
                                             .background(AppTheme.actionCoral)
                                             .clipShape(Capsule())
                                     }
                                 }
                                 
                                 Text(player.balance.asCurrency)
                                     .font(.system(size: 30, weight: .heavy, design: .rounded))
                                     .foregroundStyle(
                                         player.isBankrupt
                                         ? Color.white.opacity(0.6)
                                         : (player.balance >= 0 ? player.color.cardTextColor : AppTheme.actionCoral)
                                     )
                                     .shadow(color: Color.black.opacity(0.18), radius: 2, x: 0, y: 1)
                                     .minimumScaleFactor(0.7)
                                     .lineLimit(1)
                                 
                                 // Indicadores de Imóveis & Patrimônio Total
                                 if !playerProperties.isEmpty {
                                     HStack(spacing: 5) {
                                         HStack(spacing: 2) {
                                             Image(systemName: "building.2.fill")
                                                 .font(.system(size: 8))
                                             Text("\(playerProperties.count)")
                                                 .font(.system(size: 9, weight: .black))
                                         }
                                         if playerHousesCount > 0 {
                                             HStack(spacing: 2) {
                                                 Text("🏠")
                                                     .font(.system(size: 8))
                                                 Text("\(playerHousesCount)")
                                                     .font(.system(size: 9, weight: .black))
                                             }
                                         }
                                         if playerHotelsCount > 0 {
                                             HStack(spacing: 2) {
                                                 Text("🏨")
                                                     .font(.system(size: 8))
                                                 Text("\(playerHotelsCount)")
                                                     .font(.system(size: 9, weight: .black))
                                             }
                                         }
                                         
                                         Text("• Patr: \(netWorth.asCurrency)")
                                             .font(.system(size: 9, weight: .bold, design: .rounded))
                                             .foregroundStyle(player.color.cardSubtextColor)
                                     }
                                     .foregroundStyle(player.color.cardTextColor)
                                     .padding(.horizontal, 6)
                                     .padding(.vertical, 2)
                                     .background(Color.white.opacity(0.16))
                                     .clipShape(Capsule())
                                 }
                            }
                            
                            Spacer()
                            
                            // MARK: Bottom Bar (Nome do Jogador + Emblema Lúdico + Dígitos)
                            HStack(alignment: .bottom) {
                                // Avatar + Nome
                                HStack(spacing: 8) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.white.opacity(0.28))
                                            .frame(width: 22, height: 22)
                                            .overlay(Circle().stroke(player.color.cardTextColor.opacity(0.6), lineWidth: 1.2))
                                        
                                        Text(String(player.name.prefix(1)).uppercased())
                                            .font(.system(size: 11, weight: .black, design: .rounded))
                                            .foregroundStyle(player.color.cardTextColor)
                                    }
                                    
                                    Text(player.name.uppercased())
                                        .font(.system(size: 13, weight: .black, design: .rounded))
                                        .foregroundStyle(player.color.cardTextColor)
                                        .lineLimit(1)
                                    
                                    if let deviceName = MultipeerGameService.shared.claimedPlayerDeviceMap[player.id] {
                                        HStack(spacing: 3) {
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
                                        .background(Color.white.opacity(0.85))
                                        .clipShape(Capsule())
                                        .overlay(Capsule().stroke(AppTheme.strokeBlack.opacity(0.3), lineWidth: 0.8))
                                    }
                                }
                                
                                Spacer()
                                
                                // Emblema de Moedas Sobrepostas (Master/Game Touch)
                                HStack(spacing: -6) {
                                    Circle()
                                        .fill(AppTheme.actionCoral.opacity(0.95))
                                        .frame(width: 18, height: 18)
                                        .overlay(Circle().stroke(AppTheme.strokeBlack, lineWidth: 1))
                                    Circle()
                                        .fill(AppTheme.actionYellow.opacity(0.95))
                                        .frame(width: 18, height: 18)
                                        .overlay(Circle().stroke(AppTheme.strokeBlack, lineWidth: 1))
                                }
                                
                                Text("•• \(String(player.id.uuidString.prefix(4)))")
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundStyle(player.color.cardSubtextColor)
                                    .padding(.leading, 4)
                            }
                        }
                        .padding(18)
                    }
                    .frame(width: 330, height: 192)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                // Perspectiva 3D Realista com Inclinação Suave
                .rotation3DEffect(
                    .degrees(isPressed ? -2 : -5),
                    axis: (x: 1.0, y: 0.1, z: 0.0),
                    perspective: 0.6
                )
                .rotation3DEffect(
                    .degrees(isPressed ? 2 : 4),
                    axis: (x: 0.0, y: 1.0, z: 0.0),
                    perspective: 0.6
                )
                .rotationEffect(.degrees(isPressed ? -2 : -4))
                .scaleEffect(isPressed ? 0.96 : 1.0)
                .animation(.spring(response: 0.35, dampingFraction: 0.75), value: player.id)
                .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isPressed)
            }
            .buttonStyle(.plain)
            
            // MARK: - 2. Seletor de Deck de Jogadores da Mesa (Pílula Lúdica Integrada)
            deckPlayerSelectorRow
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Chip Metálico EMV 3D com Linhas de Circuito
    
    private var emvSmartChipView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.98, green: 0.88, blue: 0.52),
                            Color(red: 0.88, green: 0.70, blue: 0.30)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 32, height: 24)
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(AppTheme.strokeBlack, lineWidth: 1.2)
                )
            
            // Linhas de circuito do chip
            Path { path in
                path.move(to: CGPoint(x: 0, y: 8))
                path.addLine(to: CGPoint(x: 12, y: 8))
                path.move(to: CGPoint(x: 20, y: 8))
                path.addLine(to: CGPoint(x: 32, y: 8))
                path.move(to: CGPoint(x: 0, y: 16))
                path.addLine(to: CGPoint(x: 12, y: 16))
                path.move(to: CGPoint(x: 20, y: 16))
                path.addLine(to: CGPoint(x: 32, y: 16))
                path.move(to: CGPoint(x: 16, y: 0))
                path.addLine(to: CGPoint(x: 16, y: 24))
            }
            .stroke(Color.black.opacity(0.3), lineWidth: 0.7)
            .frame(width: 32, height: 24)
        }
    }
    
    // MARK: - Seletor de Jogadores Estilo Deck de Cartas
    
    private var deckPlayerSelectorRow: some View {
        HStack(spacing: 8) {
            ForEach(players) { p in
                let isCurrent = p.id == player.id
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        onSelectPlayer(p)
                        SoundManager.play(.buttonTap)
                        HapticManager.selection()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(p.color.color.gradient)
                            .frame(width: isCurrent ? 20 : 14, height: isCurrent ? 20 : 14)
                            .overlay(Circle().stroke(AppTheme.strokeBlack, lineWidth: 1.2))
                            .shadow(color: p.color.color.opacity(isCurrent ? 0.4 : 0.1), radius: 3, y: 1)
                        
                        if isCurrent {
                            Text(p.name)
                                .font(.system(size: 11, weight: .black, design: .rounded))
                                .foregroundStyle(AppTheme.strokeBlack)
                                .lineLimit(1)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .padding(.horizontal, isCurrent ? 10 : 6)
                    .padding(.vertical, 5)
                    .background(isCurrent ? Color.white : Color.white.opacity(0.25))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(isCurrent ? AppTheme.strokeBlack : Color.clear, lineWidth: 1.5)
                    )
                    .shadow(color: Color.black.opacity(isCurrent ? 0.15 : 0.0), radius: 4, y: 2)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 4)
    }
}

#Preview {
    ZStack {
        AppTheme.gamePeriwinkle.ignoresSafeArea()
        PlayfulHeroCardView(
            player: Player(name: "Kauã Vinícius", balance: 8465, color: .blue),
            players: [
                Player(name: "Kauã", balance: 8465, color: .blue),
                Player(name: "Mariana", balance: 2100, color: .purple),
                Player(name: "Lucas", balance: 950, color: .orange)
            ],
            onSelectPlayer: { _ in },
            onOpenCardActions: {}
        )
    }
}


