import SwiftUI

struct NotchView: View {
    @StateObject var vm = NotchViewModel()
    @Namespace private var animation

    var body: some View {
        // 使用 ZStack 确保布局对齐
        ZStack(alignment: .top) {
            // 1. 核心内容区域
            VStack(spacing: 0) {
                // 灵动岛主体 (NotchLayout)
                ZStack(alignment: .top) {
                    // 背景层
                    NotchShape(
                        topCornerRadius: vm.currentTopRadius,
                        bottomCornerRadius: vm.currentBottomRadius
                    )
                    .fill(Color.black)
                    .shadow(color: .black.opacity(0.4), radius: 10, x: 0, y: 5)

                    // 内容层
                    if vm.state == .closed {
                        // 折叠状态
                        HStack {
                            Spacer()
                            // 呼吸灯
                            Circle()
                                .fill(Color.green)
                                .frame(width: 6, height: 6)
                                .opacity(0.8)
                                .padding(.trailing, 4)
                            // VRM 头部渲染
                            VRMWebView(state: .closed)
                                .frame(width: 40, height: 40)
                                .matchedGeometryEffect(id: "vrm-canvas", in: animation)
                                .mask(Circle())
                        }
                        .padding(.trailing, 12)
                        .frame(width: vm.currentSize.width, height: vm.currentSize.height)
                    } else {
                        // 展开状态
                        ZStack(alignment: .top) {
                            Spacer().frame(height: NotchConfig.closedSize.height)
                            HStack(alignment: .top, spacing: 0) {
                                // 左侧控制面板
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("VRM Interactive")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                        .fixedSize(horizontal: false, vertical: true)
                                        .transition(.opacity.animation(.easeIn.delay(0.1)))
                                    Text("Status: Online")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                        .transition(.opacity.animation(.easeIn.delay(0.2)))
                                    Spacer()
                                }
                                .padding(.leading, 30)
                                .padding(.top, 10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                // 右侧 VRM 全身渲染
                                VStack {
                                    VRMWebView(state: .expanded)
                                        .frame(width: 140, height: 180)
                                        .matchedGeometryEffect(id: "vrm-canvas", in: animation)
                                        .mask(RoundedRectangle(cornerRadius: 12))
                                }
                                .frame(width: 150)
                                .padding(.trailing, 10)
                                .padding(.bottom, 0)
                            }
                            .frame(width: vm.currentSize.width)
                        }
                    }
                }
                // 【关键】：只给“实体”部分添加点击形状
                .clipShape(NotchShape(
                    topCornerRadius: vm.currentTopRadius,
                    bottomCornerRadius: vm.currentBottomRadius
                ))
                .frame(width: vm.currentSize.width, height: vm.currentSize.height, alignment: .top)
                .contentShape(Rectangle()) // 让这个黑色区域可交互
                .onHover { isHovering in
                    if isHovering { vm.hoverStarted() }
                    else { vm.hoverEnded() }
                }
                .onTapGesture {
                    print("Notch Tapped!")
                }

                // 下方留空 (如果有下巴区域)
                if vm.state == .expanded {
                    // 可以在这里放其他悬浮元素，但不要放全屏的 Color.clear
                }
            }
            // 确保 VStack 顶部对齐
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .padding(.bottom, 8)
        // 【绝对关键】：设置 Frame 为窗口大小，但不要加 .background(Color.clear)！
        .frame(maxWidth: NotchConfig.windowSize.width, maxHeight: NotchConfig.windowSize.height, alignment: .top)
        // .background(Color.clear) // <--- ❌ 删掉这行！它就是罪魁祸首！
        .ignoresSafeArea()
    }
}

#if DEBUG
    #Preview {
        // 设置一个合适的预览背景和大小，模拟刘海屏环境
        NotchView()
            .frame(width: 800, height: 400)
            .background(Color.gray.opacity(0.3))
    }
#endif
