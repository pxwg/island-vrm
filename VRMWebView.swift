import SwiftUI
import WebKit

class SharedWebViewHelper: NSObject, WKNavigationDelegate, WKUIDelegate {
    static let shared = SharedWebViewHelper()
    let webView: WKWebView

    override init() {
        let config = WKWebViewConfiguration()
        config.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        config.preferences.setValue(true, forKey: "developerExtrasEnabled")

        webView = WKWebView(frame: .zero, configuration: config)
        webView.setValue(false, forKey: "drawsBackground")

        super.init()
        webView.navigationDelegate = self
        webView.uiDelegate = self

        // 🔴 调试开关: true=LiveServer(端口5500), false=本地资源
        let DEBUG_MODE = true

        if DEBUG_MODE, let url = URL(string: "http://127.0.0.1:5500") {
            print("🌐 [Debug] Remote: \(url)")
            webView.load(URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10))
        } else {
            // 生产模式：加载本地 index.html
            // 简化 Bundle 查找逻辑
            let bundle = Bundle(url: Bundle.main.url(forResource: "island", withExtension: "bundle") ?? URL(fileURLWithPath: "")) ?? Bundle.main

            if let url = bundle.url(forResource: "index", withExtension: "html", subdirectory: "WebResources") {
                print("📂 [Release] Local: \(url.path)")
                webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
            } else {
                print("❌ [Release] Error: index.html not found.")
            }
        }
    }

    func setMode(_ mode: String) {
        webView.evaluateJavaScript("window.setCameraMode('\(mode)')", completionHandler: nil)
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
