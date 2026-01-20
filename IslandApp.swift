import IslandCore
import SwiftUI

// 创建一个全局 ViewModel 实例，供 App 和 Settings 共享
let globalVM = NotchViewModel()

@main
struct IslandVRMApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // 主窗口逻辑在 AppDelegate 中手动创建 (NotchWindow)，这里留空或者放其他逻辑
        // 但 Settings Scene 必须在这里定义
        Settings {
            SettingsView(vm: globalVM)
        }
    }
}
