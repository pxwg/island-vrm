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
    
    // [新增] God Mode 控制
    @Published var isGodModeActive: Bool = false // 当设置面板的 Body 标签页打开时为 true

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

    // [修改] init 增加 isPreview 参数，默认 false
    init(isPreview: Bool = false) {
        // 只有不是预览模式时，才启动服务器
        if !isPreview {
            setupServer()
        } else {
            // [新增] 预览模式下的假数据
            print("Preview Mode: Server skipped")
            chatContent = "预览测试：这是一段模拟的对话内容..."
        }
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
        // God Mode: 禁用自动折叠
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
        // God Mode: 悬停结束后保持展开状态
        if !isGodModeActive {
            withAnimation(animation) {
                state = .closed
            }
        }
    }
    
    // [新增] God Mode 控制方法
    func enterGodMode() {
        isGodModeActive = true
        collapseWorkItem?.cancel()
        withAnimation(animation) {
            state = .expanded
        }
    }
    
    func exitGodMode() {
        isGodModeActive = false
        // 退出 God Mode 时，如果不在悬停状态则自动折叠
        if !isHovering {
            withAnimation(animation) {
                state = .closed
            }
        }
    }
}
