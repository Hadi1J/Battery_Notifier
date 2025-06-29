//import Foundation
//import IOKit.ps
//import Combine
//
//@MainActor
//class BatteryManager: ObservableObject {
//    @Published var batteryInfo: BatteryInfo?
//    @Published var batteryHealth: BatteryHealth?
//    @Published var errorMessage: String?
//    
//    private var timer: Timer?
//    private var batteryStatusObserver: NSObjectProtocol?
//    private var lastNotifiedLevel: Int?
//    
//    private let settings: AppSettings
//    private let notificationManager: NotificationManager
//    
//    init(settings: AppSettings, notificationManager: NotificationManager) {
//        self.settings = settings
//        self.notificationManager = notificationManager
//    }
//    
//    func startMonitoring() {
//        updateBatteryInfo()
//        
//        // Set up notification observer for power source changes
//        batteryStatusObserver = NotificationCenter.default.addObserver(
//            forName: NSNotification.Name(rawValue: kIOPSNotifyPowerSource as String),
//            object: nil,
//            queue: .main
//        ) { [weak self] _ in
//            Task { @MainActor in
//                self?.updateBatteryInfo()
//            }
//        }
//        
//        // Start timer for regular updates every 30 seconds
//        timer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
//            Task { @MainActor in
//                self?.updateBatteryInfo()
//            }
//        }
//    }
//    
//    func stopMonitoring() {
//        timer?.invalidate()
//        timer = nil
//        
//        if let observer = batteryStatusObserver {
//            NotificationCenter.default.removeObserver(observer)
//            batteryStatusObserver = nil
//        }
//    }
//    
//    private func updateBatteryInfo() {
//        do {
//            let info = try getBatteryInfo()
//            let health = getBatteryHealth()
//            
//            self.batteryInfo = info
//            self.batteryHealth = health
//            self.errorMessage = nil
//            
//            checkNotificationTriggers(for: info)
//            
//        } catch let error as BatteryError {
//            self.errorMessage = error.localizedDescription
//            print("⚠️ Battery error: \(error.localizedDescription)")
//        } catch {
//            self.errorMessage = "Unknown battery error"
//            print("⚠️ Unknown battery error: \(error)")
//        }
//    }
//    
//    private func getBatteryInfo() throws -> BatteryInfo {
//        guard let blob = IOPSCopyPowerSourcesInfo()?.takeRetainedValue() else {
//            throw BatteryError.powerSourcesUnavailable
//        }
//        
//        guard let sources = IOPSCopyPowerSourcesList(blob)?.takeRetainedValue() as? [CFTypeRef] else {
//            throw BatteryError.powerSourcesListUnavailable
//        }
//        
//        guard let source = sources.first else {
//            throw BatteryError.noPowerSources
//        }
//        
//        guard let description = IOPSGetPowerSourceDescription(blob, source)?.takeUnretainedValue() as? [String: Any] else {
//            throw BatteryError.powerSourceDescriptionUnavailable
//        }
//        
//        guard let current = description[kIOPSCurrentCapacityKey as String] as? Int,
//              let max = description[kIOPSMaxCapacityKey as String] as? Int else {
//            print("📊 Available power source keys:", description.keys.sorted())
//            throw BatteryError.batteryDataUnavailable
//        }
//        
//        let isCharging = description[kIOPSIsChargingKey as String] as? Bool ?? false
//        let percentage = Int(Double(current) / Double(max) * 100)
//        let timestamp = Date()
//        
//        print(" [\(timestamp.formatted(date: .omitted, time: .shortened))] Battery: \(percentage)% | Charging: \(isCharging)")
//        
//        let health = getBatteryHealth()
//        
//        return BatteryInfo(
//            percentage: percentage,
//            isCharging: isCharging,
//            timestamp: timestamp,
//            health: health
//        )
//    }
//    
//    private func getBatteryHealth() -> BatteryHealth {
//        guard let matching = IOServiceMatching("AppleSmartBattery") else {
//            return BatteryHealth(cycleCount: -1, condition: "Unknown", healthPercentage: -1, maxCapacity: -1, designCapacity: -1)
//        }
//        
//        let service = IOServiceGetMatchingService(kIOMainPortDefault, matching)
//        guard service != 0 else {
//            return BatteryHealth(cycleCount: -1, condition: "Unknown", healthPercentage: -1, maxCapacity: -1, designCapacity: -1)
//        }
//        
//        var properties: Unmanaged<CFMutableDictionary>?
//        let result = IORegistryEntryCreateCFProperties(service, &properties, kCFAllocatorDefault, 0)
//        IOObjectRelease(service)
//        
//        guard result == KERN_SUCCESS, let propDict = properties?.takeRetainedValue() as? [String: Any] else {
//            return BatteryHealth(cycleCount: -1, condition: "Unknown", healthPercentage: -1, maxCapacity: -1, designCapacity: -1)
//        }
//        
//        let cycleCount = propDict["CycleCount"] as? Int ?? -1
//        let condition = propDict["BatteryHealthCondition"] as? String ??
//                       propDict["Condition"] as? String ??
//                       propDict["PermanentFailureStatus"] as? String ?? "Unknown"
//        
//        let maxCapacity = propDict["AppleRawMaxCapacity"] as? Int ??
//                         propDict["MaxCapacity"] as? Int ?? -1
//        let designCapacity = propDict["DesignCapacity"] as? Int ?? -1
//        
//        var actualMaxCapacity = maxCapacity
//        var healthPercentage = -1
//        
//        // Get additional capacity info from power source
//        if let blob = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
//           let sources = IOPSCopyPowerSourcesList(blob)?.takeRetainedValue() as? [CFTypeRef],
//           let source = sources.first,
//           let description = IOPSGetPowerSourceDescription(blob, source)?.takeUnretainedValue() as? [String: Any] {
//            
//            if let psMaxCapacity = description["MaxCapacity"] as? Int {
//                actualMaxCapacity = psMaxCapacity
//            }
//            
//            if designCapacity > 0 && actualMaxCapacity > 0 {
//                healthPercentage = Int(Double(actualMaxCapacity) / Double(designCapacity) * 100)
//            }
//        }
//        
//        return BatteryHealth(
//            cycleCount: cycleCount,
//            condition: condition,
//            healthPercentage: healthPercentage,
//            maxCapacity: actualMaxCapacity,
//            designCapacity: designCapacity
//        )
//    }
//    
//    private func checkNotificationTriggers(for info: BatteryInfo) {
//        if info.isCharging && info.percentage >= 80,
//           settings.notifyAbove80,
//           lastNotifiedLevel == nil || lastNotifiedLevel! < 80 {
//            print("✅ Sending 80% notification (once per session)")
//            lastNotifiedLevel = info.percentage
//            notificationManager.notify("Battery is at \(info.percentage)%. You can unplug the charger.")
//        } else if !info.isCharging && info.percentage <= 20, settings.notifyBelow20 {
//            notificationManager.notify("Battery is low (\(info.percentage)%). Plug in the charger.")
//        } else {
//            print("ℹ️ No notification triggered. Battery: \(info.percentage)% | Charging: \(info.isCharging)")
//        }
//    }
//}


import Foundation
import IOKit.ps
import Combine

@MainActor
class BatteryManager: ObservableObject {
    @Published var batteryInfo: BatteryInfo?
    @Published var batteryHealth: BatteryHealth?
    @Published var errorMessage: String?
    
    private var timer: Timer?
    private var batteryStatusObserver: NSObjectProtocol?
    
    // Enhanced notification state tracking
    private var lastNotificationStates: NotificationStates = NotificationStates()
    
    private let settings: AppSettings
    private let notificationManager: NotificationManager
    
    init(settings: AppSettings, notificationManager: NotificationManager) {
        self.settings = settings
        self.notificationManager = notificationManager
    }
    
    func startMonitoring() {
        updateBatteryInfo()
        
        // Set up notification observer for power source changes
        batteryStatusObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name(rawValue: kIOPSNotifyPowerSource as String),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.updateBatteryInfo()
            }
        }
        
        // Start timer for regular updates every 30 seconds
        timer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateBatteryInfo()
            }
        }
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        
        if let observer = batteryStatusObserver {
            NotificationCenter.default.removeObserver(observer)
            batteryStatusObserver = nil
        }
    }
    
    private func updateBatteryInfo() {
        do {
            let info = try getBatteryInfo()
            let health = getBatteryHealth()
            
            self.batteryInfo = info
            self.batteryHealth = health
            self.errorMessage = nil
            
            checkNotificationTriggers(for: info)
            
        } catch let error as BatteryError {
            self.errorMessage = error.localizedDescription
            print("⚠️ Battery error: \(error.localizedDescription)")
        } catch {
            self.errorMessage = "Unknown battery error"
            print("⚠️ Unknown battery error: \(error)")
        }
    }
    
    private func getBatteryInfo() throws -> BatteryInfo {
        guard let blob = IOPSCopyPowerSourcesInfo()?.takeRetainedValue() else {
            throw BatteryError.powerSourcesUnavailable
        }
        
        guard let sources = IOPSCopyPowerSourcesList(blob)?.takeRetainedValue() as? [CFTypeRef] else {
            throw BatteryError.powerSourcesListUnavailable
        }
        
        guard let source = sources.first else {
            throw BatteryError.noPowerSources
        }
        
        guard let description = IOPSGetPowerSourceDescription(blob, source)?.takeUnretainedValue() as? [String: Any] else {
            throw BatteryError.powerSourceDescriptionUnavailable
        }
        
        guard let current = description[kIOPSCurrentCapacityKey as String] as? Int,
              let max = description[kIOPSMaxCapacityKey as String] as? Int else {
            print("📊 Available power source keys:", description.keys.sorted())
            throw BatteryError.batteryDataUnavailable
        }
        
        let isCharging = description[kIOPSIsChargingKey as String] as? Bool ?? false
        let percentage = Int(Double(current) / Double(max) * 100)
        let timestamp = Date()
        
        print("🔋 [\(timestamp.formatted(date: .omitted, time: .shortened))] Battery: \(percentage)% | Charging: \(isCharging)")
        
        let health = getBatteryHealth()
        
        return BatteryInfo(
            percentage: percentage,
            isCharging: isCharging,
            timestamp: timestamp,
            health: health
        )
    }
    
    private func getBatteryHealth() -> BatteryHealth {
        guard let matching = IOServiceMatching("AppleSmartBattery") else {
            return BatteryHealth(
                cycleCount: -1,
                condition: "Unknown",
                healthPercentage: -1,
                maxCapacity: -1,
                designCapacity: -1
            )
        }
        
        let service = IOServiceGetMatchingService(kIOMainPortDefault, matching)
        guard service != 0 else {
            return BatteryHealth(
                cycleCount: -1,
                condition: "Unknown",
                healthPercentage: -1,
                maxCapacity: -1,
                designCapacity: -1
            )
        }
        
        var properties: Unmanaged<CFMutableDictionary>?
        let result = IORegistryEntryCreateCFProperties(service, &properties, kCFAllocatorDefault, 0)
        IOObjectRelease(service)
        
        guard result == KERN_SUCCESS,
              let propDict = properties?.takeRetainedValue() as? [String: Any] else {
            return BatteryHealth(
                cycleCount: -1,
                condition: "Unknown",
                healthPercentage: -1,
                maxCapacity: -1,
                designCapacity: -1
            )
        }
        
        // Debug: Print all available properties
        print("📊 Available battery properties:", propDict.keys.sorted())
        
        let cycleCount = propDict["CycleCount"] as? Int ?? -1
        
        // Try multiple possible keys for battery condition
        var condition = "Unknown"
        if let healthCondition = propDict["BatteryHealthCondition"] as? String {
            condition = healthCondition
        } else if let batteryCondition = propDict["Condition"] as? String {
            condition = batteryCondition
        } else if let permanentFailure = propDict["PermanentFailureStatus"] as? Int {
            condition = permanentFailure == 0 ? "Normal" : "Service Battery"
        } else if let batteryInstalled = propDict["BatteryInstalled"] as? Bool {
            condition = batteryInstalled ? "Installed" : "Not Installed"
        }
        
        let maxCapacity = propDict["AppleRawMaxCapacity"] as? Int ??
                         propDict["MaxCapacity"] as? Int ?? -1
        let designCapacity = propDict["DesignCapacity"] as? Int ?? -1
        
        var actualMaxCapacity = maxCapacity
        var healthPercentage = -1
        
        // Get additional capacity info from power source
        if let blob = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
           let sources = IOPSCopyPowerSourcesList(blob)?.takeRetainedValue() as? [CFTypeRef],
           let source = sources.first,
           let description = IOPSGetPowerSourceDescription(blob, source)?.takeUnretainedValue() as? [String: Any] {
            
            if let psMaxCapacity = description["MaxCapacity"] as? Int {
                actualMaxCapacity = psMaxCapacity
            }
            
            if designCapacity > 0 && actualMaxCapacity > 0 {
                healthPercentage = Int(Double(actualMaxCapacity) / Double(designCapacity) * 100)
            }
        }
        
        return BatteryHealth(
            cycleCount: cycleCount,
            condition: condition,
            healthPercentage: healthPercentage,
            maxCapacity: actualMaxCapacity,
            designCapacity: designCapacity
        )
    }
    
    private func checkNotificationTriggers(for info: BatteryInfo) {
        // High battery notification (charging and >= 80%)
        if info.isCharging && info.percentage >= 80 && settings.notifyAbove80 {
            if !lastNotificationStates.hasNotifiedHighBattery {
                print("✅ Sending 80% notification (first time)")
                lastNotificationStates.hasNotifiedHighBattery = true
                notificationManager.notify("Battery is at \(info.percentage)%. You can unplug the charger.", isImportant: true)
            }
        } else if !info.isCharging || info.percentage < 80 {
            // Reset high battery notification when not charging or below 80%
            lastNotificationStates.hasNotifiedHighBattery = false
        }
        
        // Low battery notification (not charging and <= 20%)
        if !info.isCharging && info.percentage <= 29 && settings.notifyBelow20 {
            if !lastNotificationStates.hasNotifiedLowBattery {
                print("✅ Sending 20% notification (first time)")
                lastNotificationStates.hasNotifiedLowBattery = true
                notificationManager.notify("Battery is low (\(info.percentage)%). Plug in the charger.", isImportant: true)
            }
        } else if info.isCharging || info.percentage > 20 {
            // Reset low battery notification when charging or above 20%
            lastNotificationStates.hasNotifiedLowBattery = false
        }
        
        // Additional debug info
        print("ℹ️ Notification states - High: \(lastNotificationStates.hasNotifiedHighBattery), Low: \(lastNotificationStates.hasNotifiedLowBattery)")
    }
}

// Helper struct to track notification states
private struct NotificationStates {
    var hasNotifiedHighBattery = false
    var hasNotifiedLowBattery = false
}
