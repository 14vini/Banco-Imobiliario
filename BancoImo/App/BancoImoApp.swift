//
//  BancoImoApp.swift
//  BancoImo
//
//  Created by Kaua on 05/09/26.
//

import SwiftUI

@main
struct BancoImoApp: App {
    
    init() {
        // Inicializa e ativa a sessão de áudio imediatamente ao abrir o app
        _ = SoundManager.shared
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
