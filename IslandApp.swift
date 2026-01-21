import IslandCore
import SwiftUI

@main
struct IslandVRMApp: App {
    // 绑定旧的 AppDelegate 以保持窗口透明逻辑
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    // [新增] 设置窗口状态管理
    @State private var isSettingsPresented = false

    var body: some Scene {
        // [修改] 添加菜单栏和键盘快捷键
        MenuBarExtra("Island VRM", systemImage: "figure.stand") {
            Button("Preferences...") {
                openSettings()
            }
            .keyboardShortcut(",", modifiers: .command)
            
            Divider()
            
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: .command)
        }
        
        // 设置窗口场景
        Window("Preferences", id: "settings") {
            SettingsView(onBodyModeSelected: { isBodyMode in
                if let vm = appDelegate.viewModel {
                    if isBodyMode {
                        vm.enterGodMode()
                    } else {
                        vm.exitGodMode()
                    }
                }
            })
        }
        .keyboardShortcut(",", modifiers: .command)
        .defaultSize(width: 600, height: 450)
    }
    
    private func openSettings() {
        NSApp.activate(ignoringOtherApps: true)
        if let window = NSApp.windows.first(where: { $0.identifier?.rawValue == "settings" }) {
            window.makeKeyAndOrderFront(nil)
        }
    }
}
