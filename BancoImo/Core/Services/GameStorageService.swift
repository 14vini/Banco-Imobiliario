//
//  GameStorageService.swift
//  BancoImo
//
//  Created by iOS Senior Developer.
//

import Foundation
import os

/// Protocolo que abstrai o mecanismo de persistência da partida para garantir testabilidade e baixo acoplamento.
protocol GameStorageServiceProtocol {
    func save(config: GameConfig) throws
    func load() -> GameConfig?
    func clear()
}

/// Implementação de persistência utilizando `UserDefaults` e serialização JSON.
final class UserDefaultsGameStorageService: GameStorageServiceProtocol {
    private let userDefaults: UserDefaults
    private let storageKey: String
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let logger = Logger(subsystem: "com.bancoimo.app", category: "Persistence")
    
    init(
        userDefaults: UserDefaults = .standard,
        storageKey: String = "banco_imo_game_state_v1"
    ) {
        self.userDefaults = userDefaults
        self.storageKey = storageKey
        
        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .iso8601
        self.encoder.outputFormatting = .prettyPrinted
        
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
    }
    
    /// Salva o estado atual da partida serializado em JSON no UserDefaults.
    func save(config: GameConfig) throws {
        do {
            let data = try encoder.encode(config)
            userDefaults.set(data, forKey: storageKey)
            logger.info("Partida salva com sucesso. Jogadores: \(config.players.count), Ativa: \(config.isGameActive)")
        } catch {
            logger.error("Erro ao codificar estado da partida: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Carrega o estado da partida a partir do UserDefaults.
    func load() -> GameConfig? {
        guard let data = userDefaults.data(forKey: storageKey) else {
            logger.info("Nenhuma partida salva encontrada no disco.")
            return nil
        }
        
        do {
            let config = try decoder.decode(GameConfig.self, from: data)
            logger.info("Partida carregada com sucesso. Jogadores: \(config.players.count), Ativa: \(config.isGameActive)")
            return config
        } catch {
            logger.error("Erro ao decodificar estado da partida salva: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Remove os dados persistidos da partida no UserDefaults.
    func clear() {
        userDefaults.removeObject(forKey: storageKey)
        logger.info("Dados da partida limpos do UserDefaults.")
    }
}
