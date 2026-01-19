import SwiftUI
import WebKit

class SharedWebViewHelper: NSObject, WKNavigationDelegate, WKUIDelegate {
    static let shared = SharedWebViewHelper()
    let webView: WKWebView
    private var mouseTrackingTimer: Timer?

    override init() {
        let config = WKWebViewConfiguration()
        config.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        config.preferences.setValue(true, forKey: "developerExtrasEnabled")

        webView = WKWebView(frame: .zero, configuration: config)
        // 关键：允许背景透明
        webView.setValue(false, forKey: "drawsBackground")

        super.init()
        webView.navigationDelegate = self
        webView.uiDelegate = self

        #if DEBUG_SERVER
            if let url = URL(string: "http://127.0.0.1:5500") {
                webView.load(URLRequest(url: url))
            }
        #else
            let bundle = Bundle(url: Bundle.main.url(forResource: "island", withExtension: "bundle") ?? URL(fileURLWithPath: "")) ?? Bundle.main
            if let url = bundle.url(forResource: "index", withExtension: "html", subdirectory: "WebResources") {
                webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
            }
        #endif

        startMouseTracking()
    }

    func setMode(_ mode: String) {
        webView.evaluateJavaScript("window.setCameraMode('\(mode)')", completionHandler: nil)
    }

    // [新增] 发送演绎指令
    func triggerPerformance(_ perf: Performance) {
        do {
            let data = try JSONEncoder().encode(perf)
            if let jsonString = String(data: data, encoding: .utf8) {
                let js = "if(window.triggerPerformance) window.triggerPerformance(\(jsonString))"
                webView.evaluateJavaScript(js, completionHandler: nil)
            }
        } catch {
            print("Failed to encode performance: \(error)")
        }
    }

    // [新增] 发送状态指令
    func setAgentState(_ state: String) {
        let js = "if(window.setAgentState) window.setAgentState('\(state)')"
        webView.evaluateJavaScript(js, completionHandler: nil)
    }

    // --- 鼠标追踪逻辑 ---
    private func startMouseTracking() {
        mouseTrackingTimer = Timer.scheduledTimer(withTimeInterval: 0.033, repeats: true) { [weak self] _ in
            self?.sendMousePosition()
        }
    }

    private func sendMousePosition() {
        let mouseLoc = NSEvent.mouseLocation
        guard let window = NSApplication.shared.windows.first(where: { $0 is NotchWindow }) else { return }

        let centerX = window.frame.midX
        let centerY = window.frame.midY

        let dx = mouseLoc.x - centerX
        let dy = mouseLoc.y - centerY

        if webView.window != nil {
            let js = "if(window.updateMouseParams) window.updateMouseParams(\(dx), \(dy))"
            webView.evaluateJavaScript(js, completionHandler: nil)
        }
    }
}

struct VRMWebView: NSViewRepresentable {
    var state: NotchViewModel.State

    func makeNSView(context _: Context) -> NSView {
        // [新增] 极为关键：判断是否在预览模式
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            let mockView = NSView()
            mockView.wantsLayer = true
            mockView.layer?.backgroundColor = NSColor.systemBlue.withAlphaComponent(0.3).cgColor
            return mockView
        }
        return SharedWebViewHelper.shared.webView
    }

    func updateNSView(_ nsView: NSView, context _: Context) {
        // [新增] 只有是 WKWebView 才执行逻辑，防止崩溃
        if let _ = nsView as? WKWebView {
            SharedWebViewHelper.shared.setMode(state == .closed ? "head" : "body")
        }
    }
}
