import SwiftUI

struct NotchView: View {
    @StateObject var vm = NotchViewModel()
    @Namespace private var animation // 动画命名空间
    
    // 模拟 VRM 头像/半身像
    let avatarIcon = "person.crop.circle.fill"
    
    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            
            ZStack(alignment: .top) {
                // --- 背景层 ---
                NotchShape(
                    topCornerRadius: vm.currentTopRadius,
                    bottomCornerRadius: vm.currentBottomRadius
                )
                .fill(Color.black)
                .shadow(color: .black.opacity(0.4), radius: 10, x: 0, y: 5)
                
                // --- 内容层 ---
                if vm.state == .closed {
                    // === [折叠状态] ===
                    HStack {
                        Spacer()
                        
                        // 呼吸灯
                        Circle()
                            .fill(Color.green)
                            .frame(width: 6, height: 6)
                            .opacity(0.8)
                            .padding(.trailing, 4)
                        
                        // 小头像 (头部特写)
                        Image(systemName: avatarIcon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 24, height: 24)
                            .foregroundColor(.white)
                            .rotationEffect(.degrees(10))
                            // 标记 ID="avatar"，位置在右侧
                            .matchedGeometryEffect(id: "avatar", in: animation)
                    }
                    .padding(.trailing, 16)
                    .frame(width: vm.currentSize.width, height: vm.currentSize.height)
                    
                } else {
                    // === [展开状态] ===
                    VStack(spacing: 0) {
                        // 1. 避让物理刘海区域 (顶部高度占位)
                        Spacer().frame(height: NotchConfig.closedSize.height)
                        
                        // 2. 主体区域 (左右分栏)
                        HStack(alignment: .top, spacing: 0) {
                            
                            // [左侧] 控制面板
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Waiting for command...")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .fixedSize(horizontal: false, vertical: true)
                                    // 修复点 1：使用 .animation(...) 包裹 delay
                                    .transition(.opacity.combined(with: .move(edge: .leading)))
                                
                                Text("Model: Alice_v1.0")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    // 修复点 2：将 .delay(0.1) 改为 .animation(...)
                                    .transition(.opacity.animation(.easeIn.delay(0.1)))
                                
                                Spacer()
                                
                                // 按钮组
                                HStack(spacing: 12) {
                                    Button(action: {}) {
                                        Label("Chat", systemImage: "message.fill")
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .tint(.indigo)
                                    .controlSize(.small)
                                    
                                    Button(action: {}) {
                                        Image(systemName: "mic.fill")
                                    }
                                    .buttonStyle(.bordered)
                                    .tint(.white.opacity(0.2))
                                    .controlSize(.small)
                                }
                                .padding(.bottom, 10)
                                // 修复点 3：修正底部的 transition 延时写法
                                .transition(
                                    .move(edge: .bottom)
                                    .combined(with: .opacity)
                                    .animation(.easeOut.delay(0.15))
                                )
                            }
                            .padding(.leading, 30) // 左边距
                            .padding(.top, 10)
                            .frame(maxWidth: .infinity, alignment: .leading) // 撑满左侧剩余空间
                            
                            // [右侧] VRM 人物展示位
                            VStack {
                                Image(systemName: avatarIcon)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 100, height: 140)
                                    .foregroundColor(.white)
                                    .rotationEffect(.degrees(0))
                                    // 标记 ID="avatar"，位置依然在右侧，但变大了
                                    .matchedGeometryEffect(id: "avatar", in: animation)
                                    .shadow(color: .white.opacity(0.1), radius: 10, x: 0, y: 0)
                            }
                            .frame(width: 130)
                            .padding(.trailing, 20)
                            .padding(.bottom, 0)
                        }
                        .frame(width: vm.currentSize.width)
                    }
                }
            }
            // 裁剪超出圆角的内容
            .clipShape(NotchShape(
                topCornerRadius: vm.currentTopRadius,
                bottomCornerRadius: vm.currentBottomRadius
            ))
            .frame(width: vm.currentSize.width, height: vm.currentSize.height, alignment: .top)
            
            // --- 交互感应 ---
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
