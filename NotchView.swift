import SwiftUI

struct NotchView: View {
    @StateObject var vm = NotchViewModel()
    // 移除 @Namespace，因为 WebView 不再需要 matchedGeometryEffect 跨层级移动

    var body: some View {
        ZStack(alignment: .top) {
            VStack(alignment: .center, spacing: 0) {
                ZStack(alignment: .top) {
                    NotchShape(
                        topCornerRadius: vm.currentTopRadius,
                        bottomCornerRadius: vm.currentBottomRadius
                    )
                    .fill(Color.black)
                    .shadow(color: .black.opacity(0.4), radius: 10, x: 0, y: 5)

                    // 使用 if/else 仅切换 UI 控件，避免 WebView 重生
                    if vm.state == .closed {
                        // === [折叠状态 UI] ===
                        HStack {
                            Spacer()
                            Circle()
                                .fill(Color.green)
                                .frame(width: 6, height: 6)
                                .opacity(0.8)
                                .padding(.trailing, 4)
                                .padding(.top, 13) // 微调垂直对齐

                            // [占位符] 为 WebView 留出空间
                            Spacer().frame(width: 40, height: 40)
                        }
                        .padding(.trailing, 12)
                        .frame(width: vm.currentSize.width, height: vm.currentSize.height)

                    } else {
                        // === [展开状态 UI] ===
                        ZStack(alignment: .top) {
                            Spacer().frame(height: NotchConfig.closedSize.height)

                            HStack(alignment: .top, spacing: 0) {
                                // [左侧] 控制面板 (保持原样)
                                VStack(alignment: .leading, spacing: 12) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("VRM Interactive")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.white)
                                        Text("Status: Online")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    .transition(.opacity.animation(.easeIn.delay(0.1)))

                                    Spacer()

                                    HStack(spacing: 12) {
                                        Button(action: { print("💬 Chat Clicked") }) {
                                            Label("Chat", systemImage: "message.fill")
                                        }
                                        .buttonStyle(.borderedProminent)
                                        .tint(.indigo)
                                        .controlSize(.small)

                                        Button(action: { print("🎤 Mic Clicked") }) {
                                            Image(systemName: "mic.fill")
                                        }
                                        .buttonStyle(.bordered)
                                        .tint(.white.opacity(0.2))
                                        .controlSize(.small)

                                        Button(action: { print("⚙️ Settings Clicked") }) {
                                            Image(systemName: "ellipsis")
                                        }
                                        .buttonStyle(.plain)
                                        .foregroundColor(.gray)
                                        .controlSize(.small)
                                    }
                                    .padding(.bottom, 14)
                                    .transition(.move(edge: .bottom).combined(with: .opacity).animation(.easeOut.delay(0.15)))
                                }
                                .padding(.leading, 24)
                                .padding(.top, 10)
                                .frame(maxWidth: .infinity, alignment: .leading)

                                // [右侧] 占位符
                                VStack {
                                    Spacer().frame(width: 150)
                                }
                                .padding(.trailing, 10)
                            }
                            .frame(width: vm.currentSize.width)
                        }
                    }

                    // WebView 部分
                    // 独立于 if/else 之外，通过修改器动态调整位置和大小
                    VRMWebView(state: vm.state)
                        .frame(
                            width: vm.state == .closed ? NotchConfig.VRM.headSize.width : NotchConfig.VRM.bodyWidth,
                            height: vm.state == .closed ? NotchConfig.VRM.headSize.height : (NotchConfig.openSize.height - NotchConfig.closedSize.height)
                        )
                        .mask(RoundedRectangle(cornerRadius: vm.state == .closed ? NotchConfig.VRM.headCornerRadius : NotchConfig.VRM.bodyCornerRadius))
                        .padding(.top, vm.state == .closed ? NotchConfig.VRM.headTopPadding : NotchConfig.closedSize.height)
                        .padding(.trailing, vm.state == .closed ? 12 : 10)
                        .frame(maxWidth: vm.currentSize.width, maxHeight: vm.currentSize.height, alignment: .topTrailing)
                }
                .clipShape(NotchShape(
                    topCornerRadius: vm.currentTopRadius,
                    bottomCornerRadius: vm.currentBottomRadius
                ))
                .frame(width: vm.currentSize.width, height: vm.currentSize.height, alignment: .top)
                .contentShape(Rectangle())
                .onHover { isHovering in
                    if isHovering { vm.hoverStarted() }
                    else { vm.hoverEnded() }
                }
                .onTapGesture { print("Background Tapped") }

                if vm.state == .expanded { Spacer() }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .ignoresSafeArea()
        .frame(maxWidth: NotchConfig.windowSize.width, maxHeight: NotchConfig.windowSize.height, alignment: .top)
    }
}
