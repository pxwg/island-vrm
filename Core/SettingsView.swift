import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings = CameraSettings.shared
    @State private var selectedTab: SettingsTab = .head
    @Environment(\.dismiss) private var dismiss
    
    // Callback for when Body tab is selected (triggers God Mode)
    var onBodyModeSelected: ((Bool) -> Void)?
    
    enum SettingsTab: String, CaseIterable {
        case head = "Head Mode"
        case body = "Body Mode"
        case about = "About"
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Head Mode Tab
            CameraModeSettingsView(
                mode: "Head",
                setting: $settings.config.head,
                onSave: {
                    settings.save()
                    SharedWebViewHelper.shared.updateCameraConfig()
                }
            )
            .tabItem {
                Label("Head Mode", systemImage: "person.crop.circle")
            }
            .tag(SettingsTab.head)
            
            // Body Mode Tab
            CameraModeSettingsView(
                mode: "Body",
                setting: $settings.config.body,
                onSave: {
                    settings.save()
                    SharedWebViewHelper.shared.updateCameraConfig()
                }
            )
            .tabItem {
                Label("Body Mode", systemImage: "figure.stand")
            }
            .tag(SettingsTab.body)
            
            // About Tab
            AboutView()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
                .tag(SettingsTab.about)
        }
        .frame(width: 600, height: 450)
        .onChange(of: selectedTab) { _, newValue in
            // Trigger God Mode when Body tab is selected
            onBodyModeSelected?(newValue == .body)
        }
        .onAppear {
            // If Body tab is already selected, trigger God Mode
            if selectedTab == .body {
                onBodyModeSelected?(true)
            }
        }
        .onDisappear {
            // Exit God Mode when settings panel closes
            onBodyModeSelected?(false)
        }
    }
}

// MARK: - Camera Mode Settings View
struct CameraModeSettingsView: View {
    let mode: String
    @Binding var setting: CameraSetting
    let onSave: () -> Void
    
    var body: some View {
        Form {
            Section("Camera Position") {
                HStack {
                    Text("X:")
                        .frame(width: 30, alignment: .leading)
                    Slider(value: $setting.position.x, in: -5...5, step: 0.01)
                    Text(String(format: "%.3f", setting.position.x))
                        .frame(width: 60, alignment: .trailing)
                        .monospacedDigit()
                }
                
                HStack {
                    Text("Y:")
                        .frame(width: 30, alignment: .leading)
                    Slider(value: $setting.position.y, in: -5...5, step: 0.01)
                    Text(String(format: "%.3f", setting.position.y))
                        .frame(width: 60, alignment: .trailing)
                        .monospacedDigit()
                }
                
                HStack {
                    Text("Z:")
                        .frame(width: 30, alignment: .leading)
                    Slider(value: $setting.position.z, in: -5...5, step: 0.01)
                    Text(String(format: "%.3f", setting.position.z))
                        .frame(width: 60, alignment: .trailing)
                        .monospacedDigit()
                }
            }
            
            Section("Look At Target") {
                HStack {
                    Text("X:")
                        .frame(width: 30, alignment: .leading)
                    Slider(value: $setting.target.x, in: -5...5, step: 0.01)
                    Text(String(format: "%.3f", setting.target.x))
                        .frame(width: 60, alignment: .trailing)
                        .monospacedDigit()
                }
                
                HStack {
                    Text("Y:")
                        .frame(width: 30, alignment: .leading)
                    Slider(value: $setting.target.y, in: -5...5, step: 0.01)
                    Text(String(format: "%.3f", setting.target.y))
                        .frame(width: 60, alignment: .trailing)
                        .monospacedDigit()
                }
                
                HStack {
                    Text("Z:")
                        .frame(width: 30, alignment: .leading)
                    Slider(value: $setting.target.z, in: -5...5, step: 0.01)
                    Text(String(format: "%.3f", setting.target.z))
                        .frame(width: 60, alignment: .trailing)
                        .monospacedDigit()
                }
            }
            
            Section("Field of View") {
                HStack {
                    Text("FOV:")
                        .frame(width: 50, alignment: .leading)
                    Slider(value: $setting.fov, in: 10...120, step: 1)
                    Text(String(format: "%.0f°", setting.fov))
                        .frame(width: 50, alignment: .trailing)
                        .monospacedDigit()
                }
            }
            
            Section {
                HStack {
                    Spacer()
                    Button("Reset to Default") {
                        CameraSettings.shared.reset()
                        onSave()
                    }
                    .foregroundColor(.red)
                    
                    Button("Apply Changes") {
                        onSave()
                    }
                    .buttonStyle(.borderedProminent)
                    Spacer()
                }
            }
        }
        .formStyle(.grouped)
        .onChange(of: setting) { _, _ in
            // Auto-save on any change for real-time feedback
            onSave()
        }
    }
}

// MARK: - About View
struct AboutView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "figure.stand")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Island VRM")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Version 1.0.0")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Divider()
                .padding(.horizontal, 40)
            
            VStack(alignment: .leading, spacing: 10) {
                Text("A native macOS application for displaying VRM models in the Dynamic Island.")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Text("Features:")
                    .font(.headline)
                    .padding(.top)
                
                VStack(alignment: .leading, spacing: 5) {
                    Label("Real-time camera configuration", systemImage: "camera.fill")
                    Label("Native persistence with UserDefaults", systemImage: "externaldrive.fill")
                    Label("God Mode for distraction-free editing", systemImage: "eye.fill")
                    Label("Instant visual feedback", systemImage: "bolt.fill")
                }
                .padding(.leading, 20)
            }
            .frame(maxWidth: 400)
            
            Spacer()
            
            Text("© 2024 PXWG. All rights reserved.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preview
#Preview("Settings - Head Mode") {
    SettingsView()
}
