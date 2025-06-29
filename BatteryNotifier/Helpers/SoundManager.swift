import AppKit
import Foundation

class SoundManager {
    func playNotificationSound() {
        let systemSound = UserDefaults.standard.string(forKey: "notificationSound") ?? "Ping"
        if let sound = NSSound(named: systemSound), sound.play() {
            print("🔊 Playing system sound: \(systemSound)")
        } else {
            NSSound(named: "Ping")?.play()
            print("🔁 Fallback to default system sound: Ping")
        }
    }
    
    func playTestSound(_ soundName: String) {
        if let sound = NSSound(named: soundName) {
            sound.play()
        }
    }
}
