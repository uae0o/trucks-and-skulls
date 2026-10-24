import Foundation
import AVFoundation
import UIKit

public class AudioManager {
    public static let shared = AudioManager()

    private var musicPlayer: AVAudioPlayer?
    private var sfxPlayers: [String: AVAudioPlayer] = [:]
    private let hapticImpact = UIImpactFeedbackGenerator(style: .heavy)
    private let hapticNotification = UINotificationFeedbackGenerator()

    private init() {
        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
        hapticImpact.prepare()
    }

    public func playMusic(named name: String = "TrucksAndSkulls_Music") {
        guard let url = findAudioURL(named: name) else { return }
        do {
            musicPlayer = try AVAudioPlayer(contentsOf: url)
            musicPlayer?.numberOfLoops = -1 // loop forever
            musicPlayer?.volume = 0.6
            musicPlayer?.play()
        } catch {
            print("Failed to play music: \(error)")
        }
    }

    public func stopMusic() {
        musicPlayer?.stop()
    }

    public func playSFX(named name: String, volume: Float = 1.0) {
        guard let url = findAudioURL(named: name) else { return }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = volume
            player.play()
            sfxPlayers[name] = player
        } catch {
            print("Failed to play SFX: \(error)")
        }
    }

    public func triggerHaptic(style: UIImpactFeedbackGenerator.FeedbackStyle = .heavy) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }

    public func triggerWinHaptic() {
        hapticNotification.notificationOccurred(.success)
    }

    private func findAudioURL(named name: String) -> URL? {
        let clean = name.replacingOccurrences(of: ".wav", with: "")
        if let url = Bundle.main.url(forResource: clean, withExtension: "wav") { return url }
        for sub in ["Audio", "Resources/Audio"] {
            if let url = Bundle.main.url(forResource: clean, withExtension: "wav", subdirectory: sub) {
                return url
            }
        }
        if let urls = Bundle.main.urls(forResourcesWithExtension: "wav", subdirectory: nil) {
            if let match = urls.first(where: { $0.deletingPathExtension().lastPathComponent.lowercased() == clean.lowercased() }) {
                return match
            }
        }
        return nil
    }
}
