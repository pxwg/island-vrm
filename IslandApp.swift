import IslandCore
import SwiftUI

@main
struct IslandVRMApp: App {
    // 绑定旧的 AppDelegate 以保持窗口透明逻辑
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
