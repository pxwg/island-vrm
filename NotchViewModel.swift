import SwiftUI

class NotchViewModel: ObservableObject {
    enum State {
        case closed
        case expanded
    }

    @Published var state: State = .closed

    // [UI 数据源]
    @Published var chatContent: String = "你好！我是你的 AI 桌面助手。"
    @Published var currentTool: String? = nil

    // [自动折叠控制]
    private var collapseWorkItem: DispatchWorkItem?
    private var isHovering: Bool = false
    private let displayDuration: TimeInterval = 5.0 // 消息展示时长(秒)

    // 尺寸配置
    var currentSize: CGSize {
        state == .closed ? NotchConfig.closedSize : NotchConfig.openSize
    }

    var currentTopRadius: CGFloat {
        state == .closed ? NotchConfig.radius.closed.top : NotchConfig.radius.opened.top
    }

    var currentBottomRadius: CGFloat {
        state == .closed ? NotchConfig.radius.closed.bottom : NotchConfig.radius.opened.bottom
    }

    // duration: 0.5 秒，提供平滑、从容的展开感
    var animation: Animation {
        .easeInOut(duration: 0.5)
    }

    init() {
        setupServer()
    }

    private func setupServer() {
        LocalServer.shared.onMessageReceived = { [weak self] request in
            self?.handleRequest(request)
        }
        LocalServer.shared.start()
    }

    // [自动折叠逻辑]
    private func scheduleAutoCollapse() {
        collapseWorkItem?.cancel()
        if isHovering { return }

        let item = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            if !self.isHovering {
                withAnimation(self.animation) {
                    self.state = .closed
                }
            }
        }

        collapseWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + displayDuration, execute: item)
    }

    private func handleRequest(_ req: APIRequest) {
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
        withAnimation(animation) {
            state = .closed
        }
    }
}
