//internal import Combine
//import IOKit.ps
//import ServiceManagement
//// Updated checkBattery function with better error handling and logging
//func checkBattery(batteryStatus: Binding<String>) {
//    struct Static {
//        static var lastNotifiedLevel: Int? = nil
//    }
//
//    guard let blob = IOPSCopyPowerSourcesInfo()?.takeRetainedValue() else {
//        print("⚠️ Failed to get power sources info")
//        DispatchQueue.main.async {
//            batteryStatus.wrappedValue = "Unable to read battery"
//        }
//        return
//    }
//    
//    guard let sources = IOPSCopyPowerSourcesList(blob)?.takeRetainedValue() as? [CFTypeRef] else {
//        print("⚠️ Failed to get power sources list")
//        DispatchQueue.main.async {
//            batteryStatus.wrappedValue = "Unable to read battery"
//        }
//        return
//    }
//    
//    guard let source = sources.first else {
//        print("⚠️ No power sources found")
//        DispatchQueue.main.async {
//            batteryStatus.wrappedValue = "No battery found"
//        }
//        return
//    }
//    
//    guard let description = IOPSGetPowerSourceDescription(blob, source)?.takeUnretainedValue() as? [String: Any] else {
//        print("⚠️ Failed to get power source description")
//        DispatchQueue.main.async {
//            batteryStatus.wrappedValue = "Unable to read battery"
//        }
//        return
//    }
//
//    // Debug: Print all available keys
//    print("📊 Available power source keys:", description.keys.sorted())
//
//    guard let current = description[kIOPSCurrentCapacityKey as String] as? Int,
//          let max = description[kIOPSMaxCapacityKey as String] as? Int else {
//        print("⚠️ Missing battery capacity data")
//        print("📊 Current capacity key:", kIOPSCurrentCapacityKey as String)
//        print("📊 Max capacity key:", kIOPSMaxCapacityKey as String)
//        print("📊 Available values:", description)
//        
//        DispatchQueue.main.async {
//            batteryStatus.wrappedValue = "Battery data unavailable"
//        }
//        return
//    }
//    
//    let isCharging = description[kIOPSIsChargingKey as String] as? Bool ?? false
//
//    let percentage = Int(Double(current) / Double(max) * 100)
//    let timestamp = Date().formatted(date: .omitted, time: .shortened)
//    
//    print("🔋 [\(timestamp)] Battery: \(percentage)% | Charging: \(isCharging)")
//    print("🧪 notifyAbove80 setting is", UserDefaults.standard.bool(forKey: "notifyAbove80"))
//
//    DispatchQueue.main.async {
//        batteryStatus.wrappedValue = "\(percentage)% - " + (isCharging ? "Charging" : "Discharging") + " (Updated: \(timestamp))"
//    }
//
//    // Notification logic
//    if isCharging && percentage >= 80,
//       UserDefaults.standard.bool(forKey: "notifyAbove80"),
//       Static.lastNotifiedLevel == nil || Static.lastNotifiedLevel! < 80 {
//        print("✅ Sending 80% notification (once per session)")
//        Static.lastNotifiedLevel = percentage
//        NotificationManager.shared.notify("Battery is at \(percentage)%. You can unplug the charger.")
//    } else if !isCharging && percentage <= 20, UserDefaults.standard.bool(forKey: "notifyBelow20") {
//        NotificationManager.shared.notify("Battery is low (\(percentage)%). Plug in the charger.")
//    } else {
//        print("ℹ️ No notification triggered. Battery: \(percentage)% | Charging: \(isCharging)")
//    }
//}
//import AppKit
//
//func playRingtone() {
//    let systemSound = UserDefaults.standard.string(forKey: "notificationSound") ?? "Ping"
//    if let sound = NSSound(named: systemSound), sound.play() {
//        print("🔊 Playing system sound: \(systemSound)")
//    } else {
//        NSSound(named: "Ping")?.play()
//        print("🔁 Fallback to default system sound: Ping")
//    }
//}
//
//import UserNotifications
//
//class NotificationManager {
//    static let shared = NotificationManager()
//
//    private init() {}
//
//    func notify(_ message: String) {
//        UNUserNotificationCenter.current().getNotificationSettings { settings in
//            if settings.authorizationStatus == .notDetermined {
//                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
//                    if granted {
//                        self.scheduleNotification(with: message)
//                    } else {
//                        print("❌ User denied notification permissions.")
//                    }
//                }
//            } else if settings.authorizationStatus == .authorized {
//                self.scheduleNotification(with: message)
//            } else {
//                print("❌ Notifications not authorized.")
//            }
//        }
//    }
//
//    private func scheduleNotification(with message: String) {
//        let content = UNMutableNotificationContent()
//        content.title = "Battery Alert"
//        content.body = message
//        content.sound = UNNotificationSound.default
//
//        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
//        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
//
//        UNUserNotificationCenter.current().add(request) { error in
//            if let error = error {
//                print("❌ Failed to send notification: \(error)")
//            } else {
//                print("📣 Notification sent: \(message)")
//
//                // Show fallback alert if app is frontmost
//                DispatchQueue.main.async {
//                    if NSApplication.shared.isActive {
//                        let alert = NSAlert()
//                        alert.messageText = "Battery Alert"
//                        alert.informativeText = message
//                        playRingtone()
//                        alert.runModal()
//                    }
//                }
//            }
//        }
//
//        playRingtone()
//    }
//}
//
//struct GlassBackground: NSViewRepresentable {
//    func makeNSView(context: Context) -> NSVisualEffectView {
//        let view = NSVisualEffectView()
//        view.material = .contentBackground
//        view.blendingMode = .behindWindow
//        view.state = .active
//        view.wantsLayer = true
//        view.layer?.cornerRadius = 12
//        view.layer?.masksToBounds = true
//        return view
//    }
//
//    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
//}
//
//import SwiftUI
//// Updated BatteryNotifierView with real-time updates
//struct BatteryNotifierView: View {
//    @Environment(\.colorScheme) var colorScheme
//    @AppStorage("notifyAbove80") private var notifyAbove80 = true
//    @AppStorage("notifyBelow20") private var notifyBelow20 = true
//    @AppStorage("userColorScheme") private var userColorScheme: String = "system"
//    @AppStorage("notificationSound") private var notificationSound: String = "default"
//    @AppStorage("launchAtLogin") private var launchAtLogin = false
//    @State private var batteryStatus: String = ""
//    @State private var batteryStatusObserver: NSObjectProtocol?
//    @State private var batteryHealth: String = ""
//    @State private var timer: Timer? // Add timer for regular updates
//
//    func performBatteryCheck() {
//        checkBattery(batteryStatus: $batteryStatus)
//        batteryHealth = getBatteryHealthInfo()
//    }
//
//    var body: some View {
//        VStack(alignment: .leading, spacing: 0) {
//            HStack {
//                Text("Battery Notifier")
//                    .font(.system(size: 28, weight: .bold, design: .rounded))
//                    .foregroundColor(.primary)
//                Spacer()
//            }
//            .padding(.top, 24)
//            .padding(.horizontal, 24)
//
//            Form {
//                Section(header: Text("Appearance")) {
//                    Picker("Theme", selection: $userColorScheme) {
//                        Text("System").tag("system")
//                        Text("Light").tag("light")
//                        Text("Dark").tag("dark")
//                    }
//                    .pickerStyle(SegmentedPickerStyle())
//                    Toggle("Launch at Login", isOn: $launchAtLogin)
//                        .onChange(of: launchAtLogin) {
//                            if launchAtLogin {
//                                try? SMAppService.mainApp.register()
//                            } else {
//                                try? SMAppService.mainApp.unregister()
//                            }
//                        }
//                }
//
//                Section(header: Text("Notifications")) {
//                    Toggle("Notify at ≥ 80%", isOn: $notifyAbove80)
//                    Toggle("Notify at ≤ 20%", isOn: $notifyBelow20)
//                }
//
//                Section(header: Text("Notification Sound")) {
//                    Picker("Sound", selection: $notificationSound) {
//                        Text("Ping").tag("Ping")
//                        Text("Glass").tag("Glass")
//                        Text("Funk").tag("Funk")
//                        Text("Submarine").tag("Submarine")
//                        Text("Tink").tag("Tink")
//                    }
//                    .pickerStyle(SegmentedPickerStyle())
//                    .onChange(of: notificationSound) {
//                        if let sound = NSSound(named: notificationSound) {
//                            sound.play()
//                        }
//                    }
//                }
//
//                Section(header: Text("Status")) {
//                    Text("Battery: \(batteryStatus)")
//                    Text(batteryHealth)
//                    Text("Monitoring your battery health.")
//                }
//
//                Section {
//                    Button("🔔 Test Notification") {
//                        DispatchQueue.main.async {
//                            NotificationManager.shared.notify("🔔 This is a manual test alert from BatteryNotifier.")
//                        }
//                    }
//                    .buttonStyle(PlainButtonStyle())
//                    .padding(.vertical, 6)
//                }
//            }
//            .formStyle(.grouped)
//            .padding(.horizontal, 24)
//            .frame(maxWidth: 500)
//        }
//        .padding()
//        .background(GlassBackground())
//        .frame(width: 420, height: 520)
//        .environment(\.colorScheme, {
//            switch userColorScheme {
//            case "light": return .light
//            case "dark": return .dark
//            default: return colorScheme
//            }
//        }())
//        .task {
//            performBatteryCheck()
//
//            // Set up notification observer for power source changes
//            batteryStatusObserver = NotificationCenter.default.addObserver(
//                forName: NSNotification.Name(rawValue: kIOPSNotifyPowerSource as String),
//                object: nil,
//                queue: .main
//            ) { _ in
//                performBatteryCheck()
//            }
//            
//            // Start timer for regular updates every 30 seconds
//            timer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
//                performBatteryCheck()
//            }
//        }
//        .onDisappear {
//            // Clean up timer and observer
//            timer?.invalidate()
//            timer = nil
//            
//            if let observer = batteryStatusObserver {
//                NotificationCenter.default.removeObserver(observer)
//            }
//        }
//    }
//}
//
//
//
//@main
//struct BatteryNotifierApp: App {
//    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
//
//    var body: some Scene {
//        Settings {
//            EmptyView()
//        }
//    }
//}
//
//class AppDelegate: NSObject, NSApplicationDelegate {
//    var statusItem: NSStatusItem!
//    var popover: NSPopover!
//    var eventMonitor: Any?
//
//    func applicationDidFinishLaunching(_ notification: Notification) {
//        let contentView = BatteryNotifierView()
//            .frame(width: 420, height: 520)
//
//        popover = NSPopover()
//        popover.contentSize = NSSize(width: 420, height: 520)
//        popover.behavior = .transient
//        popover.contentViewController = NSHostingController(rootView: contentView)
//
//        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
//        if let button = statusItem.button {
//            button.image = NSImage(systemSymbolName: "battery.100", accessibilityDescription: "Battery Notifier")
//            button.action = #selector(togglePopover(_:))
//        }
//    }
//
//    @objc func togglePopover(_ sender: AnyObject?) {
//        if let button = statusItem.button {
//            if popover.isShown {
//                popover.performClose(sender)
//                if let monitor = eventMonitor {
//                    NSEvent.removeMonitor(monitor)
//                    eventMonitor = nil
//                }
//            } else {
//                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
//                popover.contentViewController?.view.window?.becomeKey()
//
//                // Start monitoring for outside clicks
//                eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
//                    self?.popover.performClose(nil)
//                    if let monitor = self?.eventMonitor {
//                        NSEvent.removeMonitor(monitor)
//                        self?.eventMonitor = nil
//                    }
//                }
//            }
//        }
//    }
//}
//
//func getBatteryHealthInfo() -> String {
//    guard let matching = IOServiceMatching("AppleSmartBattery") else {
//        return "Battery Health: Unknown"
//    }
//
//    let service = IOServiceGetMatchingService(kIOMasterPortDefault, matching)
//    if service == 0 {
//        return "Battery Health: Unknown"
//    }
//
//    var properties: Unmanaged<CFMutableDictionary>?
//    let result = IORegistryEntryCreateCFProperties(service, &properties, kCFAllocatorDefault, 0)
//    IOObjectRelease(service)
//
//    guard result == KERN_SUCCESS, let propDict = properties?.takeRetainedValue() as? [String: Any] else {
//        return "Battery Health: Unknown"
//    }
//
//    // Debug: Print all available properties to see what's actually available
//    print("Available battery properties:", propDict.keys.sorted())
//
//    let cycleCount = propDict["CycleCount"] as? Int ?? -1
//    
//    // Try different possible keys for condition/health
//    let condition = propDict["BatteryHealthCondition"] as? String ??
//                   propDict["Condition"] as? String ??
//                   propDict["PermanentFailureStatus"] as? String ?? "Unknown"
//    
//    // Try different capacity keys
//    let maxCapacity = propDict["AppleRawMaxCapacity"] as? Int ??
//                     propDict["MaxCapacity"] as? Int ?? -1
//    
//    let designCapacity = propDict["DesignCapacity"] as? Int ?? -1
//    
//    // Alternative approach: get current max capacity from power source info
//    var actualMaxCapacity = maxCapacity
//    var healthPercentage = -1
//    
//    if let blob = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
//       let sources = IOPSCopyPowerSourcesList(blob)?.takeRetainedValue() as? [CFTypeRef],
//       let source = sources.first,
//       let description = IOPSGetPowerSourceDescription(blob, source)?.takeUnretainedValue() as? [String: Any] {
//        
//        if let psMaxCapacity = description["MaxCapacity"] as? Int {
//            actualMaxCapacity = psMaxCapacity
//        }
//        
//        // Calculate health percentage if we have both values
//        if designCapacity > 0 && actualMaxCapacity > 0 {
//            healthPercentage = Int(Double(actualMaxCapacity) / Double(designCapacity) * 100)
//        }
//    }
//
//    // Format the output
//    var healthInfo = "🔁 Cycle Count: \(cycleCount >= 0 ? "\(cycleCount)" : "Unknown")\n"
//    
//    if condition != "Unknown" {
//        healthInfo += "⚙️ Condition: \(condition)\n"
//    }
//    
//    if healthPercentage >= 0 {
//        healthInfo += "🔋 Battery Health: \(healthPercentage)%"
//    } else if actualMaxCapacity >= 0 && designCapacity >= 0 {
//        healthInfo += "🔋 Max/Design Capacity: \(actualMaxCapacity)/\(designCapacity) mAh"
//    } else {
//        healthInfo += "🔋 Battery Health: Unknown"
//    }
//
//    return healthInfo
//}

//import SwiftUI
//internal import Combine
//import IOKit.ps
//import ServiceManagement
//import AppKit
//import UserNotifications
//import Charts
//
//
//@main
//struct BatteryNotifierApp: App {
//    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
//
//    var body: some Scene {
//        Settings {
//            EmptyView()
//        }
//    }
//}
//
//class AppDelegate: NSObject, NSApplicationDelegate {
//    var statusItem: NSStatusItem!
//    var popover: NSPopover!
//    var eventMonitor: Any?
//    var batteryManager = BatteryManager() // Add this line
//
//    func applicationDidFinishLaunching(_ notification: Notification) {
//        // Use the enhanced view instead of the old one
//        let contentView = EnhancedBatteryNotifierView()
//            .frame(width: 520, height: 600) // Updated size
//
//        popover = NSPopover()
//        popover.contentSize = NSSize(width: 520, height: 600) // Updated size
//        popover.behavior = .transient
//        popover.contentViewController = NSHostingController(rootView: contentView)
//
//        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
//        if let button = statusItem.button {
//            button.image = NSImage(systemSymbolName: "battery.100", accessibilityDescription: "Battery Notifier")
//            button.action = #selector(togglePopover(_:))
//        }
//        
//        // Start monitoring immediately
//        batteryManager.startMonitoring()
//    }
//
//    @objc func togglePopover(_ sender: AnyObject?) {
//        if let button = statusItem.button {
//            if popover.isShown {
//                popover.performClose(sender)
//                if let monitor = eventMonitor {
//                    NSEvent.removeMonitor(monitor)
//                    eventMonitor = nil
//                }
//            } else {
//                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
//                popover.contentViewController?.view.window?.becomeKey()
//
//                eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
//                    self?.popover.performClose(nil)
//                    if let monitor = self?.eventMonitor {
//                        NSEvent.removeMonitor(monitor)
//                        self?.eventMonitor = nil
//                    }
//                }
//            }
//        }
//    }
//}



import SwiftUI

@main
struct BatteryNotifierApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
