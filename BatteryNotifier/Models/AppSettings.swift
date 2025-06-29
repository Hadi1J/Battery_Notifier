import Foundation
import ServiceManagement
import Combine

@MainActor
class AppSettings: ObservableObject {
    @Published var notifyAbove80: Bool {
        didSet { UserDefaults.standard.set(notifyAbove80, forKey: "notifyAbove80") }
    }
    
    @Published var notifyBelow20: Bool {
        didSet { UserDefaults.standard.set(notifyBelow20, forKey: "notifyBelow20") }
    }
    
    @Published var userColorScheme: String {
        didSet { UserDefaults.standard.set(userColorScheme, forKey: "userColorScheme") }
    }
    
    @Published var notificationSound: String {
        didSet { UserDefaults.standard.set(notificationSound, forKey: "notificationSound") }
    }
    
    @Published var launchAtLogin: Bool {
        didSet {
            UserDefaults.standard.set(launchAtLogin, forKey: "launchAtLogin")
            updateLaunchAtLogin()
        }
    }
    
    init() {
        self.notifyAbove80 = UserDefaults.standard.bool(forKey: "notifyAbove80", defaultValue: true)
        self.notifyBelow20 = UserDefaults.standard.bool(forKey: "notifyBelow20", defaultValue: true)
        self.userColorScheme = UserDefaults.standard.string(forKey: "userColorScheme") ?? "system"
        self.notificationSound = UserDefaults.standard.string(forKey: "notificationSound") ?? "Ping"
        self.launchAtLogin = UserDefaults.standard.bool(forKey: "launchAtLogin")
    }
    
    private func updateLaunchAtLogin() {
        if launchAtLogin {
            try? SMAppService.mainApp.register()
        } else {
            try? SMAppService.mainApp.unregister()
        }
    }
}
