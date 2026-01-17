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

        // debug mode
        let DEBUG_MODE = true

        if DEBUG_MODE, let url = URL(string: "http://127.0.0.1:5500") {
            webView.load(URLRequest(url: url))
        } else {
            let bundle = Bundle(url: Bundle.main.url(forResource: "island", withExtension: "bundle") ?? URL(fileURLWithPath: "")) ?? Bundle.main
            if let url = bundle.url(forResource: "index", withExtension: "html", subdirectory: "WebResources") {
                webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
            }
        }

        startMouseTracking()
    }

    func setMode(_ mode: String) {
        webView.evaluateJavaScript("window.setCameraMode('\(mode)')", completionHandler: nil)
    }

    private func startMouseTracking() {
        // 30 FPS 刷新率
        mouseTrackingTimer = Timer.scheduledTimer(withTimeInterval: 0.033, repeats: true) { [weak self] _ in
            self?.sendMousePosition()
        }
    }

    private func sendMousePosition() {
        // 获取全局鼠标位置
        let mouseLoc = NSEvent.mouseLocation
        // 获取窗口位置
        guard let window = NSApplication.shared.windows.first(where: { $0 is NotchWindow }) else { return }

        let centerX = window.frame.midX
        let centerY = window.frame.midY

        // 计算相对偏移 (dx, dy)
        let dx = mouseLoc.x - centerX
        let dy = mouseLoc.y - centerY

        // 发送给 JS
        let js = "if(window.updateMouseParams) window.updateMouseParams(\(dx), \(dy))"
        webView.evaluateJavaScript(js, completionHandler: nil)
    }
}

struct VRMWebView: NSViewRepresentable {
    var state: NotchViewModel.State

    func makeNSView(context _: Context) -> WKWebView {
        return SharedWebViewHelper.shared.webView
    }

    func updateNSView(_ nsView: WKWebView, context _: Context) {
        SharedWebViewHelper.shared.setMode(state == .closed ? "head" : "body")

        DispatchQueue.main.async {
            let size = nsView.frame.size
            if size.width > 0 {
                nsView.evaluateJavaScript("if(window.updateSize) window.updateSize(\(size.width), \(size.height))", completionHandler: nil)
            }
        }
    }
}
