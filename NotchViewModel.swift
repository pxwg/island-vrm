import SwiftUI

class NotchViewModel: ObservableObject {
    enum State {
        case closed
        case expanded
    }

    @Published var state: State = .closed

    // [UI 数据源]
    @Published var chatContent: String = "你好！我是你的 AI 桌面助手。正在等待指令..."
    @Published var currentTool: String? = nil

    // 当前显示的灵动岛尺寸
    var currentSize: CGSize {
        state == .closed ? NotchConfig.closedSize : NotchConfig.openSize
    }

    var currentTopRadius: CGFloat {
        state == .closed ? NotchConfig.radius.closed.top : NotchConfig.radius.opened.top
    }

    var currentBottomRadius: CGFloat {
        state == .closed ? NotchConfig.radius.closed.bottom : NotchConfig.radius.opened.bottom
    }

    init() {
        setupServer()
    }

    // [新增] 启动服务器并处理消息
    private func setupServer() {
        LocalServer.shared.onMessageReceived = { [weak self] request in
            self?.handleRequest(request)
        }
        LocalServer.shared.start()
    }

    private func handleRequest(_ req: APIRequest) {
        switch req.type {
        case "assistant_response":
            if let content = req.payload.content {
                // 自动展开灵动岛以显示消息
                withAnimation { self.state = .expanded }
                // 模拟打字机效果（可选，这里直接赋值）
                chatContent = content
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

                // 如果是 thinking 状态，可以考虑自动展开或显示 loading UI
                if st == "thinking" {
                    currentTool = "Thinking..."
                } else if st == "idle" {
                    currentTool = nil
                }
            }

        default:
            print("Unknown request type: \(req.type)")
        }
    }

    func hoverStarted() {
        withAnimation(.easeInOut(duration: 0.3)) {
            state = .expanded
        }
    }

    func hoverEnded() {
        withAnimation(.easeInOut(duration: 0.3)) {
            state = .closed
        }
    }
}
