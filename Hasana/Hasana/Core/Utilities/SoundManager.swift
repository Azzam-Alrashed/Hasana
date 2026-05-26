import Foundation
import AVFoundation

final class SoundManager {
    static let shared = SoundManager()
    
    private var audioPlayer: AVAudioPlayer?
    private var isMuted: Bool = true
    
    private init() {
        self.isMuted = UserDefaults.standard.bool(forKey: "hasana.sound.muted")
    }
    
    func setMuted(_ muted: Bool) {
        self.isMuted = muted
        UserDefaults.standard.set(muted, forKey: "hasana.sound.muted")
        
        if muted {
            stopAmbientSound()
        } else {
            playAmbientSound()
        }
    }
    
    func toggleMuted() -> Bool {
        setMuted(!isMuted)
        return isMuted
    }
    
    func getMuted() -> Bool {
        isMuted
    }
    
    func playAmbientSound() {
        guard !isMuted else { return }
        
        guard let soundURL = Bundle.main.url(forResource: "ambient", withExtension: "mp3") else {
            print("Ambient audio asset not found in bundle. Playback skipped.")
            return
        }
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.numberOfLoops = -1 // Infinite loop
            audioPlayer?.volume = 0.35 // Subtle background volume
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
        } catch {
            print("Error initializing audio playback: \(error.localizedDescription)")
        }
    }
    
    func stopAmbientSound() {
        audioPlayer?.stop()
        audioPlayer = nil
    }
}
