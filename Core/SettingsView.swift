import SwiftUI

struct SettingsView: View {
    // 引用全局的 Config Store
    @ObservedObject var store = CameraConfigStore.shared
    // 引用 App 传入的 ViewModel (用于控制灵动岛展开)
    @ObservedObject var vm: NotchViewModel
    
    @State private var selectedTab = "head"
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ConfigForm(setting: Binding(
                get: { store.config.head },
                set: { store.config.head = $0 }
            ))
            .tabItem { Label("Head Mode", systemImage: "face.smiling") }
            .tag("head")
            
            ConfigForm(setting: Binding(
                get: { store.config.body },
                set: { store.config.body = $0 }
            ))
            .tabItem { Label("Body Mode", systemImage: "figure.stand") }
            .tag("body")
        }
        .padding()
        .frame(width: 400, height: 400)
        .onAppear {
            // [关键] 打开设置：根据当前标签强制展开/收起灵动岛
            updateOverrideState()
        }
        .onDisappear {
            // [关键] 关闭设置：释放控制权
            vm.overrideState = nil
        }
        .onChange(of: selectedTab) { _ in
            updateOverrideState()
        }
    }
    
    private func updateOverrideState() {
        // 切换 Web 摄像机模式
        SharedWebViewHelper.shared.setMode(selectedTab)
        
        // 切换 Native 灵动岛形态
        // Head 模式 -> 收起 (以便观察收起时的大头位置)
        // Body 模式 -> 展开 (以便观察身体位置)
        withAnimation {
            vm.overrideState = (selectedTab == "head" ? .closed : .expanded)
        }
    }
}

// 子视图：具体的滑块表单
struct ConfigForm: View {
    @Binding var setting: CameraSetting
    
    var body: some View {
        Form {
            Section(header: Text("Position")) {
                SliderRow(label: "X", value: $setting.position.x, range: -2...2)
                SliderRow(label: "Y", value: $setting.position.y, range: -1...3)
                SliderRow(label: "Z", value: $setting.position.z, range: 0...5)
            }
            
            Section(header: Text("Target (Look At)")) {
                SliderRow(label: "X", value: $setting.target.x, range: -2...2)
                SliderRow(label: "Y", value: $setting.target.y, range: -1...3)
                SliderRow(label: "Z", value: $setting.target.z, range: -2...2)
            }
            
            Section(header: Text("Camera")) {
                SliderRow(label: "FOV", value: $setting.fov, range: 10...100)
            }
            
            Button("Reset to Defaults") {
                CameraConfigStore.shared.reset()
            }
        }
        .padding()
    }
}

struct SliderRow: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    
    var body: some View {
        HStack {
            Text(label).frame(width: 20)
            Slider(value: $value, in: range)
            Text(String(format: "%.2f", value)).font(.monospacedDigit(.caption)())
        }
    }
}
