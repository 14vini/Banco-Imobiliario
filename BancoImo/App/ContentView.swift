//
//  ContentView.swift
//  BancoImo
//
//  Created by Kaua on 05/09/26.
//

import SwiftUI

/// View raiz que gerencia o fluxo de navegação entre o Setup e o Dashboard do jogo ativo,
/// gerenciando o ciclo de vida do app (Foreground/Background) para preservar o cronômetro.
struct ContentView: View {
    @State private var viewModel = GameViewModel()
    @State private var multipeerService = MultipeerGameService.shared
    @State private var isShowingSplash: Bool = true
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        ZStack {
            if isShowingSplash {
                SplashScreenView {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                        isShowingSplash = false
                    }
                }
                .transition(.asymmetric(
                    insertion: .identity,
                    removal: .scale(scale: 1.05).combined(with: .opacity)
                ))
                .zIndex(2)
            } else {
                Group {
                    if multipeerService.role == .client {
                        // MARK: Modo Carteira Pessoal (iPhone Conectado)
                        PlayerPersonalWalletView {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                                multipeerService.stopAllServices()
                            }
                        }
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .move(edge: .bottom).combined(with: .opacity)
                        ))
                    } else if viewModel.isGameActive {
                        // MARK: Modo Mesa Central Ativa (iPad / Standalone)
                        GameDashboardView(viewModel: viewModel)
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .scale(scale: 0.98)),
                                removal: .opacity.combined(with: .scale(scale: 1.02))
                            ))
                    } else {
                        // MARK: Menu Inicial & Criação de Sala
                        SetupView(viewModel: viewModel)
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .scale(scale: 1.02)),
                                removal: .opacity.combined(with: .scale(scale: 0.98))
                            ))
                    }
                }
                .animation(.spring(response: 0.45, dampingFraction: 0.85), value: viewModel.isGameActive)
                .animation(.spring(response: 0.45, dampingFraction: 0.85), value: multipeerService.role)
                .zIndex(1)
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .background, .inactive:
                viewModel.handleAppBackgrounded()
            case .active:
                viewModel.handleAppForegrounded()
            @unknown default:
                break
            }
        }
    }
}

#Preview {
    ContentView()
}

