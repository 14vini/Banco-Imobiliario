//
//  SetupStepReadyView.swift
//  BancoImo
//
//  Created by iOS Senior Developer.
//

import SwiftUI

/// Passo 3 do Onboarding: Mesa pronta com vitrine de peões dos jogadores reunidos, toggles rápidos e grande botão de início.
struct SetupStepReadyView: View {
    @Bindable var viewModel: GameViewModel
    let onStart: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // MARK: - Cabeçalho do Passo
            VStack(spacing: 4) {
                Text("Mesa Pronta para Jogar")
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundStyle(Color.white)
                    .multilineTextAlignment(.center)
                
                Text("Confira os amigos na mesa e os recursos antes de abrir o banco.")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.white.opacity(0.9))
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 4)
            
            // MARK: - Vitrine da Mesa (Card Cerâmico dos Jogadores Reunidos)
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(AppTheme.actionGreen)
                            .frame(width: 8, height: 8)
                            .overlay(Circle().stroke(AppTheme.strokeBlack, lineWidth: 1))
                        
                        Text("MESA CONFIGURADA")
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .foregroundStyle(AppTheme.strokeBlack)
                            .tracking(1)
                    }
                    
                    Spacer()
                    
                    Text("\(viewModel.players.count) amigos")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundStyle(AppTheme.strokeBlack)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(AppTheme.actionYellow)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(AppTheme.strokeBlack, lineWidth: 1.2))
                }
                
                // Grid/Carrossel de Peões dos Jogadores
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(viewModel.players) { player in
                            VStack(spacing: 6) {
                                ZStack(alignment: .bottom) {
                                    Circle()
                                        .fill(player.color.color.opacity(0.8))
                                        .frame(width: 44, height: 44)
                                        .overlay(Circle().stroke(AppTheme.strokeBlack, lineWidth: 1.8))
                                        .offset(y: 2)
                                    
                                    Circle()
                                        .fill(player.color.color.gradient)
                                        .frame(width: 44, height: 44)
                                        .overlay(Circle().stroke(AppTheme.strokeBlack, lineWidth: 1.8))
                                        .overlay(
                                            Circle()
                                                .strokeBorder(Color.white.opacity(0.4), lineWidth: 1.2)
                                                .padding(1.5)
                                        )
                                        .overlay(
                                            Text(String(player.name.prefix(1)).uppercased())
                                                .font(.system(size: 18, weight: .black, design: .rounded))
                                                .foregroundStyle(.white)
                                        )
                                }
                                .frame(width: 44, height: 46)
                                
                                Text(player.name)
                                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                                    .foregroundStyle(AppTheme.textPrimary)
                                    .lineLimit(1)
                                
                                Text(player.balance.asCurrency)
                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                                    .foregroundStyle(AppTheme.actionGreenDark)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(AppTheme.strokeBlack.opacity(0.15), lineWidth: 1.2)
                            )
                        }
                    }
                    .padding(.horizontal, 2)
                }
                
                Divider()
                
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Total Inicial em Circulação:")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(AppTheme.textSecondary)
                        
                        Text(viewModel.totalMoneyInCirculation.asCurrency)
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .foregroundStyle(AppTheme.strokeBlack)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Saldo por Jogador:")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(AppTheme.textSecondary)
                        
                        Text(viewModel.initialBalance.asCurrency)
                            .font(.system(size: 14, weight: .heavy, design: .rounded))
                            .foregroundStyle(AppTheme.strokeBlack)
                    }
                }
            }
            .padding(14)
            .background(AppTheme.cardPearlGradient)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(AppTheme.strokeBlack, lineWidth: 2.0)
            )
            .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 3)
            
            // MARK: - Recursos da Mesa Digital
            VStack(spacing: 8) {
                // Toggle Dados 3D
                Toggle(isOn: $viewModel.isDiceEnabled) {
                    HStack(spacing: 10) {
                        Image(systemName: "die.face.5.fill")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(AppTheme.actionYellow)
                        
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Dados Virtuais 3D na Mesa")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(AppTheme.textPrimary)
                            Text("Rolagem com física e detecção de duplos")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    }
                }
                .tint(AppTheme.actionGreen)
                
                Divider()
                
                // Toggle Audio FX
                Toggle(isOn: $viewModel.isSoundEnabled) {
                    HStack(spacing: 10) {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(AppTheme.actionPurple)
                        
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Efeitos Sonoros (Audio FX)")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(AppTheme.textPrimary)
                            Text("Cliques mecânicos, moedas e caixa")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    }
                }
                .tint(AppTheme.actionGreen)
            }
            .padding(12)
            .background(AppTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(AppTheme.strokeBlack, lineWidth: 1.8)
            )
            
            Spacer(minLength: 4)
            
            // MARK: - Botão Final 3D: Começar Jogo!
            Tactile3DButton(
                faceGradient: AppTheme.actionYellowGradient,
                depthColor: AppTheme.actionYellowDark,
                cornerRadius: 20,
                depth: 5.5,
                strokeColor: AppTheme.strokeBlack,
                strokeWidth: 2.2,
                highlightColor: Color.white.opacity(0.75),
                action: {
                    SoundManager.play(.cashRegister)
                    HapticManager.impact(.heavy)
                    onStart()
                }
            ) {
                HStack(spacing: 10) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 16, weight: .black))
                    
                    Text("COMEÇAR PARTIDA")
                        .font(.system(size: 17, weight: .heavy, design: .rounded))
                }
                .foregroundStyle(AppTheme.strokeBlack)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }
}

#Preview {
    let vm = GameViewModel()
    vm.players = [
        Player(name: "Kauã", balance: 1500, color: .blue),
        Player(name: "Mariana", balance: 1500, color: .purple)
    ]
    return ZStack {
        AppTheme.canvasBackground.ignoresSafeArea()
        SetupStepReadyView(viewModel: vm, onStart: {})
    }
}
