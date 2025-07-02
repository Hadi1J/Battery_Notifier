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
        var components: [String] = []
        
        // Cycle count
        if cycleCount >= 0 {
            components.append("🔁 Cycles: \(cycleCount)")
        }
        
        // Condition - always show if available
        if condition != "Unknown" && !condition.isEmpty {
            let conditionIcon = getConditionIcon(condition)
            components.append("\(conditionIcon) Condition: \(condition)")
        }
        
        // Health percentage
        if healthPercentage >= 0 {
            let healthIcon = getHealthIcon(healthPercentage)
            components.append("\(healthIcon) Health: \(healthPercentage)%")
        } else if maxCapacity > 0 && designCapacity > 0 {
            components.append("🔋 Capacity: \(maxCapacity)/\(designCapacity) mAh")
        }
        
        // If no components, show unknown
        if components.isEmpty {
            components.append("🔋 Battery Health: Unknown")
        }
        
        return components.joined(separator: "\n")
    }
    
    private func getConditionIcon(_ condition: String) -> String {
        let lowerCondition = condition.lowercased()
        if lowerCondition.contains("normal") || lowerCondition.contains("good") {
            return "✅"
        } else if lowerCondition.contains("service") || lowerCondition.contains("replace") {
            return "⚠️"
        } else if lowerCondition.contains("fair") || lowerCondition.contains("check") {
            return "🟡"
        } else {
            return "ℹ️"
        }
    }
    
    private func getHealthIcon(_ percentage: Int) -> String {
        if percentage >= 80 {
            return "💚"
        } else if percentage >= 60 {
            return "🟡"
        } else {
            return "🔴"
        }
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
