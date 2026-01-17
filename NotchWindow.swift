import Cocoa
import SwiftUI

class NotchWindow: NSPanel {
    init() {
        // 1. 使用最大尺寸 (展开时的大小)
        let size = NotchConfig.windowSize
        guard let screen = NSScreen.main else { fatalError("No screen found") }
        let screenRect = screen.frame
        // 2. 计算位置：顶部居中
        let x = screenRect.midX - (size.width / 2)
        let y = screenRect.maxY - size.height
        let frame = NSRect(x: x, y: y, width: size.width, height: size.height)
        super.init(
            contentRect: frame,
            // 关键 StyleMask：参考 boringNotchApp.swift 的 createBoringNotchWindow
            styleMask: [.borderless, .nonactivatingPanel, .utilityWindow, .hudWindow],
            backing: .buffered,
            defer: false
        )

        // 3. 核心属性设置
        isFloatingPanel = true // 让窗口浮动在其他窗口之上
        isOpaque = false // 允许透明
        backgroundColor = .clear // 背景完全透明
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        isMovable = false
        hasShadow = false

        // 4. 层级设置
        level = .mainMenu + 3

        // 5. 集合行为 (Expose, 全屏支持等)
        collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .stationary,
            .ignoresCycle,
        ]
    }

    // 确保窗口不会成为 Key Window (抢夺键盘焦点)
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

// 在 AppDelegate 或 App 入口中使用
class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NotchWindow!

    func applicationDidFinishLaunching(_: Notification) {
        window = NotchWindow()
        let contentView = NotchView()

        let hostingView = NSHostingView(rootView: contentView)
        hostingView.sizingOptions = .minSize // 允许 View 自由调整大小
        hostingView.layer?.backgroundColor = NSColor.clear.cgColor

        window.contentView = hostingView
        window.makeKeyAndOrderFront(nil)
    }
}
