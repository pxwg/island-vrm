import SwiftUI
import WebKit

class SharedWebViewHelper: NSObject, WKNavigationDelegate, WKUIDelegate {
    static let shared = SharedWebViewHelper()
    let webView: WKWebView

    override init() {
        let config = WKWebViewConfiguration()
        config.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        config.preferences.setValue(true, forKey: "developerExtrasEnabled") // 开发模式

        webView = WKWebView(frame: .zero, configuration: config)
        webView.setValue(false, forKey: "drawsBackground") // 透明背景

        super.init()

        webView.navigationDelegate = self
        webView.uiDelegate = self

        loadResources()
    }

    func loadResources() {
        // 【极简模式】直接从 Bundle.main 加载
        // 因为我们在 Xcode 中添加了文件夹引用，目录名就是 WebResources
        if let url = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "WebResources") {
            let dir = url.deletingLastPathComponent()
            print("📂 Loading HTML from: \(url.path)")
            // 允许读取整个 WebResources 目录
            webView.loadFileURL(url, allowingReadAccessTo: dir)
        } else {
            print("❌ Critical Error: index.html not found in Bundle.main/WebResources")
        }
    }

    func setMode(_ mode: String) {
        let js = "if(window.setCameraMode) window.setCameraMode('\(mode)')"
        webView.evaluateJavaScript(js, completionHandler: nil)
    }
}

struct VRMWebView: NSViewRepresentable {
    var state: NotchViewModel.State

    func makeNSView(context _: Context) -> WKWebView {
        return SharedWebViewHelper.shared.webView
    }

    func updateNSView(_ nsView: WKWebView, context _: Context) {
        let mode = (state == .closed) ? "head" : "body"
        SharedWebViewHelper.shared.setMode(mode)

        DispatchQueue.main.async {
            let size = nsView.frame.size
            if size.width > 0, size.height > 0 {
                let js = "if(window.updateSize) window.updateSize(\(size.width), \(size.height))"
                nsView.evaluateJavaScript(js, completionHandler: nil)
            }
        }
    }
}
