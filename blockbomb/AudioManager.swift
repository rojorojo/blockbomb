import AVFoundation
import UIKit

// MARK: - Audio Manager
class AudioManager: ObservableObject {
    static let shared = AudioManager()
    
    // MARK: - Properties
    @Published var masterVolume: Float = 1.0 {
        didSet {
            UserDefaults.standard.set(masterVolume, forKey: "masterVolume")
            updateAllVolumes()
        }
    }
    
    @Published var sfxVolume: Float = 1.0 {
        didSet {
            UserDefaults.standard.set(sfxVolume, forKey: "sfxVolume")
            updateAllVolumes()
        }
    }
    
    @Published var isMuted: Bool = false {
        didSet {
            UserDefaults.standard.set(isMuted, forKey: "isMuted")
            updateAllVolumes()
        }
    }
    
    // Audio players for different sound types
    private var soundEffects: [String: AVAudioPlayer] = [:]
    private var audioEngine = AVAudioEngine()
    private var audioPlayerNodes: [String: AVAudioPlayerNode] = [:]
    private var audioBuffers: [String: AVAudioPCMBuffer] = [:]
    
    // MARK: - Initialization
    private init() {
        loadUserPreferences()
        setupAudioSession()
        setupAudioEngine()
        preloadSoundEffects()
    }
    
    // MARK: - Audio Session Setup
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try audioSession.setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    // MARK: - Audio Engine Setup
    private func setupAudioEngine() {
        do {
            try audioEngine.start()
        } catch {
            print("Failed to start audio engine: \(error)")
        }
    }
    
    // MARK: - User Preferences
    private func loadUserPreferences() {
        masterVolume = UserDefaults.standard.object(forKey: "masterVolume") as? Float ?? 1.0
        sfxVolume = UserDefaults.standard.object(forKey: "sfxVolume") as? Float ?? 1.0
        isMuted = UserDefaults.standard.bool(forKey: "isMuted")
    }
    
    // MARK: - Sound Effect Management
    private func preloadSoundEffects() {
        let soundFiles = [
            "block_place",
            "line_clear_single", 
            "line_clear_double",
            "line_clear_triple",
            "line_clear_quad",
            "combo_small",
            "combo_medium", 
            "combo_large",
            "game_over",
            "new_high_score",
            "invalid_placement",
            "revive-heart"
        ]
        
        for soundFile in soundFiles {
            loadSoundEffect(named: soundFile)
        }
    }
    
    private func loadSoundEffect(named fileName: String) {
        // Try to load from NSDataAsset first (for Assets.xcassets datasets)
        if let dataAsset = NSDataAsset(name: fileName) {
            do {
                // Load for AVAudioPlayer (backup method)
                let player = try AVAudioPlayer(data: dataAsset.data)
                player.prepareToPlay()
                player.volume = calculateEffectiveVolume()
                soundEffects[fileName] = player
                
                // Create temporary file for AVAudioEngine (which needs a file URL)
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(fileName).wav")
                try dataAsset.data.write(to: tempURL)
                
                // Load for AVAudioEngine (primary method for low latency)
                let audioFile = try AVAudioFile(forReading: tempURL)
                guard let buffer = AVAudioPCMBuffer(pcmFormat: audioFile.processingFormat, frameCapacity: AVAudioFrameCount(audioFile.length)) else {
                    print("Could not create buffer for \(fileName)")
                    return
                }
                
                try audioFile.read(into: buffer)
                audioBuffers[fileName] = buffer
                
                // Create player node
                let playerNode = AVAudioPlayerNode()
                audioEngine.attach(playerNode)
                audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: buffer.format)
                audioPlayerNodes[fileName] = playerNode
                
                print("Successfully loaded sound: \(fileName)")
                
            } catch {
                print("Error loading sound effect from data asset \(fileName): \(error)")
            }
        }
        // Fallback to bundle resource loading
        else if let url = Bundle.main.url(forResource: fileName, withExtension: "wav") {
            do {
                // Load for AVAudioPlayer (backup method)
                let player = try AVAudioPlayer(contentsOf: url)
                player.prepareToPlay()
                player.volume = calculateEffectiveVolume()
                soundEffects[fileName] = player
                
                // Load for AVAudioEngine (primary method for low latency)
                let audioFile = try AVAudioFile(forReading: url)
                guard let buffer = AVAudioPCMBuffer(pcmFormat: audioFile.processingFormat, frameCapacity: AVAudioFrameCount(audioFile.length)) else {
                    print("Could not create buffer for \(fileName)")
                    return
                }
                
                try audioFile.read(into: buffer)
                audioBuffers[fileName] = buffer
                
                // Create player node
                let playerNode = AVAudioPlayerNode()
                audioEngine.attach(playerNode)
                audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: buffer.format)
                audioPlayerNodes[fileName] = playerNode
                
                print("Successfully loaded sound from bundle: \(fileName)")
                
            } catch {
                print("Error loading sound effect from bundle \(fileName): \(error)")
            }
        } else {
            print("Could not find sound file: \(fileName) (tried both NSDataAsset and bundle resources)")
        }
    }
    
    // MARK: - Volume Control
    private func calculateEffectiveVolume() -> Float {
        return isMuted ? 0.0 : (masterVolume * sfxVolume)
    }
    
    private func updateAllVolumes() {
        let volume = calculateEffectiveVolume()
        
        // Update AVAudioPlayer volumes
        for player in soundEffects.values {
            player.volume = volume
        }
        
        // Update audio engine main mixer volume
        audioEngine.mainMixerNode.outputVolume = volume
    }
    
    // MARK: - Sound Playback
    func playSound(_ soundName: String, volume: Float = 1.0) {
        print("Attempting to play sound: \(soundName), isMuted: \(isMuted)")
        guard !isMuted else { 
            print("Audio is muted, not playing sound")
            return 
        }
        
        // Try AVAudioEngine first for low latency
        if let playerNode = audioPlayerNodes[soundName],
           let buffer = audioBuffers[soundName] {
            
            print("Playing \(soundName) with AVAudioEngine")
            
            // Stop if already playing
            if playerNode.isPlaying {
                playerNode.stop()
            }
            
            // Schedule and play buffer
            playerNode.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
            if !playerNode.isPlaying {
                playerNode.play()
            }
        }
        // Fallback to AVAudioPlayer
        else if let player = soundEffects[soundName] {
            print("Playing \(soundName) with AVAudioPlayer (fallback)")
            player.currentTime = 0
            player.volume = calculateEffectiveVolume() * volume
            player.play()
        } else {
            print("Sound not found: \(soundName)")
            print("Available sounds: \(Array(soundEffects.keys))")
            print("Available engine sounds: \(Array(audioPlayerNodes.keys))")
        }
    }
    
    // MARK: - Game-Specific Sound Methods
    func playBlockPlaceSound() {
        playSound("block_place")
    }
    
    func playLineClearSound(lineCount: Int) {
        let soundName: String
        switch lineCount {
        case 1:
            soundName = "line_clear_single"
        case 2:
            soundName = "line_clear_double"
        case 3:
            soundName = "line_clear_triple"
        case 4...Int.max:
            soundName = "line_clear_quad"
        default:
            return
        }
        playSound(soundName)
    }
    
    func playComboSound(comboLevel: Int) {
        let soundName: String
        switch comboLevel {
        case 1...2:
            soundName = "combo_small"
        case 3...4:
            soundName = "combo_medium"
        case 5...Int.max:
            soundName = "combo_large"
        default:
            soundName = "combo_small"
        }
        playSound(soundName, volume: min(1.0, 0.7 + Float(comboLevel) * 0.1))
    }
    
    func playGameOverSound() {
        playSound("game_over")
    }
    
    func playNewHighScoreSound() {
        playSound("new_high_score")
    }
    
    func playInvalidPlacementSound() {
        playSound("invalid_placement", volume: 0.5)
    }
    
    func playReviveSound() {
        playSound("revive-heart", volume: 0.8)
    }
    
    // MARK: - Accessibility Support
    func triggerHapticFeedback(for event: GameAudioEvent) {
        guard UIDevice.current.userInterfaceIdiom == .phone else { return }
        
        switch event {
        case .blockPlace:
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
        case .lineClear:
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
        case .combo:
            let impact = UIImpactFeedbackGenerator(style: .heavy)
            impact.impactOccurred()
        case .gameOver:
            let notification = UINotificationFeedbackGenerator()
            notification.notificationOccurred(.error)
        case .newHighScore:
            let notification = UINotificationFeedbackGenerator()
            notification.notificationOccurred(.success)
        case .invalidPlacement:
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred(intensity: 0.5)
        case .revive:
            let notification = UINotificationFeedbackGenerator()
            notification.notificationOccurred(.success)
        }
    }
}

// MARK: - Game Audio Events
enum GameAudioEvent {
    case blockPlace
    case lineClear
    case combo
    case gameOver
    case newHighScore
    case invalidPlacement
    case revive
}
