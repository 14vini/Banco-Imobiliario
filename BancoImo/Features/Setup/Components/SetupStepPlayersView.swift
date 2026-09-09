//
//  SetupStepPlayersView.swift
//  BancoImo
//
//  Created by iOS Senior Developer.
//

import SwiftUI

/// Passo 2 do Onboarding: Cadastro e seleção de peões 3D dos jogadores da mesa com animação elástica ao entrar.
struct SetupStepPlayersView: View {
    @Bindable var viewModel: GameViewModel
    let onNext: () -> Void
    
    @State private var newPlayerName: String = ""
    @State private var selectedColor: PlayerColor = .blue
    @FocusState private var isNameFieldFocused: Bool
    
    private var canProceed: Bool {
        viewModel.players.count >= 2
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // MARK: - Cabeçalho do Passo
            VStack(spacing: 4) {
                HStack(spacing: 6) {
                    Text("Quem vai jogar?")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundStyle(Color.white)
                }
                
                Text(canProceed
                     ? "\(viewModel.players.count) amigos prontos! Você pode adicionar mais ou avançar."
                     : "Adicione pelo menos 2 jogadores para iniciar a mesa.")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(canProceed ? AppTheme.actionYellow : Color.white.opacity(0.9))
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 4)
            
            // MARK: - Card de Adicionar Jogador com Avatar 3D
            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    // Preview do Avatar Token 3D
                    ZStack(alignment: .bottom) {
                        Circle()
                            .fill(selectedColor.color.opacity(0.8))
                            .frame(width: 36, height: 36)
                            .overlay(Circle().stroke(AppTheme.strokeBlack, lineWidth: 1.5))
                            .offset(y: 2)
                        
                        Circle()
                            .fill(selectedColor.color.gradient)
                            .frame(width: 36, height: 36)
                            .overlay(Circle().stroke(AppTheme.strokeBlack, lineWidth: 1.5))
                            .overlay(
                                Circle()
                                    .strokeBorder(Color.white.opacity(0.4), lineWidth: 1.2)
                                    .padding(1.5)
                            )
                            .overlay(
                                Group {
                                    if newPlayerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                        Image(systemName: "person.fill")
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundStyle(.white)
                                    } else {
                                        Text(String(newPlayerName.prefix(1)).uppercased())
                                            .font(.system(size: 14, weight: .black, design: .rounded))
                                            .foregroundStyle(.white)
                                    }
                                }
                            )
                    }
                    .frame(width: 36, height: 38)
                    
                    TextField("Nome do amigo (ex: Mariana)", text: $newPlayerName)
                        .font(.body.weight(.bold))
                        .focused($isNameFieldFocused)
                        .onSubmit {
                            submitPlayer()
                        }
                    
                    // Botão 3D Adicionar (+)
                    Tactile3DButton(
                        faceGradient: newPlayerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            ? LinearGradient(colors: [Color(white: 0.92), Color(white: 0.85)], startPoint: .top, endPoint: .bottom)
                            : AppTheme.actionYellowGradient,
                        depthColor: newPlayerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            ? Color(white: 0.75)
                            : AppTheme.actionYellowDark,
                        cornerRadius: 12,
                        depth: 3.5,
                        strokeWidth: 1.5,
                        highlightColor: Color.white.opacity(0.7),
                        action: submitPlayer
                    ) {
                        Image(systemName: "plus")
                            .font(.system(size: 15, weight: .black))
                            .foregroundStyle(
                                newPlayerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                ? Color.gray
                                : AppTheme.strokeBlack
                            )
                            .frame(width: 34, height: 32)
                    }
                    .disabled(newPlayerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.players.count >= viewModel.maxPlayers)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(AppTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(isNameFieldFocused ? AppTheme.strokeBlack : AppTheme.strokeBlack.opacity(0.18), lineWidth: 1.8)
                )
                
                // Seletor de Cores em Fichas 3D
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(PlayerColor.allCases) { color in
                            let isUsed = viewModel.players.contains(where: { $0.color == color })
                            ColorChip(
                                color: color,
                                isSelected: selectedColor == color,
                                isUsedByAnotherPlayer: isUsed
                            ) {
                                HapticManager.selection()
                                SoundManager.play(.buttonTap)
                                selectedColor = color
                            }
                        }
                    }
                    .padding(.horizontal, 2)
                    .padding(.vertical, 4)
                }
            }
            
            // MARK: - Lista de Amigos na Mesa (com Animação de Entrada)
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Jogadores na Mesa:")
                        .font(.caption.weight(.heavy))
                        .foregroundStyle(Color.white.opacity(0.85))
                    
                    Spacer()
                    
                    Text("\(viewModel.players.count)/\(viewModel.maxPlayers)")
                        .font(.system(size: 10.5, weight: .black, design: .rounded))
                        .foregroundStyle(AppTheme.strokeBlack)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2.5)
                        .background(canProceed ? AppTheme.actionYellow : Color.white)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(AppTheme.strokeBlack, lineWidth: 1.2))
                }
                
                if viewModel.players.isEmpty {
                    HStack {
                        Spacer()
                        VStack(spacing: 6) {
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 26))
                                .foregroundStyle(AppTheme.strokeBlack.opacity(0.35))
                            Text("Digite o nome acima para adicionar")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                        .padding(.vertical, 20)
                        Spacer()
                    }
                    .background(AppTheme.cardBackground.opacity(0.9))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(AppTheme.strokeBlack.opacity(0.2), style: StrokeStyle(lineWidth: 1.5, dash: [5, 5]))
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(viewModel.players) { player in
                                PlayerSetupCard(
                                    player: player,
                                    isHost: viewModel.hostPlayerId == player.id,
                                    onSetHost: {
                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                            viewModel.setHostPlayer(id: player.id)
                                        }
                                    },
                                    onDelete: {
                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                            viewModel.removePlayer(id: player.id)
                                            selectedColor = viewModel.nextSuggestedColor
                                        }
                                    }
                                )
                                .transition(.asymmetric(
                                    insertion: .scale(scale: 0.85).combined(with: .opacity).combined(with: .move(edge: .top)),
                                    removal: .opacity.combined(with: .move(edge: .trailing))
                                ))
                            }
                        }
                        .padding(.vertical, 2)
                    }
                    .frame(maxHeight: 220)
                }
            }
            
            Spacer(minLength: 4)
            
            // MARK: - Botão de Avançar 3D (Validado com Mínimo 2 Jogadores)
            Tactile3DButton(
                faceGradient: canProceed
                    ? AppTheme.actionYellowGradient
                    : LinearGradient(colors: [Color(white: 0.92), Color(white: 0.85)], startPoint: .top, endPoint: .bottom),
                depthColor: canProceed ? AppTheme.actionYellowDark : Color(white: 0.70),
                cornerRadius: 18,
                depth: canProceed ? 5.0 : 2.5,
                strokeColor: AppTheme.strokeBlack,
                strokeWidth: 2.0,
                highlightColor: canProceed ? Color.white.opacity(0.7) : Color.clear,
                action: {
                    if canProceed {
                        SoundManager.play(.buttonTap)
                        onNext()
                    }
                }
            ) {
                HStack(spacing: 8) {
                    Text(canProceed ? "Avançar: Ajustes da Mesa" : "Adicione pelo menos 2 jogadores")
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                    
                    if canProceed {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .black))
                    }
                }
                .foregroundStyle(canProceed ? AppTheme.strokeBlack : Color.black.opacity(0.35))
                .frame(maxWidth: .infinity)
                .frame(height: 48)
            }
            .disabled(!canProceed)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
        .onAppear {
            selectedColor = viewModel.nextSuggestedColor
        }
    }
    
    private func submitPlayer() {
        if viewModel.addPlayer(name: newPlayerName, color: selectedColor) {
            newPlayerName = ""
            selectedColor = viewModel.nextSuggestedColor
            isNameFieldFocused = false
            SoundManager.play(.coinDrop)
            HapticManager.impact(.medium)
        }
    }
}

#Preview {
    ZStack {
        AppTheme.canvasBackground.ignoresSafeArea()
        SetupStepPlayersView(viewModel: GameViewModel(), onNext: {})
    }
}
