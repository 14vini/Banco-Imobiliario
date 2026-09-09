//
//  MultipeerGameService.swift
//  BancoImo
//
//  Created by iOS Senior Developer.
//

import Foundation
import MultipeerConnectivity
import Observation
import SwiftUI

/// Modo de operação do dispositivo no ecossistema local P2P.
enum MultiplayerRole: Equatable, Sendable {
    case idle
    case host   // iPad (Mesa Central / Tabuleiro)
    case client // iPhone (Carteira do Jogador)
}

/// Serviço de rede P2P local (Zero-Backend) utilizando Apple MultipeerConnectivity.
/// Suporta Wi-Fi P2P e Bluetooth de baixa latência sem necessidade de conexão com internet ou servidores externos.
@Observable
@MainActor
final class MultipeerGameService: NSObject {
    
    // MARK: - Singleton & Configuração
    
    static let shared = MultipeerGameService()
    static let serviceType = "bancoimo-p2p"
    
    // MARK: - Estado Reativo
    
    var role: MultiplayerRole = .idle
    var connectionState: PeerConnectionState = .disconnected
    var connectedDevices: [ConnectedPeerDevice] = []
    
    /// Host atual ao qual este cliente está conectado
    var hostPeerID: MCPeerID? = nil
    var currentSessionId: String = UUID().uuidString.prefix(6).uppercased()
    
    /// Último snapshot recebido da Mesa Central (utilizado pelo iPhone)
    var latestGamePacket: GameSyncPacket? = nil
    
    /// Jogador reivindicado por este dispositivo cliente
    var myClaimedPlayerId: UUID? = nil
    
    /// Lista de mesas próximas descobertas pelo browser
    var discoveredHosts: [DiscoveredHost] = []
    
    /// Jogador que o próprio Anfitrião (iPad / Mesa Central) está controlando
    var hostPlayerId: UUID? = nil
    
    /// Dicionário com mapeamento de cada peão (Player ID) para o nome do aparelho conectado
    var claimedPlayerDeviceMap: [UUID: String] {
        var map: [UUID: String] = [:]
        if let hId = hostPlayerId {
            map[hId] = "Mesa Central (Anfitrião 👑)"
        }
        for device in connectedDevices {
            if let pId = device.claimedPlayerId {
                map[pId] = device.claimedPlayerName ?? device.deviceDisplayName
            }
        }
        return map
    }
    
    // MARK: - Handlers e Callbacks
    
    /// Callback executado no Host quando uma ação remota chega de um iPhone
    var onReceiveActionFromClient: ((PlayerNetworkAction, MCPeerID) -> Void)? = nil
    
    /// Callback executado no Host assim que um novo peer completa a conexão
    var onPeerConnected: (() -> Void)? = nil
    
    // MARK: - Multipeer Primitives
    
    let myPeerID: MCPeerID
    private var session: MCSession?
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?
    
    /// Alvo de sessão para pareamento por QR Code
    private var targetSessionId: String? = nil
    
    // MARK: - Inicialização
    
    override init() {
        #if targetEnvironment(simulator)
        let deviceName = "Simulador (\(UUID().uuidString.prefix(4)))"
        #else
        let deviceName = UIDevice.current.name
        #endif
        self.myPeerID = MCPeerID(displayName: deviceName)
        super.init()
    }
    
    // MARK: - 1. Operações do HOST (Mesa Central / iPad)
    
    /// Inicia o modo Mesa Central: cria sessão P2P e começa a anunciar a sala localmente.
    func startHosting(gameId: UUID) {
        stopAllServices()
        
        self.role = .host
        self.currentSessionId = String(UUID().uuidString.prefix(6)).uppercased()
        self.connectedDevices = []
        self.connectionState = .advertising
        
        let newSession = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .none)
        newSession.delegate = self
        self.session = newSession
        
        let discoveryInfo: [String: String] = [
            "sessionId": currentSessionId,
            "hostName": myPeerID.displayName,
            "gameId": gameId.uuidString
        ]
        
        let newAdvertiser = MCNearbyServiceAdvertiser(
            peer: myPeerID,
            discoveryInfo: discoveryInfo,
            serviceType: Self.serviceType
        )
        newAdvertiser.delegate = self
        newAdvertiser.startAdvertisingPeer()
        self.advertiser = newAdvertiser
        
        HapticManager.notification(.success)
    }
    
    /// Transmite o estado atualizado do jogo (GameSyncPacket) para todos os iPhones conectados.
    func broadcastGameState(_ packet: GameSyncPacket) {
        guard role == .host, let session = session, !session.connectedPeers.isEmpty else { return }
        
        do {
            let data = try JSONEncoder().encode(packet)
            try session.send(data, toPeers: session.connectedPeers, with: .reliable)
        } catch {
            print("⚠️ [Multipeer] Falha ao transmitir GameSyncPacket: \(error)")
        }
    }
    
    /// Desconecta um peer específico
    func disconnectDevice(peerName: String) {
        guard let session = session else { return }
        if let peer = session.connectedPeers.first(where: { $0.displayName == peerName }) {
            session.cancelConnectPeer(peer)
        }
        connectedDevices.removeAll { $0.peerIdName == peerName }
    }
    
    // MARK: - 2. Operações do CLIENTE (Carteira / iPhone)
    
    /// Inicia a busca passiva por mesas locais na tela do Scanner sem alterar a role do app.
    func startBrowsingTables() {
        if browser != nil { return }
        self.discoveredHosts = []
        
        let newSession = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .none)
        newSession.delegate = self
        self.session = newSession
        
        let newBrowser = MCNearbyServiceBrowser(peer: myPeerID, serviceType: Self.serviceType)
        newBrowser.delegate = self
        newBrowser.startBrowsingForPeers()
        self.browser = newBrowser
    }
    
    /// Interrompe a busca de mesas se não estiver conectado
    func stopBrowsing() {
        if role == .idle {
            browser?.stopBrowsingForPeers()
            browser = nil
            session?.disconnect()
            session = nil
            discoveredHosts = []
        }
    }
    
    /// Inicia a conexão ativa como cliente focando em uma sessão específica
    func startClient(targetSessionId: String? = nil) {
        self.role = .client
        self.targetSessionId = targetSessionId
        self.connectionState = .browsing
        
        if session == nil {
            let newSession = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .none)
            newSession.delegate = self
            self.session = newSession
        }
        
        if browser == nil {
            let newBrowser = MCNearbyServiceBrowser(peer: myPeerID, serviceType: Self.serviceType)
            newBrowser.delegate = self
            newBrowser.startBrowsingForPeers()
            self.browser = newBrowser
        }
        
        // Se já tivermos encontrado o host com o ID desejado, conecta
        if let target = targetSessionId, let match = discoveredHosts.first(where: { $0.sessionId == target }) {
            connectToHost(match)
        }
    }
    
    /// Conecta a um host descoberto e define a role como cliente
    func connectToHost(_ host: DiscoveredHost) {
        self.role = .client
        self.targetSessionId = host.sessionId
        self.connectionState = .connecting(peerName: host.hostName)
        
        if session == nil {
            let newSession = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .none)
            newSession.delegate = self
            self.session = newSession
        }
        
        if browser == nil {
            let newBrowser = MCNearbyServiceBrowser(peer: myPeerID, serviceType: Self.serviceType)
            newBrowser.delegate = self
            newBrowser.startBrowsingForPeers()
            self.browser = newBrowser
        }
        
        guard let browser = browser, let session = session else { return }
        let contextData = currentSessionId.data(using: .utf8)
        browser.invitePeer(host.peerID, to: session, withContext: contextData, timeout: 15)
    }
    
    /// Conecta automaticamente ao ler dados de um QR Code
    func joinViaQRCode(_ qrData: HostQRData) {
        self.role = .client
        self.targetSessionId = qrData.sessionId
        
        if let match = discoveredHosts.first(where: { $0.sessionId == qrData.sessionId }) {
            connectToHost(match)
        } else {
            startClient(targetSessionId: qrData.sessionId)
        }
    }
    
    /// Envia uma ação do jogador (pagamento, compra, salário, etc.) para o iPad processar.
    func sendAction(_ action: PlayerNetworkAction) {
        guard role == .client, let session = session, let hostPeer = hostPeerID else {
            print("⚠️ [Multipeer] Não conectado a um host para enviar ação.")
            return
        }
        
        do {
            let data = try JSONEncoder().encode(action)
            try session.send(data, toPeers: [hostPeer], with: .reliable)
        } catch {
            print("⚠️ [Multipeer] Erro ao enviar ação remota: \(error)")
        }
    }
    
    /// Reivindica um peão específico
    func claimPlayerToken(_ playerId: UUID) {
        self.myClaimedPlayerId = playerId
        sendAction(.claimPlayer(playerId: playerId, deviceName: myPeerID.displayName))
        HapticManager.notification(.success)
        SoundManager.play(.buttonTap)
    }
    
    /// Libera o peão atual
    func releasePlayerToken() {
        if let pId = myClaimedPlayerId {
            sendAction(.releasePlayer(playerId: pId))
            self.myClaimedPlayerId = nil
        }
    }
    
    // MARK: - Encerramento
    
    /// Interrompe qualquer sessão, propaganda ou busca.
    func stopAllServices() {
        advertiser?.stopAdvertisingPeer()
        advertiser = nil
        
        browser?.stopBrowsingForPeers()
        browser = nil
        
        session?.disconnect()
        session = nil
        
        self.role = .idle
        self.connectionState = .disconnected
        self.hostPeerID = nil
        self.targetSessionId = nil
        self.discoveredHosts = []
        self.connectedDevices = []
    }
}

// MARK: - Descoberta de Salas

struct DiscoveredHost: Identifiable, Sendable, Equatable {
    var id: String { peerID.displayName }
    let peerID: MCPeerID
    let hostName: String
    let sessionId: String
    let gameId: String?
}

// MARK: - MCSessionDelegate

extension MultipeerGameService: MCSessionDelegate {
    nonisolated func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        Task { @MainActor in
            switch state {
            case .connected:
                HapticManager.notification(.success)
                SoundManager.play(.salary)
                
                if self.role == .client {
                    self.hostPeerID = peerID
                    self.connectionState = .connected(peerName: peerID.displayName)
                    
                    // Se já tínhamos um jogador reivindicado, reassume
                    if let claimedId = self.myClaimedPlayerId {
                        self.sendAction(.claimPlayer(playerId: claimedId, deviceName: self.myPeerID.displayName))
                    }
                } else if self.role == .host {
                    if !self.connectedDevices.contains(where: { $0.peerIdName == peerID.displayName }) {
                        self.connectedDevices.append(
                            ConnectedPeerDevice(
                                peerIdName: peerID.displayName,
                                deviceDisplayName: peerID.displayName
                            )
                        )
                    }
                    self.onPeerConnected?()
                }
                
            case .connecting:
                if self.role == .client {
                    self.connectionState = .connecting(peerName: peerID.displayName)
                }
                
            case .notConnected:
                if self.role == .client && self.hostPeerID == peerID {
                    self.hostPeerID = nil
                    self.connectionState = .disconnected
                    HapticManager.notification(.warning)
                } else if self.role == .host {
                    self.connectedDevices.removeAll { $0.peerIdName == peerID.displayName }
                }
                
            @unknown default:
                break
            }
        }
    }
    
    nonisolated func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        Task { @MainActor in
            if self.role == .client {
                // Cliente recebe snapshot completo da mesa
                if let packet = try? JSONDecoder().decode(GameSyncPacket.self, from: data) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        self.latestGamePacket = packet
                    }
                }
            } else if self.role == .host {
                // Host recebe ação remota enviada pelo iPhone
                if let action = try? JSONDecoder().decode(PlayerNetworkAction.self, from: data) {
                    self.handleIncomingActionOnHost(action, from: peerID)
                }
            }
        }
    }
    
    private func handleIncomingActionOnHost(_ action: PlayerNetworkAction, from peerID: MCPeerID) {
        // Atualiza rastreamento de qual jogador o dispositivo está controlando
        switch action {
        case .claimPlayer(let playerId, let deviceName):
            if let idx = connectedDevices.firstIndex(where: { $0.peerIdName == peerID.displayName }) {
                connectedDevices[idx].claimedPlayerId = playerId
                connectedDevices[idx].claimedPlayerName = deviceName
            }
        case .releasePlayer:
            if let idx = connectedDevices.firstIndex(where: { $0.peerIdName == peerID.displayName }) {
                connectedDevices[idx].claimedPlayerId = nil
                connectedDevices[idx].claimedPlayerName = nil
            }
        default:
            break
        }
        
        // Notifica o GameViewModel da mesa central para executar a ação!
        onReceiveActionFromClient?(action, peerID)
    }
    
    nonisolated func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    
    nonisolated func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    
    nonisolated func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

// MARK: - MCNearbyServiceAdvertiserDelegate (Host)

extension MultipeerGameService: MCNearbyServiceAdvertiserDelegate {
    nonisolated func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        Task { @MainActor in
            guard let currentSession = self.session else {
                invitationHandler(false, nil)
                return
            }
            
            // Aceita convites automaticamente para conexões sem atrito
            invitationHandler(true, currentSession)
        }
    }
}

// MARK: - MCNearbyServiceBrowserDelegate (Cliente)

extension MultipeerGameService: MCNearbyServiceBrowserDelegate {
    nonisolated func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        Task { @MainActor in
            let hostName = info?["hostName"] ?? peerID.displayName
            let sessionId = info?["sessionId"] ?? ""
            let gameId = info?["gameId"]
            
            let host = DiscoveredHost(
                peerID: peerID,
                hostName: hostName,
                sessionId: sessionId,
                gameId: gameId
            )
            
            if !self.discoveredHosts.contains(where: { $0.peerID == peerID }) {
                self.discoveredHosts.append(host)
            }
            
            // Se o usuário escaneou um QR code com targetSessionId específico, conecta automaticamente!
            if let target = self.targetSessionId, target == sessionId {
                self.connectToHost(host)
            }
        }
    }
    
    nonisolated func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        Task { @MainActor in
            self.discoveredHosts.removeAll { $0.peerID == peerID }
        }
    }
}
