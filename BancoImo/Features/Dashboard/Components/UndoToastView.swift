//
//  UndoToastView.swift
//  BancoImo
//
//  Created by iOS Senior Developer.
//

import SwiftUI

/// Banner/Toast flutuante que notifica os jogadores na mesa quando uma ação foi desfeita com sucesso.
struct UndoToastView: View {
    let message: String
    let onDismiss: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(AppTheme.actionYellowGradient)
                    .frame(width: 32, height: 32)
                    .overlay(Circle().stroke(AppTheme.strokeBlack, lineWidth: 1.2))
                
                Image(systemName: "arrow.uturn.backward")
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(AppTheme.strokeBlack)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("AÇÃO DESFEITA")
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .foregroundStyle(AppTheme.actionYellow)
                    .tracking(0.5)
                
                Text(message)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(2)
            }
            
            Spacer(minLength: 8)
            
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white.opacity(0.8))
                    .frame(width: 24, height: 24)
                    .background(Color.white.opacity(0.12))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.12, green: 0.14, blue: 0.20), Color(red: 0.08, green: 0.09, blue: 0.14)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(AppTheme.strokeBlack, lineWidth: 2.0)
                )
                .shadow(color: Color.black.opacity(0.35), radius: 12, x: 0, y: 6)
        )
        .padding(.horizontal, 24)
        .transition(.asymmetric(
            insertion: .move(edge: .top).combined(with: .opacity).combined(with: .scale(scale: 0.95)),
            removal: .move(edge: .top).combined(with: .opacity)
        ))
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        UndoToastView(
            message: "Passou pelo Início (+R$ 2.000)",
            onDismiss: {}
        )
    }
}
