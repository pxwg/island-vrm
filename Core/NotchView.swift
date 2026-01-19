import SwiftUI

struct NotchView: View {
    @StateObject var vm: NotchViewModel
    // 允许外部传入 vm
    init(vm: NotchViewModel = NotchViewModel()) {
        _vm = StateObject(wrappedValue: vm)
    }

    var body: some View {
        // 1. 全局容器：吸顶
        ZStack(alignment: .top) {
            // 2. 灵动岛主体
            ZStack(alignment: .top) {
                // --- Layer A: 背景 (黑色药丸) ---
                NotchShape(
                    topCornerRadius: vm.currentTopRadius,
                    bottomCornerRadius: vm.currentBottomRadius
                )
                .fill(Color.black)
                .shadow(color: .black.opacity(0.4), radius: 12, x: 0, y: 6)
                .frame(width: vm.currentSize.width, height: vm.currentSize.height)

                // --- Layer B: 3D 模型 (WebView) ---
                // WebView 使用 Frame 动画，它会自动重排/缩放 Canvas
                VRMWebView(state: vm.state)
                    .frame(
                        width: vm.state == .closed ? NotchConfig.VRM.headSize.width : NotchConfig.VRM.bodyWidth,
                        height: vm.state == .closed ? NotchConfig.VRM.headSize.height : (NotchConfig.openSize.height - NotchConfig.closedSize.height)
                    )
                    .mask(
                        RoundedRectangle(
                            cornerRadius: vm.state == .closed ? NotchConfig.VRM.headCornerRadius : NotchConfig.VRM.bodyCornerRadius,
                            style: .continuous
                        )
                    )
                    .padding(.top, vm.state == .closed ? (NotchConfig.closedSize.height - NotchConfig.VRM.headSize.height) / 2 : NotchConfig.closedSize.height)
                    .padding(.trailing, vm.state == .closed ? 12 : 24)
                    .frame(
                        width: vm.currentSize.width,
                        height: vm.currentSize.height,
                        alignment: .topTrailing
                    )
                    .zIndex(2)

                // --- Layer C: UI 内容 ---
                // [核心修改]
                // 不使用 if/else，让两个视图始终存在，利用 scaleEffect 和 opacity 实现无缝混合
                ZStack(alignment: .top) {
                    // 1. 展开态内容 (ExpandedContent)
                    ExpandedContent(vm: vm)
                        // [关键点] 强制固定为展开后的大小，保证文字排版不乱
                        .frame(width: NotchConfig.openSize.width, height: NotchConfig.openSize.height)
                        // [视觉缩放] 当折叠时，缩小到 50% 并隐藏；展开时恢复 100%
                        // 这里的动画曲线会完美跟随 vm.animation (Spring)
                        .scaleEffect(vm.state == .expanded ? 1.0 : 0.5, anchor: .top)
                        .opacity(vm.state == .expanded ? 1.0 : 0.0)
                        // 稍微加一点垂直位移，增加“滑出”的动感
                        .offset(y: vm.state == .expanded ? 0 : 15)
                        // 折叠时禁止点击
                        .allowsHitTesting(vm.state == .expanded)

                    // 2. 折叠态内容 (CompactView)
                    CompactView()
                        .frame(width: NotchConfig.closedSize.width, height: NotchConfig.closedSize.height)
                        // 展开时：放大并消失
                        .scaleEffect(vm.state == .closed ? 1.0 : 1.2, anchor: .center)
                        .opacity(vm.state == .closed ? 1.0 : 0.0)
                        .allowsHitTesting(vm.state == .closed)
                }
                .frame(width: vm.currentSize.width, height: vm.currentSize.height, alignment: .top)
                // 确保超出灵动岛圆角的内容被裁切
                .clipShape(NotchShape(
                    topCornerRadius: vm.currentTopRadius,
                    bottomCornerRadius: vm.currentBottomRadius
                ))
                .zIndex(3)
            }
            // .animation(vm.animation, value: vm.state)
            // 交互触发
            .contentShape(Rectangle())
            .onHover { hovering in
                if hovering { vm.hoverStarted() }
                else { vm.hoverEnded() }
            }
        }
        .frame(width: NotchConfig.windowSize.width, height: NotchConfig.windowSize.height, alignment: .top)
        .ignoresSafeArea()
    }
}

// --- 子视图组件 ---

struct CompactView: View {
    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: "cloud.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
                Text("24°")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
            }
            .padding(.leading, 14)

            Spacer()
            // 避让物理刘海
            Spacer().frame(width: 100)
            Spacer()
            // 右侧留给 WebView
            Spacer().frame(width: NotchConfig.VRM.headSize.width + 12)
        }
        .frame(height: NotchConfig.closedSize.height)
    }
}

struct ExpandedContent: View {
    @ObservedObject var vm: NotchViewModel

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Assistant")
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                    if let tool = vm.currentTool {
                        HStack(spacing: 4) {
                            Image(systemName: "hammer.fill")
                            Text(tool)
                        }
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Capsule())
                    }
                }

                ScrollView {
                    Text(vm.chatContent)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.9))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                HStack {
                    Button(action: {}) {
                        Label("Chat", systemImage: "mic.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.indigo)
                    .controlSize(.small)
                }
            }
            .padding(EdgeInsets(top: 16, leading: 20, bottom: 16, trailing: 10))
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Spacer().frame(width: NotchConfig.VRM.bodyWidth)
        }
        .padding(.top, NotchConfig.closedSize.height)
    }
}

// [新增] Xcode 15+ 专用预览宏
#Preview("展开状态") {
    // 这里传入 isPreview: true，避免启动服务器
    NotchView(vm: NotchViewModel(isPreview: true))
        .frame(width: 800, height: 400) // 给画布一个大背景
        .background(Color.black.opacity(0.1)) // 稍微给点背景色看清轮廓
}

#Preview("收起状态") {
    let vm = NotchViewModel(isPreview: true)
    vm.state = .closed
    return NotchView(vm: vm)
        .frame(width: 500, height: 200)
}
