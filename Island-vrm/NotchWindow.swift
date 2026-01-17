import Cocoa
import SwiftUI

// --- AppDelegate: 应用生命周期管理 ---
class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NotchWindow!

    func applicationDidFinishLaunching(_: Notification) {
        // 1. 初始化自定义窗口
        window = NotchWindow()

        // 2. 创建 SwiftUI 视图
        // 注意：这里需要你把 NotchViewModel, NotchView 等文件也拖进 Xcode
        let contentView = NotchView()

        // 3. 将 SwiftUI 嵌入 Cocoa 窗口
        let hostingView = NSHostingView(rootView: contentView)
        hostingView.sizingOptions = .minSize
        hostingView.layer?.backgroundColor = NSColor.clear.cgColor

        window.contentView = hostingView

        // 4. 显示窗口 (不激活应用，保持在其他窗口之上)
        window.makeKeyAndOrderFront(nil)

        print("✅ Island App Launched")
    }
}

// --- NotchWindow: 自定义 NSPanel ---
class NotchWindow: NSPanel {
    init() {
        // 使用预定义尺寸
        let size = NotchConfig.windowSize

        // 计算屏幕顶部居中位置
        guard let screen = NSScreen.main else { fatalError("No screen found") }
        let screenRect = screen.frame
        let x = screenRect.midX - (size.width / 2)
        let y = screenRect.maxY - size.height // 贴顶

        let frame = NSRect(x: x, y: y, width: size.width, height: size.height)

        super.init(
            contentRect: frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        // 窗口透明配置
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false

        // 层级配置：确保在菜单栏和普通窗口之上
        level = .mainMenu + 3

        // 行为配置：允许在全屏 App 上方显示
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        isMovable = false

        // 交互配置
        ignoresMouseEvents = false
    }

    // 禁止成为 Key Window (防止抢键盘焦点)
    override var canBecomeKey: Bool { false }
}
