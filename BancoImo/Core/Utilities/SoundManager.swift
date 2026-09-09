//
//  SoundManager.swift
//  BancoImo
//
//  Created by iOS Senior Developer.
//

import Foundation
import AVFoundation
import AudioToolbox

/// Gerenciador robusto de áudio com sintetizador de efeitos sonoros em memória (PCM WAV) e configuração de AVAudioSession,
/// garantindo reprodução nítida em iPads, iPhones e simuladores, mesmo no modo silencioso.
final class SoundManager: @unchecked Sendable {
    
    /// Tipos de efeitos sonoros do jogo
    enum SoundEffect: CaseIterable {
        case moneyIn      // 💵 Som de Dinheiro Entrando (Caixa Registradora "Cha-Ching" + Cascata de Moedas)
        case moneyOut     // 💸 Som de Dinheiro Saindo (Deslize de Notas de Papel + Pagamento Realizado)
        case cashRegister // Alias para moneyIn
        case salary       // Alias para compatibilidade (+2.000 / Início)
        case payment      // Alias para compatibilidade (Pagamento)
        case coinDrop     // Som de moeda/peão caindo na mesa
        case keypadTap    // Toque no teclado numérico
        case bankruptcy   // Alerta de falência / buzzer
        case undo         // Desfazer transação (rewind)
        case diceRoll     // Chacoalhar e rolar dados
        case diceDouble   // Dados iguais (fanfarra comemorativa)
        case buttonTap    // Clique sutil
    }
    
    static let shared = SoundManager()
    
    private var audioPlayers: [SoundEffect: AVAudioPlayer] = [:]
    private let queue = DispatchQueue(label: "com.bancoimo.soundmanager", qos: .userInteractive)
    
    private init() {
        configureAudioSession()
        preloadSounds()
    }
    
    /// Configura a sessão de áudio para categoria .playback, permitindo tocar mesmo com o interruptor de mudo do iPad/iPhone ativado.
    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            print("[SoundManager] Erro ao configurar AVAudioSession: \(error)")
        }
    }
    
    /// Pré-carrega todos os efeitos sonoros sintetizados na memória para latência zero.
    private func preloadSounds() {
        for effect in SoundEffect.allCases {
            if let wavData = generateWavData(for: effect) {
                do {
                    let player = try AVAudioPlayer(data: wavData)
                    player.prepareToPlay()
                    audioPlayers[effect] = player
                } catch {
                    print("[SoundManager] Erro ao preparar player para \(effect): \(error)")
                }
            }
        }
    }
    
    /// Flag global de áudio ativado/desativado
    static var isMuted: Bool {
        get {
            UserDefaults.standard.bool(forKey: "BancoImo_isSoundMuted")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "BancoImo_isSoundMuted")
        }
    }
    
    /// Executa o efeito sonoro se o áudio não estiver mutado.
    static func play(_ effect: SoundEffect) {
        guard !isMuted else { return }
        shared.queue.async {
            shared.playEffect(effect)
        }
    }
    
    private func playEffect(_ effect: SoundEffect) {
        // Reativa a sessão caso o sistema tenha interrompido
        try? AVAudioSession.sharedInstance().setActive(true)
        
        let targetEffect: SoundEffect
        switch effect {
        case .salary, .cashRegister: targetEffect = .moneyIn
        case .payment: targetEffect = .moneyOut
        default: targetEffect = effect
        }
        
        if let player = audioPlayers[targetEffect] {
            if player.isPlaying {
                player.currentTime = 0
            }
            player.play()
        } else if let wavData = generateWavData(for: targetEffect), let player = try? AVAudioPlayer(data: wavData) {
            player.play()
            audioPlayers[targetEffect] = player
        }
    }
    
    // MARK: - Sintetizador de Ondas PCM (WAV em Memória)
    
    private func generateWavData(for effect: SoundEffect) -> Data? {
        let sampleRate: Double = 44100
        var samples: [Int16] = []
        
        switch effect {
        case .moneyIn, .salary, .cashRegister:
            // MARK: 💵 Som de Dinheiro Entrando (Caixa Registradora "Cha-Ching" + Cascata de Moedas de Ouro)
            // 1. Sino Brilhante de Caixa Registradora (Acorde harmônico E6 1318Hz + C7 2093Hz + E7 2637Hz)
            samples.append(contentsOf: generateChord(
                frequencies: [1318.5, 2093.0, 2637.0],
                duration: 0.12,
                sampleRate: sampleRate,
                attack: 0.003,
                decay: 0.11,
                amplitude: 0.85
            ))
            
            // Pausa acústica de engrenagem
            samples.append(contentsOf: generateSilence(duration: 0.015, sampleRate: sampleRate))
            
            // 2. Cascata cintilante de moedas caindo no cofre (G6 1568Hz -> B6 1975Hz -> D7 2349Hz -> G7 3136Hz)
            let coinChimes: [Double] = [1567.98, 1975.53, 2349.32, 3135.96]
            for (idx, note) in coinChimes.enumerated() {
                let isLast = idx == coinChimes.count - 1
                let noteDuration = isLast ? 0.26 : 0.04
                samples.append(contentsOf: generateChord(
                    frequencies: [note, note * 1.5],
                    duration: noteDuration,
                    sampleRate: sampleRate,
                    attack: 0.002,
                    decay: isLast ? 0.24 : 0.035,
                    amplitude: isLast ? 0.8 : 0.65
                ))
            }
            
        case .moneyOut, .payment:
            // MARK: 💸 Som de Dinheiro Saindo (Deslize de Cédulas + Moeda Paga)
            // 1. Deslize rítmico de 3 notas de dinheiro saindo da carteira/dispensador
            for i in 0..<3 {
                let startF = 380.0 + Double(i * 140)
                let endF = 820.0 + Double(i * 160)
                samples.append(contentsOf: generateGlide(
                    startFreq: startF,
                    endFreq: endF,
                    duration: 0.026,
                    sampleRate: sampleRate,
                    amplitude: 0.55
                ))
                samples.append(contentsOf: generateSilence(duration: 0.010, sampleRate: sampleRate))
            }
            
            // 2. Confirmação acústica de saída de valor (Descida tonal C6 1046Hz -> G5 784Hz -> E5 659Hz)
            samples.append(contentsOf: generateGlide(
                startFreq: 1046.5,
                endFreq: 783.99,
                duration: 0.08,
                sampleRate: sampleRate,
                amplitude: 0.75
            ))
            samples.append(contentsOf: generateTone(
                frequency: 659.25,
                duration: 0.18,
                sampleRate: sampleRate,
                attack: 0.003,
                decay: 0.17,
                amplitude: 0.70
            ))
            
        case .keypadTap:
            // Clique nítido e curto: 1600Hz por 0.02s
            samples.append(contentsOf: generateTone(frequency: 1600, duration: 0.02, sampleRate: sampleRate, attack: 0.002, decay: 0.018, amplitude: 0.4))
            
        case .bankruptcy:
            // Buzzer dramático de alerta: 220Hz por 0.12s + 164Hz por 0.25s
            samples.append(contentsOf: generateTone(frequency: 220, duration: 0.12, sampleRate: sampleRate, attack: 0.01, decay: 0.10, amplitude: 0.8, isSquare: true))
            samples.append(contentsOf: generateSilence(duration: 0.03, sampleRate: sampleRate))
            samples.append(contentsOf: generateTone(frequency: 164, duration: 0.25, sampleRate: sampleRate, attack: 0.01, decay: 0.22, amplitude: 0.85, isSquare: true))
            
        case .undo:
            // Efeito de estorno (descendente de 880Hz para 440Hz por 0.16s)
            samples.append(contentsOf: generateGlide(startFreq: 880, endFreq: 440, duration: 0.16, sampleRate: sampleRate, amplitude: 0.6))
            
        case .diceRoll:
            // Ruído rítmico de dados chacoalhando (4 impactos secos)
            for i in 0..<4 {
                let freq = Double(600 + (i * 120))
                samples.append(contentsOf: generateTone(frequency: freq, duration: 0.03, sampleRate: sampleRate, attack: 0.002, decay: 0.025, amplitude: 0.6))
                samples.append(contentsOf: generateSilence(duration: 0.02, sampleRate: sampleRate))
            }
            
        case .diceDouble:
            // Fanfarra de dados iguais: C5 (523Hz), E5 (659Hz), G5 (783Hz), C6 (1046Hz)
            samples.append(contentsOf: generateTone(frequency: 523, duration: 0.06, sampleRate: sampleRate, attack: 0.005, decay: 0.05, amplitude: 0.6))
            samples.append(contentsOf: generateTone(frequency: 659, duration: 0.06, sampleRate: sampleRate, attack: 0.005, decay: 0.05, amplitude: 0.65))
            samples.append(contentsOf: generateTone(frequency: 783, duration: 0.08, sampleRate: sampleRate, attack: 0.005, decay: 0.07, amplitude: 0.7))
            samples.append(contentsOf: generateTone(frequency: 1046, duration: 0.22, sampleRate: sampleRate, attack: 0.01, decay: 0.20, amplitude: 0.8))
            
        case .coinDrop:
            // Tilintar metálico de moeda/peão de tabuleiro: B6 1975Hz + G7 3136Hz
            samples.append(contentsOf: generateChord(
                frequencies: [1975.5, 3135.9],
                duration: 0.10,
                sampleRate: sampleRate,
                attack: 0.002,
                decay: 0.09,
                amplitude: 0.7
            ))
            
        case .buttonTap:
            // Micro clique sutil: 1200Hz por 0.015s
            samples.append(contentsOf: generateTone(frequency: 1200, duration: 0.015, sampleRate: sampleRate, attack: 0.002, decay: 0.013, amplitude: 0.35))
        }
        
        return createWavData(samples: samples, sampleRate: Int(sampleRate))
    }
    
    private func generateChord(
        frequencies: [Double],
        duration: Double,
        sampleRate: Double,
        attack: Double,
        decay: Double,
        amplitude: Double
    ) -> [Int16] {
        let totalSamples = Int(duration * sampleRate)
        var samples = [Int16]()
        samples.reserveCapacity(totalSamples)
        
        let perFreqAmp = amplitude / Double(max(1, frequencies.count))
        
        for i in 0..<totalSamples {
            let t = Double(i) / sampleRate
            var envelope = 1.0
            
            if t < attack {
                envelope = t / attack
            } else if t > (duration - decay) {
                envelope = max(0, (duration - t) / decay)
            }
            
            var sampleSum = 0.0
            for freq in frequencies {
                let angle = 2.0 * .pi * freq * t
                sampleSum += sin(angle) * perFreqAmp
            }
            
            let sample = sampleSum * envelope * Double(Int16.max)
            samples.append(Int16(clamping: Int(sample)))
        }
        return samples
    }
    
    private func generateTone(
        frequency: Double,
        duration: Double,
        sampleRate: Double,
        attack: Double,
        decay: Double,
        amplitude: Double,
        isSquare: Bool = false
    ) -> [Int16] {
        let totalSamples = Int(duration * sampleRate)
        var samples = [Int16]()
        samples.reserveCapacity(totalSamples)
        
        for i in 0..<totalSamples {
            let t = Double(i) / sampleRate
            var envelope = 1.0
            
            if t < attack {
                envelope = t / attack
            } else if t > (duration - decay) {
                envelope = max(0, (duration - t) / decay)
            }
            
            let angle = 2.0 * .pi * frequency * t
            let rawValue: Double
            if isSquare {
                rawValue = sin(angle) >= 0 ? 0.7 : -0.7
            } else {
                rawValue = sin(angle)
            }
            
            let sample = rawValue * envelope * amplitude * Double(Int16.max)
            samples.append(Int16(clamping: Int(sample)))
        }
        return samples
    }
    
    private func generateGlide(
        startFreq: Double,
        endFreq: Double,
        duration: Double,
        sampleRate: Double,
        amplitude: Double
    ) -> [Int16] {
        let totalSamples = Int(duration * sampleRate)
        var samples = [Int16]()
        samples.reserveCapacity(totalSamples)
        
        var currentPhase = 0.0
        for i in 0..<totalSamples {
            let t = Double(i) / sampleRate
            let progress = t / duration
            let currentFreq = startFreq + (endFreq - startFreq) * progress
            let envelope = max(0, 1.0 - progress)
            
            currentPhase += 2.0 * .pi * currentFreq * (1.0 / sampleRate)
            let sample = sin(currentPhase) * envelope * amplitude * Double(Int16.max)
            samples.append(Int16(clamping: Int(sample)))
        }
        return samples
    }
    
    private func generateSilence(duration: Double, sampleRate: Double) -> [Int16] {
        let totalSamples = Int(duration * sampleRate)
        return [Int16](repeating: 0, count: totalSamples)
    }
    
    private func createWavData(samples: [Int16], sampleRate: Int) -> Data {
        let numChannels: Int16 = 1
        let bitsPerSample: Int16 = 16
        let byteRate: Int32 = Int32(sampleRate * Int(numChannels) * Int(bitsPerSample) / 8)
        let blockAlign: Int16 = Int16(numChannels * bitsPerSample / 8)
        let dataSize: Int32 = Int32(samples.count * 2)
        let fileSize: Int32 = 36 + dataSize
        
        var data = Data()
        
        // RIFF Header
        data.append(contentsOf: "RIFF".utf8)
        var fileSizeLE = fileSize.littleEndian
        data.append(Data(bytes: &fileSizeLE, count: 4))
        data.append(contentsOf: "WAVE".utf8)
        
        // fmt Subchunk
        data.append(contentsOf: "fmt ".utf8)
        var subchunk1Size: Int32 = Int32(16).littleEndian
        data.append(Data(bytes: &subchunk1Size, count: 4))
        var audioFormat: Int16 = Int16(1).littleEndian
        data.append(Data(bytes: &audioFormat, count: 2))
        var channelsLE: Int16 = numChannels.littleEndian
        data.append(Data(bytes: &channelsLE, count: 2))
        var sampleRateLE: Int32 = Int32(sampleRate).littleEndian
        data.append(Data(bytes: &sampleRateLE, count: 4))
        var byteRateLE: Int32 = byteRate.littleEndian
        data.append(Data(bytes: &byteRateLE, count: 4))
        var blockAlignLE: Int16 = blockAlign.littleEndian
        data.append(Data(bytes: &blockAlignLE, count: 2))
        var bitsPerSampleLE: Int16 = bitsPerSample.littleEndian
        data.append(Data(bytes: &bitsPerSampleLE, count: 2))
        
        // data Subchunk
        data.append(contentsOf: "data".utf8)
        var dataSizeLE: Int32 = dataSize.littleEndian
        data.append(Data(bytes: &dataSizeLE, count: 4))
        
        // Samples
        for sample in samples {
            var sampleLE = sample.littleEndian
            data.append(Data(bytes: &sampleLE, count: 2))
        }
        
        return data
    }
}
