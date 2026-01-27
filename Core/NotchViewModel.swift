import SwiftUI

public class NotchViewModel: ObservableObject {
    enum State {
        case closed
        case expanded
    }

    @Published var state: State = .closed
    @Published var chatContent: String = "你好！我是你的 AI 桌面助手。"
    @Published var currentTool: String? = nil

    private var collapseWorkItem: DispatchWorkItem?
    private var isHovering: Bool = false
    private let displayDuration: TimeInterval = 5.0

    @Published var isGodModeActive: Bool = false

    var currentSize: CGSize {
        state == .closed ? NotchConfig.closedSize : NotchConfig.openSize
    }

    var currentTopRadius: CGFloat {
        state == .closed ? NotchConfig.radius.closed.top : NotchConfig.radius.opened.top
    }

    var currentBottomRadius: CGFloat {
        state == .closed ? NotchConfig.radius.closed.bottom : NotchConfig.radius.opened.bottom
    }

    var animation: Animation {
        .easeInOut(duration: 0.5)
    }

    init(isPreview: Bool = false) {
        if !isPreview {
            setupServer()
        } else {
            print("Preview Mode: Server skipped")
            chatContent = "预览测试：这是一段模拟的对话内容..."
        }
    }

    public convenience init() {
        self.init(isPreview: false)
    }

    private func setupServer() {
        LocalServer.shared.onMessageReceived = { [weak self] request in
            self?.handleRequest(request)
        }
        LocalServer.shared.start()
    }

    private func scheduleAutoCollapse() {
        collapseWorkItem?.cancel()
        if isHovering || isGodModeActive { return }

        let item = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            if !self.isHovering && !self.isGodModeActive {
                withAnimation(self.animation) {
                    self.state = .closed
                }
            }
        }

        collapseWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + displayDuration, execute: item)
    }

    private func handleRequest(_ req: APIRequest) {
        // [新增] 处理 API 传递的鼠标跟随控制
        // 只有当 payload 中显式包含 follow_mouse 时才更新
        if let followMouse = req.payload.follow_mouse {
            DispatchQueue.main.async {
                print("🖱️ API Request set followMouse to: \(followMouse)")
                CameraSettings.shared.config.followMouse = followMouse
                CameraSettings.shared.save()
                // 通知前端更新
                SharedWebViewHelper.shared.updateCameraConfig()
            }
        }

        switch req.type {
        case "assistant_response":
            if let content = req.payload.content {
                withAnimation(animation) {
                    self.state = .expanded
                    self.chatContent = content
                }
                scheduleAutoCollapse()
            }

            if let tool = req.payload.tool_info {
                currentTool = tool.name
            } else {
                currentTool = nil
            }

            if let perf = req.payload.performance {
                SharedWebViewHelper.shared.triggerPerformance(perf)
            }

        case "agent_state":
            if let st = req.payload.state {
                SharedWebViewHelper.shared.setAgentState(st)

                if st == "thinking" {
                    currentTool = "Thinking..."
                    withAnimation(animation) {
                        self.state = .expanded
                    }
                } else if st == "idle" {
                    currentTool = nil
                    withAnimation(animation) {
                        self.state = .closed
                    }
                }
            }

        default:
            print("Unknown request type: \(req.type)")
        }
    }

    func hoverStarted() {
        isHovering = true
        collapseWorkItem?.cancel()

        withAnimation(animation) {
            state = .expanded
        }
    }

    func hoverEnded() {
        isHovering = false
        if !isGodModeActive {
            withAnimation(animation) {
                state = .closed
            }
        }
    }

    public func enterGodMode() {
        isGodModeActive = true
        collapseWorkItem?.cancel()
        withAnimation(animation) {
            state = .expanded
        }
    }

    public func exitGodMode() {
        isGodModeActive = false
        if !isHovering {
            withAnimation(animation) {
                state = .closed
            }
        }
    }
}
