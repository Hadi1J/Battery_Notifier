import UserNotifications
import AppKit

class NotificationManager {
    static let shared = NotificationManager()
    
    private let soundManager = SoundManager()
    
    private init() {}
    
    func notify(_ message: String, isImportant: Bool = false) {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            if settings.authorizationStatus == .notDetermined {
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                    if granted {
                        self?.scheduleNotification(with: message, isImportant: isImportant)
                    } else {
                        print("❌ User denied notification permissions.")
                        // Show alert even without permission
                        self?.showForcedAlert(message: message)
                    }
                }
            } else if settings.authorizationStatus == .authorized {
                self?.scheduleNotification(with: message, isImportant: isImportant)
            } else {
                print("❌ Notifications not authorized. Showing forced alert.")
                // Show alert even without permission
                self?.showForcedAlert(message: message)
            }
        }
    }
    
    private func scheduleNotification(with message: String, isImportant: Bool) {
        let content = UNMutableNotificationContent()
        content.title = "Battery Alert"
        content.body = message
        content.sound = UNNotificationSound.default
        
        // Make notification more prominent for important alerts
        if isImportant {
            content.badge = 1
            content.categoryIdentifier = "BATTERY_ALERT"
        }
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.5, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { [weak self] error in
            if let error = error {
                print("❌ Failed to send notification: \(error)")
                // Fallback to forced alert
                self?.showForcedAlert(message: message)
            } else {
                print("📣 Notification sent: \(message)")
            }
        }
        
        // Always show the prominent alert for important notifications
        if isImportant {
            showForcedAlert(message: message)
        }
        
        soundManager.playNotificationSound()
    }
    
    private func showForcedAlert(message: String) {
        DispatchQueue.main.async { [weak self] in
            let alert = NSAlert()
            alert.messageText = "🔋 Battery Alert"
            alert.informativeText = message
            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK")
            
            // Play sound before showing alert
            self?.soundManager.playNotificationSound()
            
            // Make the app temporarily active to ensure visibility
            NSApplication.shared.activate(ignoringOtherApps: true)
            
            // Use runModal() for system-centered alert positioning
            // This creates a modal alert that appears centered on screen like system dialogs
            alert.runModal()
        }
    }
}
