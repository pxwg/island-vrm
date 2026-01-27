import SwiftUI

public struct SettingsView: View {
    @ObservedObject var settings = CameraSettings.shared
    @State private var selectedTab: SettingsTab = .general

    public var onBodyModeSelected: ((Bool) -> Void)?

    public init(onBodyModeSelected: ((Bool) -> Void)? = nil) {
        self.onBodyModeSelected = onBodyModeSelected
    }

    enum SettingsTab: String, CaseIterable {
        case general = "General"
        case head = "Head Mode"
        case body = "Body Mode"
    }

    public var body: some View {
        TabView(selection: $selectedTab) {
            GeneralSettingsView(settings: settings)
                .tabItem { Label("General", systemImage: "gearshape") }
                .tag(SettingsTab.general)

            CameraModeSettingsView(
                mode: "Head",
                setting: $settings.config.head,
                onSave: { settings.save() }
            )
            .tabItem { Label("Head Mode", systemImage: "person.crop.circle") }
            .tag(SettingsTab.head)

            CameraModeSettingsView(
                mode: "Body",
                setting: $settings.config.body,
                onSave: { settings.save() }
            )
            .tabItem { Label("Body Mode", systemImage: "figure.stand") }
            .tag(SettingsTab.body)
        }
        .frame(width: 600, height: 450)
        .onChange(of: selectedTab) { _, newValue in
            onBodyModeSelected?(newValue == .body)
        }
        .onAppear {
            if selectedTab == .body { onBodyModeSelected?(true) }
        }
        .onDisappear {
            onBodyModeSelected?(false)
        }
    }
}

struct GeneralSettingsView: View {
    @ObservedObject var settings: CameraSettings

    var body: some View {
        Form {
            Section("Behavior") {
                Toggle("Look at Mouse Cursor", isOn: $settings.config.followMouse)
                    .onChange(of: settings.config.followMouse) { _, _ in
                        settings.save()
                        SharedWebViewHelper.shared.updateCameraConfig()
                    }
                Text("When disabled, the character will look straight forward regardless of mouse position.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
    }
}

struct CameraModeSettingsView: View {
    let mode: String
    @Binding var setting: CameraSetting
    let onSave: () -> Void
    @State private var saveTimer: Timer?

    var body: some View {
        Form {
            Section("Camera Position") {
                SliderRow(label: "X", value: $setting.position.x, range: -5 ... 5, onChange: handleLiveChange)
                SliderRow(label: "Y", value: $setting.position.y, range: -5 ... 5, onChange: handleLiveChange)
                SliderRow(label: "Z", value: $setting.position.z, range: -5 ... 5, onChange: handleLiveChange)
            }

            Section("Look At Target") {
                SliderRow(label: "X", value: $setting.target.x, range: -5 ... 5, onChange: handleLiveChange)
                SliderRow(label: "Y", value: $setting.target.y, range: -5 ... 5, onChange: handleLiveChange)
                SliderRow(label: "Z", value: $setting.target.z, range: -5 ... 5, onChange: handleLiveChange)
            }

            Section("Field of View") {
                SliderRow(label: "FOV", value: $setting.fov, range: 10 ... 120, step: 1, format: "%.0f°", onChange: handleLiveChange)
            }

            Section {
                HStack {
                    Spacer()
                    Button("Reset to Default") {
                        CameraSettings.shared.reset()
                        SharedWebViewHelper.shared.updateCameraConfig()
                        onSave()
                    }
                    .foregroundColor(.red)
                    Spacer()
                }
            }
        }
        .formStyle(.grouped)
    }

    private func handleLiveChange() {
        SharedWebViewHelper.shared.updateCameraConfig()
        saveTimer?.invalidate()
        saveTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
            onSave()
        }
    }
}

struct SliderRow: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    var step: Double = 0.01
    var format: String = "%.3f"
    var onChange: () -> Void

    var body: some View {
        HStack {
            Text("\(label):")
                .frame(width: 35, alignment: .leading)
                .font(.caption)
                .foregroundColor(.secondary)
            Slider(value: $value, in: range)
                .onChange(of: value) { _, _ in onChange() }
            Text(String(format: format, value))
                .frame(width: 55, alignment: .trailing)
                .monospacedDigit()
                .font(.caption)
        }
    }
}
