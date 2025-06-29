import UserNotifications
import AppKit

class NotificationManager {
    static let shared = NotificationManager()
    
    private let soundManager = SoundManager()
    
    private init() {}
    
    func notify(_ message: String) {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            if settings.authorizationStatus == .notDetermined {
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
                    if granted {
                        self?.scheduleNotification(with: message)
                    } else {
                        print("❌ User denied notification permissions.")
                    }
                }
            } else if settings.authorizationStatus == .authorized {
                self?.scheduleNotification(with: message)
            } else {
                print("❌ Notifications not authorized.")
            }
        }
    }
    
    private func scheduleNotification(with message: String) {
        let content = UNMutableNotificationContent()
        content.title = "Battery Alert"
        content.body = message
        content.sound = UNNotificationSound.default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { [weak self] error in
            if let error = error {
                print("❌ Failed to send notification: \(error)")
            } else {
                print("📣 Notification sent: \(message)")
                
                // Show fallback alert if app is frontmost
                DispatchQueue.main.async {
                    if NSApplication.shared.isActive {
                        let alert = NSAlert()
                        alert.messageText = "Battery Alert"
                        alert.informativeText = message
                        self?.soundManager.playNotificationSound()
                        alert.runModal()
                    }
                }
            }
        }
        
        soundManager.playNotificationSound()
    }
}
