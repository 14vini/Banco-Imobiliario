//
//  SetupView.swift
//  BancoImo
//
//  Created by iOS Senior Developer.
//

import SwiftUI

/// Tela inicial (Home Hub) e Onboarding Wizard Passo a Passo para criação e início de partidas com animações fluidas 3D.
struct SetupView: View {
    @Bindable var viewModel: GameViewModel
    
    // Estado de exibição do Wizard (false = Home Hub, true = Passo a Passo)
    @State private var isWizardActive: Bool = false
    @State private var currentStep: Int = 1 // 1: Saldo, 2: Jogadores, 3: Mesa Pronta
    @State private var isNavigatingForward: Bool = true
    
    @State private var showConfirmReset: Bool = false
    @State private var showQRScanner: Bool = false
    
    var body: some View {
        NavigationStack {
            ZStack{
                // Fundo Lúdico Periwinkle
                AppTheme.canvasBackground
                    .ignoresSafeArea()
                
                if !isWizardActive {
                    // MARK: - 1. Home Hub (Tela Inicial Limpa)
                    homeHubView
                        .transition(
                            .asymmetric(
                                insertion: .opacity.combined(with: .scale(scale: 0.96)),
                                removal: .opacity.combined(with: .scale(scale: 0.96))
                            )
                        )
                } else {
                    // MARK: - 2. Wizard de Criação em 3 Passos
                    wizardContainerView
                        .transition(
                            .asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            )
                        )
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isWizardActive)
            .animation(.spring(response: 0.35, dampingFraction: 0.75), value: currentStep)
            .navigationBarHidden(true)
            .confirmationDialog(
                "Apagar Dados da Mesa?",
                isPresented: $showConfirmReset,
                titleVisibility: .visible
            ) {
                Button("Apagar Dados e Começar do Zero", role: .destructive) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        viewModel.resetGame()
                        currentStep = 1
                        isWizardActive = false
                    }
                }
                Button("Cancelar", role: .cancel) {}
            } message: {
                Text("Esta ação apagará os jogadores cadastrados e os saldos da mesa.")
            }
            .alert(
                "Atenção",
                isPresented: Binding(
                    get: { viewModel.errorMessage != nil },
                    set: { if !$0 { viewModel.errorMessage = nil } }
                )
            ) {
                Button("OK", role: .cancel) {
                    viewModel.errorMessage = nil
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .sheet(isPresented: $showQRScanner) {
                QRCodeScannerView(
                    onScannedQR: { _ in
                        showQRScanner = false
                    },
                    onCancel: {
                        showQRScanner = false
                    }
                )
            }
        }
    }
    
    // MARK: - 1. Home Hub View (Tela Inicial Limpa e Acolhedora)
    
    private var homeHubView: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 22) {
                    // MARK: Card 3D de Retomada de Partida Salva (Se houver)
                    if viewModel.hasSavedGame && !viewModel.transactions.isEmpty {
                        resumeGameHero3DCard
                    }
                    
                    // MARK: Botão Principal 3D: Criar Nova Mesa
                    Tactile3DButton(
                        faceGradient: AppTheme.actionYellowGradient,
                        depthColor: AppTheme.actionYellowDark,
                        cornerRadius: 20,
                        depth: 5.5,
                        strokeColor: AppTheme.strokeBlack,
                        strokeWidth: 2.2,
                        highlightColor: Color.white.opacity(0.75),
                        action: {
                            SoundManager.play(.buttonTap)
                            HapticManager.impact(.medium)
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                currentStep = 1
                                isWizardActive = true
                            }
                        }
                    ) {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 36, height: 36)
                                    .overlay(Circle().stroke(AppTheme.strokeBlack, lineWidth: 1.5))
                                
                                Image(systemName: "plus")
                                    .font(.system(size: 18, weight: .black))
                                    .foregroundStyle(AppTheme.strokeBlack)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Criar Nova Mesa")
                                    .font(.system(size: 17, weight: .heavy, design: .rounded))
                                    .foregroundStyle(AppTheme.strokeBlack)
                                
                                Text("Passo a passo rápido em 3 etapas")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(AppTheme.strokeBlack.opacity(0.75))
                            }
                            
                            Spacer()
                            
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.system(size: 24, weight: .black))
                                .foregroundStyle(AppTheme.strokeBlack)
                        }
                        .padding(.horizontal, 16)
                        .frame(maxWidth: .infinity)
                        .frame(height: 64)
                    }
                    
                    // MARK: Botão 3D: Entrar na Mesa (QR Code / P2P Local)
                    Tactile3DButton(
                        faceGradient: AppTheme.actionPurpleGradient,
                        depthColor: AppTheme.actionPurpleDark,
                        cornerRadius: 20,
                        depth: 5.5,
                        strokeColor: AppTheme.strokeBlack,
                        strokeWidth: 2.2,
                        highlightColor: Color.white.opacity(0.4),
                        action: {
                            SoundManager.play(.buttonTap)
                            HapticManager.impact(.medium)
                            showQRScanner = true
                        }
                    ) {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 36, height: 36)
                                    .overlay(Circle().stroke(AppTheme.strokeBlack, lineWidth: 1.5))
                                
                                Image(systemName: "qrcode.viewfinder")
                                    .font(.system(size: 18, weight: .black))
                                    .foregroundStyle(AppTheme.strokeBlack)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Entrar na Mesa (QR Code)")
                                    .font(.system(size: 17, weight: .heavy, design: .rounded))
                                    .foregroundStyle(Color.white)
                                
                                Text("Use seu iPhone como carteira digital")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(Color.white.opacity(0.85))
                            }
                            
                            Spacer()
                            
                            Image(systemName: "wifi")
                                .font(.system(size: 18, weight: .black))
                                .foregroundStyle(Color.white)
                        }
                        .padding(.horizontal, 16)
                        .frame(maxWidth: .infinity)
                        .frame(height: 64)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
    }
    
    // MARK: - Card 3D de Retomada de Jogo Salvo
    
    private var resumeGameHero3DCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                HStack(spacing: 6) {
                    Circle()
                        .fill(AppTheme.actionGreen)
                        .frame(width: 8, height: 8)
                        .overlay(Circle().stroke(AppTheme.strokeBlack, lineWidth: 1))
                    
                    Text("PARTIDA EM ANDAMENTO")
                        .font(.system(size: 10.5, weight: .black, design: .rounded))
                        .foregroundStyle(AppTheme.strokeBlack)
                        .tracking(1)
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "stopwatch.fill")
                        .font(.system(size: 10, weight: .bold))
                    Text(viewModel.formattedElapsedTime)
                        .font(.system(size: 11.5, weight: .black, design: .monospaced))
                }
                .foregroundStyle(AppTheme.strokeBlack)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(AppTheme.gameYellow)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(AppTheme.strokeBlack, lineWidth: 1.2))
            }
            
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(viewModel.activePlayers.count) amigos na mesa")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                    
                    Text(viewModel.totalMoneyInCirculation.asCurrency)
                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                        .foregroundStyle(AppTheme.strokeBlack)
                }
                
                Spacer()
                
                Tactile3DButton(
                    faceGradient: AppTheme.actionGreenGradient,
                    depthColor: AppTheme.actionGreenDark,
                    cornerRadius: 14,
                    depth: 4.5,
                    strokeWidth: 1.8,
                    highlightColor: Color.white.opacity(0.4),
                    action: {
                        SoundManager.play(.buttonTap)
                        HapticManager.impact(.medium)
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                            viewModel.resumeGame()
                        }
                    }
                ) {
                    HStack(spacing: 6) {
                        Text("Continuar")
                            .font(.system(size: 14, weight: .heavy, design: .rounded))
                        Image(systemName: "play.fill")
                            .font(.system(size: 11, weight: .black))
                    }
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 16)
                    .frame(height: 38)
                }
            }
        }
        .padding(16)
        .background(AppTheme.cardPearlGradient)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(AppTheme.strokeBlack, lineWidth: 2.0)
        )
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(red: 0.12, green: 0.14, blue: 0.20))
                .offset(x: 2.5, y: 4)
                .shadow(color: Color.black.opacity(0.18), radius: 6, x: 2, y: 4)
        )
    }
        
    private func featureItemRow(icon: String, color: Color, title: String, subtitle: String) -> some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.18))
                    .frame(width: 32, height: 32)
                    .overlay(Circle().stroke(AppTheme.strokeBlack.opacity(0.2), lineWidth: 1))
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(AppTheme.strokeBlack)
            }
            
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
                Text(subtitle)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(AppTheme.textSecondary)
            }
            Spacer()
        }
    }
    
    // MARK: - 2. Wizard Container View (Barra de Progresso + Passos)
    
    private var wizardContainerView: some View {
        VStack(spacing: 0) {
            // MARK: Barra Superior do Wizard
            wizardTopBar
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 8)
            
            // MARK: Conteúdo do Passo Atual
            ZStack {
                switch currentStep {
                case 1:
                    SetupStepInitialBalanceView(viewModel: viewModel) {
                        goToStep(2)
                    }
                    .transition(stepTransition)
                    
                case 2:
                    SetupStepPlayersView(viewModel: viewModel) {
                        goToStep(3)
                    }
                    .transition(stepTransition)
                    
                case 3:
                    SetupStepReadyView(viewModel: viewModel) {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                            viewModel.startGame()
                        }
                    }
                    .transition(stepTransition)
                    
                default:
                    EmptyView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    // MARK: - Barra Superior do Wizard com Progresso em Pílulas
    
    private var wizardTopBar: some View {
        HStack(spacing: 12) {
            // Botão Voltar / Cancelar
            Button {
                SoundManager.play(.buttonTap)
                HapticManager.impact(.light)
                if currentStep > 1 {
                    goToStep(currentStep - 1, isForward: false)
                } else {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        isWizardActive = false
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .black))
                    Text(currentStep == 1 ? "Início" : "Voltar")
                        .font(.system(size: 12.5, weight: .black, design: .rounded))
                }
                .foregroundStyle(AppTheme.strokeBlack)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.white)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(AppTheme.strokeBlack, lineWidth: 1.5))
                .shadow(color: Color.black.opacity(0.08), radius: 2, x: 0, y: 1)
            }
            
            // Pílulas Indicadoras de Progresso (1, 2, 3)
            HStack(spacing: 6) {
                stepProgressPill(stepNumber: 1, title: "Saldo", isActive: currentStep >= 1, isCurrent: currentStep == 1)
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 8, weight: .black))
                    .foregroundStyle(Color.white.opacity(0.5))
                
                stepProgressPill(stepNumber: 2, title: "Amigos", isActive: currentStep >= 2, isCurrent: currentStep == 2)
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 8, weight: .black))
                    .foregroundStyle(Color.white.opacity(0.5))
                
                stepProgressPill(stepNumber: 3, title: "Iniciar", isActive: currentStep >= 3, isCurrent: currentStep == 3)
            }
            
            Spacer()
            
            // Botão de Lixeira / Reset Circular Elegante
            if !viewModel.players.isEmpty {
                Button {
                    SoundManager.play(.buttonTap)
                    HapticManager.impact(.medium)
                    showConfirmReset = true
                } label: {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(AppTheme.gameCoral)
                        .frame(width: 30, height: 30)
                        .background(Color.white)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(AppTheme.strokeBlack, lineWidth: 1.5))
                        .shadow(color: Color.black.opacity(0.08), radius: 2, x: 0, y: 1)
                }
                .accessibilityLabel("Apagar jogadores e reiniciar")
            }
        }
    }
    
    private func stepProgressPill(stepNumber: Int, title: String, isActive: Bool, isCurrent: Bool) -> some View {
        HStack(spacing: 4) {
            Text("\(stepNumber)")
                .font(.system(size: 10, weight: .black))
                .foregroundStyle(isCurrent ? AppTheme.strokeBlack : (isActive ? Color.white : Color.white.opacity(0.6)))
                .frame(width: 16, height: 16)
                .background(isCurrent ? AppTheme.actionYellow : (isActive ? AppTheme.actionGreen : Color.white.opacity(0.2)))
                .clipShape(Circle())
                .overlay(Circle().stroke(AppTheme.strokeBlack, lineWidth: isCurrent ? 1 : 0))
            
            if isCurrent {
                Text(title)
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundStyle(AppTheme.strokeBlack)
            }
        }
        .padding(.horizontal, isCurrent ? 8 : 4)
        .padding(.vertical, 4)
        .background(isCurrent ? Color.white : Color.clear)
        .clipShape(Capsule())
        .overlay(
            Capsule().stroke(isCurrent ? AppTheme.strokeBlack : Color.clear, lineWidth: 1.2)
        )
    }
    
    // MARK: - Helpers de Navegação e Transição
    
    private func goToStep(_ step: Int, isForward: Bool = true) {
        isNavigatingForward = isForward
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            currentStep = step
        }
    }
    
    private var stepTransition: AnyTransition {
        if isNavigatingForward {
            return .asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            )
        } else {
            return .asymmetric(
                insertion: .move(edge: .leading).combined(with: .opacity),
                removal: .move(edge: .trailing).combined(with: .opacity)
            )
        }
    }
}

#Preview {
    SetupView(viewModel: GameViewModel())
}
