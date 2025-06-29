import Foundation

struct BatteryInfo {
    let percentage: Int
    let isCharging: Bool
    let timestamp: Date
    let health: BatteryHealth
    
    var displayString: String {
        let timeString = timestamp.formatted(date: .omitted, time: .shortened)
        let status = isCharging ? "Charging" : "Discharging"
        return "\(percentage)% - \(status) (Updated: \(timeString))"
    }
}

struct BatteryHealth {
    let cycleCount: Int
    let condition: String
    let healthPercentage: Int
    let maxCapacity: Int
    let designCapacity: Int
    
    var displayString: String {
        var info = "🔁 Cycle Count: \(cycleCount >= 0 ? "\(cycleCount)" : "Unknown")\n"
        
        if condition != "Unknown" {
            info += "⚙️ Condition: \(condition)\n"
        }
        
        if healthPercentage >= 0 {
            info += "🔋 Battery Health: \(healthPercentage)%"
        } else if maxCapacity >= 0 && designCapacity >= 0 {
            info += "🔋 Max/Design Capacity: \(maxCapacity)/\(designCapacity) mAh"
        } else {
            info += "🔋 Battery Health: Unknown"
        }
        
        return info
    }
}

enum BatteryError: Error {
    case powerSourcesUnavailable
    case powerSourcesListUnavailable
    case noPowerSources
    case powerSourceDescriptionUnavailable
    case batteryDataUnavailable
    
    var localizedDescription: String {
        switch self {
        case .powerSourcesUnavailable:
            return "Unable to read battery"
        case .powerSourcesListUnavailable:
            return "Unable to read battery"
        case .noPowerSources:
            return "No battery found"
        case .powerSourceDescriptionUnavailable:
            return "Unable to read battery"
        case .batteryDataUnavailable:
            return "Battery data unavailable"
        }
    }
}
