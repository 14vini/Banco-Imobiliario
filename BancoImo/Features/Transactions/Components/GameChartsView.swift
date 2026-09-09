//
//  GameChartsView.swift
//  BancoImo
//
//  Created by iOS Senior Developer.
//

import SwiftUI
import Charts

/// Visão analítica lúdica com Gráficos Swift Charts, Gráfico de Barras com Peões do Jogo,
/// Badges Geométricos (Hexágono, Engrenagem, Círculo) e Métricas de Partida inspirados na tela de detalhes da imagem de referência.
struct GameChartsView: View {
    let viewModel: GameViewModel
    
    private var historyPoints: [BalanceHistoryPoint] {
        viewModel.calculateBalanceHistory()
    }
    
    // Jogadores ordenados por saldo para o gráfico de barras
    private var sortedPlayers: [Player] {
        viewModel.players.sorted { $0.balance > $1.balance }
    }
    
    // Saldo máximo para dimensionamento das barras
    private var maxBalance: Decimal {
        let maxVal = viewModel.players.map { max(0, $0.balance) }.max() ?? 1500
        return maxVal > 0 ? maxVal : 1500
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // MARK: - 1. Badges Geométricos Lúdicos (Screen 3)
                geometricBadgesRow
                
                // MARK: - 2. Gráfico de Barras Lúdico com Peões de Tabuleiro (Screen 3)
                playfulBarChartCard
                
                // MARK: - 3. Gráfico de Linha: Evolução Patrimonial
                netWorthLineChartCard
                
                // MARK: - 4. Gráfico de Pizza / Rosca: Distribuição de Riqueza
                wealthDistributionDonutCard
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 28)
        }
        .background(AppTheme.canvasBackground.opacity(0.12))
    }
    
    // MARK: - 1. Badges Geométricos Lúdicos
    
    private var geometricBadgesRow: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
            // Badge 1: Hexágono Líder de Saldo
            geometricBadge(
                title: "LÍDER DE SALDO",
                value: viewModel.richestPlayer?.name ?? "Ninguém",
                subvalue: viewModel.richestPlayer?.balance.asCurrency ?? "R$ 0",
                shape: .hexagon,
                accentColor: AppTheme.gameYellow
            )
            
            // Badge 2: Magnata Imobiliário (Patrimônio Líquido Real)
            let tycoon = viewModel.richestPlayerByNetWorth
            geometricBadge(
                title: "MAIOR MAGNATA",
                value: tycoon?.name ?? "Ninguém",
                subvalue: tycoon != nil ? "Patr: \(viewModel.calculateNetWorth(for: tycoon!).asCurrency)" : "R$ 0",
                shape: .building,
                accentColor: AppTheme.actionBlue
            )
            
            // Badge 3: Engrenagem / Starburst (Total em Jogo)
            geometricBadge(
                title: "EM CIRCULAÇÃO",
                value: viewModel.totalMoneyInCirculation.asCurrency,
                subvalue: "\(viewModel.activePlayers.count) amigos ativos",
                shape: .gear,
                accentColor: AppTheme.gameCoral
            )
            
            // Badge 4: Círculo (Média da Mesa)
            geometricBadge(
                title: "MÉDIA POR AMIGO",
                value: viewModel.averageBalancePerPlayer.asCurrency,
                subvalue: "Tempo: \(viewModel.formattedElapsedTime)",
                shape: .circle,
                accentColor: AppTheme.gameGreen
            )
        }
    }
    
    private enum GeometricShapeType {
        case hexagon
        case building
        case gear
        case circle
    }
    
    private func geometricBadge(title: String, value: String, subvalue: String, shape: GeometricShapeType, accentColor: Color) -> some View {
        VStack(alignment: .center, spacing: 6) {
            // Ícone com forma geométrica estilizada
            ZStack {
                switch shape {
                case .hexagon:
                    Image(systemName: "hexagon.fill")
                        .font(.system(size: 38))
                        .foregroundStyle(accentColor.opacity(0.2))
                    Image(systemName: "crown.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(accentColor)
                case .building:
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(accentColor.opacity(0.2))
                        .frame(width: 38, height: 38)
                    Image(systemName: "building.2.fill")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(accentColor)
                case .gear:
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 38))
                        .foregroundStyle(accentColor.opacity(0.2))
                    Image(systemName: "banknote.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(accentColor)
                case .circle:
                    Circle()
                        .fill(accentColor.opacity(0.2))
                        .frame(width: 38, height: 38)
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(accentColor)
                }
            }
            .frame(height: 42)
            
            Text(title)
                .font(.system(size: 9, weight: .black, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
                .tracking(0.5)
                .lineLimit(1)
            
            Text(value)
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            
            Text(subvalue)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)
                .lineLimit(1)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AppTheme.strokeBlack.opacity(0.12), lineWidth: 1.5)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - 2. Gráfico de Barras Lúdico com Peões de Tabuleiro (Screen 3)
    
    private var playfulBarChartCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("COMPARATIVO DE SALDOS")
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .foregroundStyle(AppTheme.gameYellow)
                        .tracking(1)
                    
                    Text("Ranking Financeiro da Mesa")
                        .font(.headline.weight(.heavy))
                        .foregroundStyle(AppTheme.textPrimary)
                }
                
                Spacer()
                
                // Ícone lúdico de dado/jogo
                HStack(spacing: 4) {
                    Image(systemName: "die.face.5.fill")
                        .font(.system(size: 14, weight: .bold))
                    Text("Mesa")
                        .font(.caption2.weight(.bold))
                }
                .foregroundStyle(AppTheme.strokeBlack)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(AppTheme.gameYellow)
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(AppTheme.strokeBlack, lineWidth: 1.2)
                )
            }
            
            if viewModel.players.isEmpty {
                Text("Nenhum jogador cadastrado.")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
                    .padding(.vertical, 30)
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                // Barras Verticais Lúdicas
                HStack(alignment: .bottom, spacing: 12) {
                    ForEach(Array(sortedPlayers.enumerated()), id: \.element.id) { index, player in
                        let maxDouble = NSDecimalNumber(decimal: maxBalance).doubleValue
                        let playerDouble = NSDecimalNumber(decimal: max(0, player.balance)).doubleValue
                        let normalizedHeight = maxDouble > 0 ? (playerDouble / maxDouble) : 0.1
                        let barHeight = CGFloat(max(30, normalizedHeight * 140))
                        let tokenIcon = boardGameTokenIcon(for: index)
                        
                        VStack(spacing: 6) {
                            // Saldo formatado acima do peão
                            Text(player.balance.asCurrency)
                                .font(.system(size: 10, weight: .heavy, design: .rounded))
                                .foregroundStyle(AppTheme.textPrimary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                            
                            // Peão Lúdico de Tabuleiro no topo da barra (Screen 3)
                            ZStack {
                                Circle()
                                    .fill(player.color.color)
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Circle().stroke(AppTheme.strokeBlack, lineWidth: 1.5)
                                    )
                                    .shadow(color: player.color.color.opacity(0.3), radius: 3, x: 0, y: 2)
                                
                                Image(systemName: tokenIcon)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                            
                            // Barra Vertical Arredondada
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            player.color.color,
                                            player.color.color.opacity(0.75)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(height: barHeight)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(AppTheme.strokeBlack, lineWidth: 1.5)
                                )
                                .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
                            
                            // Nome do Jogador
                            Text(player.name)
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundStyle(AppTheme.textPrimary)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 220)
                .padding(.top, 10)
            }
        }
        .padding(18)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(AppTheme.strokeBlack.opacity(0.12), lineWidth: 1.5)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 3)
    }
    
    private func boardGameTokenIcon(for index: Int) -> String {
        switch index % 6 {
        case 0: return "house.fill"          // Casa / Hotel
        case 1: return "car.fill"            // Carro
        case 2: return "die.face.5.fill"     // Dado
        case 3: return "tram.fill"           // Trem / Ferrovia
        case 4: return "crown.fill"          // Coroa / Cartola
        default: return "pawprint.fill"      // Mascote / Cãozinho
        }
    }
    
    // MARK: - 3. Gráfico de Linha de Evolução do Patrimônio
    
    private var netWorthLineChartCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("CURVA DE PATRIMÔNIO")
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .foregroundStyle(AppTheme.gameCoral)
                        .tracking(1)
                    
                    Text("Evolução Rodada a Rodada")
                        .font(.headline.weight(.heavy))
                        .foregroundStyle(AppTheme.textPrimary)
                }
                
                Spacer()
                
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(AppTheme.gameCoral)
            }
            
            if historyPoints.isEmpty || viewModel.players.isEmpty {
                Text("Inicie a partida para visualizar a evolução.")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
                    .padding(.vertical, 30)
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                Chart(historyPoints) { point in
                    LineMark(
                        x: .value("Rodada", point.stepLabel),
                        y: .value("Saldo", point.balance)
                    )
                    .foregroundStyle(by: .value("Jogador", point.playerName))
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 3.5, lineCap: .round))
                    
                    PointMark(
                        x: .value("Rodada", point.stepLabel),
                        y: .value("Saldo", point.balance)
                    )
                    .foregroundStyle(by: .value("Jogador", point.playerName))
                    .symbolSize(42)
                }
                .chartForegroundStyleScale(
                    domain: viewModel.players.map { $0.name },
                    range: viewModel.players.map { $0.color.color }
                )
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                            .foregroundStyle(AppTheme.borderSubtle)
                        AxisValueLabel {
                            if let doubleVal = value.as(Double.self) {
                                Text("R$\(Int(doubleVal))")
                                    .font(.system(size: 9, weight: .bold, design: .rounded))
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let str = value.as(String.self) {
                                Text(str)
                                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                        }
                    }
                }
                .frame(height: 200)
                .padding(.top, 6)
            }
        }
        .padding(18)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(AppTheme.strokeBlack.opacity(0.12), lineWidth: 1.5)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 3)
    }
    
    // MARK: - 4. Gráfico de Pizza / Rosca de Distribuição de Riqueza
    
    private var wealthDistributionDonutCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("DISTRIBUIÇÃO DE RIQUEZA")
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .foregroundStyle(AppTheme.gameGreen)
                        .tracking(1)
                    
                    Text("Participação no Dinheiro Total")
                        .font(.headline.weight(.heavy))
                        .foregroundStyle(AppTheme.textPrimary)
                }
                
                Spacer()
                
                Image(systemName: "chart.pie.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(AppTheme.gameGreen)
            }
            
            if viewModel.totalMoneyInCirculation <= 0 || viewModel.players.isEmpty {
                Text("Sem saldo em circulação para gerar a pizza.")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
                    .padding(.vertical, 30)
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                HStack(spacing: 20) {
                    // Gráfico Donut
                    Chart(viewModel.players) { player in
                        SectorMark(
                            angle: .value("Saldo", max(0, NSDecimalNumber(decimal: player.balance).doubleValue)),
                            innerRadius: .ratio(0.58),
                            angularInset: 2.5
                        )
                        .cornerRadius(6)
                        .foregroundStyle(player.color.color)
                    }
                    .frame(width: 130, height: 130)
                    .overlay(
                        VStack(spacing: 1) {
                            Text("TOTAL")
                                .font(.system(size: 8, weight: .black, design: .rounded))
                                .foregroundStyle(AppTheme.textSecondary)
                            Text(viewModel.totalMoneyInCirculation.asCurrency)
                                .font(.system(size: 11, weight: .heavy, design: .rounded))
                                .foregroundStyle(AppTheme.textPrimary)
                                .minimumScaleFactor(0.6)
                                .lineLimit(1)
                        }
                    )
                    
                    // Legenda com % de cada amigo
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(viewModel.players) { player in
                            let totalDouble = NSDecimalNumber(decimal: viewModel.totalMoneyInCirculation).doubleValue
                            let playerDouble = NSDecimalNumber(decimal: max(0, player.balance)).doubleValue
                            let percentage = totalDouble > 0 ? (playerDouble / totalDouble) * 100 : 0
                            
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(player.color.color)
                                    .frame(width: 10, height: 10)
                                    .overlay(
                                        Circle().stroke(AppTheme.strokeBlack, lineWidth: 1)
                                    )
                                
                                Text(player.name)
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(AppTheme.textPrimary)
                                    .lineLimit(1)
                                
                                Spacer()
                                
                                Text(String(format: "%.1f%%", percentage))
                                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                                    .foregroundStyle(AppTheme.textPrimary)
                            }
                        }
                    }
                }
                .padding(.vertical, 6)
            }
        }
        .padding(18)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(AppTheme.strokeBlack.opacity(0.12), lineWidth: 1.5)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 3)
    }
}

#Preview {
    let vm = GameViewModel()
    vm.players = [
        Player(name: "Kauã", balance: 3200, color: .blue),
        Player(name: "Mariana", balance: 2100, color: .purple),
        Player(name: "Lucas", balance: 1400, color: .orange)
    ]
    vm.elapsedTime = 2540
    return GameChartsView(viewModel: vm)
        .padding()
        .background(AppTheme.canvasBackground)
}

