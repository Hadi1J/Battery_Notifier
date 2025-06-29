import SwiftUI

struct BatteryNotifierView: View {
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var settings = AppSettings()
    @StateObject private var batteryManager: BatteryManager
    
    init() {
        // Create settings first
        let settings = AppSettings()
        // Create battery manager with settings and notification manager
        let batteryManager = BatteryManager(
            settings: settings,
            notificationManager: NotificationManager.shared
        )
        // Use _StateObject to initialize properly
        self._settings = StateObject(wrappedValue: settings)
        self._batteryManager = StateObject(wrappedValue: batteryManager)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerView
            
            Form {
                appearanceSection
                notificationSection
                soundSection
                statusSection
                testSection
            }
            .formStyle(.grouped)
            .padding(.horizontal, 24)
            .frame(maxWidth: 500)
        }
        .padding()
        .background(GlassBackground())
        .frame(width: 420, height: 520)
        .environment(\.colorScheme, resolvedColorScheme)
        .task {
            await MainActor.run {
                batteryManager.startMonitoring()
            }
        }
        .onDisappear {
            batteryManager.stopMonitoring()
        }
    }
    
    private var headerView: some View {
        HStack {
            Text("Battery Notifier")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            Spacer()
        }
        .padding(.top, 24)
        .padding(.horizontal, 24)
    }
    
    private var appearanceSection: some View {
        Section(header: Text("Appearance")) {
            Picker("Theme", selection: $settings.userColorScheme) {
                Text("System").tag("system")
                Text("Light").tag("light")
                Text("Dark").tag("dark")
            }
            .pickerStyle(SegmentedPickerStyle())
            
            Toggle("Launch at Login", isOn: $settings.launchAtLogin)
        }
    }
    
    private var notificationSection: some View {
        Section(header: Text("Notifications")) {
            Toggle("Notify at ≥ 80%", isOn: $settings.notifyAbove80)
            Toggle("Notify at ≤ 20%", isOn: $settings.notifyBelow20)
        }
    }
    
    private var soundSection: some View {
        Section(header: Text("Notification Sound")) {
            Picker("Sound", selection: $settings.notificationSound) {
                Text("Ping").tag("Ping")
                Text("Glass").tag("Glass")
                Text("Funk").tag("Funk")
                Text("Submarine").tag("Submarine")
                Text("Tink").tag("Tink")
            }
            .pickerStyle(SegmentedPickerStyle())
            .onChange(of: settings.notificationSound) { oldValue, newValue in
                SoundManager().playTestSound(newValue)
            }
        }
    }
    
    private var statusSection: some View {
        Section(header: Text("Status")) {
            if let batteryInfo = batteryManager.batteryInfo {
                Text("Battery: \(batteryInfo.displayString)")
                Text(batteryInfo.health.displayString)
            } else if let errorMessage = batteryManager.errorMessage {
                Text("Battery: \(errorMessage)")
                    .foregroundColor(.secondary)
            } else {
                Text("Battery: Loading...")
                    .foregroundColor(.secondary)
            }
            
            Text("Monitoring your battery health.")
        }
    }
    
    private var testSection: some View {
        Section {
            Button("🔔 Test Notification") {
                NotificationManager.shared.notify("🔔 This is a manual test alert from BatteryNotifier.")
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.vertical, 6)
        }
    }
    
    private var resolvedColorScheme: ColorScheme {
        switch settings.userColorScheme {
        case "light": return .light
        case "dark": return .dark
        default: return colorScheme
        }
    }
}
