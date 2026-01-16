import SwiftUI

struct NotchView: View {
    @StateObject var vm = NotchViewModel()
    
    // 模拟头像数据 (这里用系统图标代替，未来换成 VRM 截图或渲染图)
    let avatarIcon = "face.smiling.inverse" 
    
    var body: some View {
        // 1. 最外层容器
        VStack(alignment: .center, spacing: 0) {
            
            // 2. 灵动岛背景与内容
            ZStack(alignment: .top) {
                // A. 背景层 (黑色形状)
                NotchShape(
                    topCornerRadius: vm.currentTopRadius,
                    bottomCornerRadius: vm.currentBottomRadius
                )
                .fill(Color.black)
                .shadow(color: .black.opacity(0.4), radius: 10, x: 0, y: 5)
                
                // B. 内容层
                VStack(spacing: 0) {
                    // --- 顶部区域 (对应折叠状态的高度) ---
                    // 始终存在，用于放置折叠时的小图标
                    HStack {
                        // 左侧占位 (避开中间的物理摄像头区域)
                        Spacer()
                        
                        // --- 右侧头像 (关键新增) ---
                        // 仅在折叠状态，或者展开初期显示
                        if vm.state == .closed {
                            HStack(spacing: 6) {
                                // 模拟呼吸灯或状态点 (可选)
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 6, height: 6)
                                    .opacity(0.8)
                                
                                // 头像/头部
                                Image(systemName: avatarIcon)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 22, height: 22)
                                    .foregroundColor(.white)
                                    // 稍微旋转一点增加俏皮感
                                    .rotationEffect(.degrees(10))
                            }
                            .padding(.trailing, 18) // 右侧边距，避免贴边太紧
                            .transition(.opacity.combined(with: .scale)) // 消失/出现动画
                        }
                    }
                    .frame(height: NotchConfig.closedSize.height)
                    .frame(maxWidth: .infinity) // 撑满宽度
                    
                    // --- 展开区域 (对应展开状态) ---
                    if vm.state == .expanded {
                        VStack {
                            Spacer()
                            // 这里未来是你的 WebView (Three.js VRM)
                            Text("✨ VRM Character Body ✨")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.bottom, 20)
                            
                            HStack(spacing: 20) {
                                Button("Dance") {}.buttonStyle(.borderedProminent)
                                Button("Sleep") {}.buttonStyle(.bordered)
                            }
                            Spacer()
                        }
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
                .frame(width: vm.currentSize.width, height: vm.currentSize.height)
                // 裁剪内容，确保圆角
                .clipShape(NotchShape(
                    topCornerRadius: vm.currentTopRadius,
                    bottomCornerRadius: vm.currentBottomRadius
                ))
            }
            .frame(width: vm.currentSize.width, height: vm.currentSize.height, alignment: .top)
            
            // 3. 交互区域
            .contentShape(Rectangle()) 
            .onHover { isHovering in
                if isHovering { vm.hoverStarted() }
                else { vm.hoverEnded() }
            }
            
            Spacer() 
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.clear)
    }
}
