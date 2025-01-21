import SwiftUI

// 添加砖头动画数据结构
struct BrickAnimation: Equatable {
    let fromIndex: Int
    let toIndex: Int
}

// 添加新的PlayerPositionReader视图
struct PlayerPositionReader: View {
    let index: Int
    let playerNumber: Int
    let flyingBrick: BrickAnimation?
    let updatePosition: (CGPoint) -> Void
    
    var body: some View {
        GeometryReader { geometry in
            Color.clear
                .onAppear {
                    if index == playerNumber {
                        updatePosition(CGPoint(x: geometry.frame(in: .global).midX,
                                            y: geometry.frame(in: .global).midY))
                    }
                    if let brick = flyingBrick, brick.toIndex == index {
                        let targetPosition = CGPoint(x: geometry.frame(in: .global).midX,
                                                   y: geometry.frame(in: .global).midY)
                        updatePosition(targetPosition)
                    }
                }
                .onChange(of: flyingBrick) { newValue in
                    if let brick = newValue, brick.toIndex == index {
                        let targetPosition = CGPoint(x: geometry.frame(in: .global).midX,
                                                   y: geometry.frame(in: .global).midY)
                        updatePosition(targetPosition)
                    }
                }
        }
    }
}

struct PlayerListView: View {
    @EnvironmentObject private var gameViewModel: GameViewModel
    @State private var brickPosition: CGPoint = .zero
    @State private var brickTargetPosition: CGPoint = .zero
    @State private var brickRotation: Double = 0
    @State private var flyingBrick: BrickAnimation? = nil
    @State private var brickAnimationProgress: Double = 0  // 添加动画进度状态
    
    // 计算容器宽度
    private var containerWidth: CGFloat {
        let cardWidth: CGFloat = 100  // 单个卡片宽度
        let spacing: CGFloat = 10     // 卡片间距
        let horizontalPadding: CGFloat = 20  // 水平内边距
        let playerCount = gameViewModel.playerCardCounts.count
        
        return cardWidth * CGFloat(playerCount) + spacing * CGFloat(playerCount - 1) + horizontalPadding * 2
    }
    
    // 添加固定高度常量
    private let containerHeight: CGFloat = 120
    
    // 计算抛物线路径上的点
    private func getParabolicPosition(start: CGPoint, end: CGPoint, progress: Double) -> CGPoint {
        let height: CGFloat = -200  // 增加抛物线高度
        let x = start.x + (end.x - start.x) * progress
        
        // 修改抛物线计算方式，使其更加明显
        let normalizedProgress = progress * 2 - 1 // 将进度转换为 -1 到 1
        let parabola = -(normalizedProgress * normalizedProgress) + 1 // 创建更明显的抛物线
        
        let y = start.y + (end.y - start.y) * progress + height * parabola
        
        print("抛物线计算 - 进度: \(progress), 高度系数: \(parabola), 结果位置: (\(x), \(y))")
        return CGPoint(x: x, y: y)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView(.horizontal, showsIndicators: false) {
                ZStack(alignment: .topLeading) {
                    // 背景容器
                    Color.clear
                        .frame(width: containerWidth, height: containerHeight)
                    
                    // 玩家卡片层
                    HStack(spacing: 10) {
                        ForEach(0..<6) { index in
                            if let cardCount = gameViewModel.playerCardCounts[index] {
                                ZStack {
                                    Color.clear
                                        .frame(width: 100, height: containerHeight)
                                        .background(
                                            GeometryReader { cardGeometry in
                                                Color.clear
                                                    .onAppear {
                                                        let cardFrame = cardGeometry.frame(in: .global)
                                                        if index == gameViewModel.playerNumber {
                                                            brickPosition = CGPoint(x: cardFrame.midX, y: cardFrame.midY)
                                                            print("设置起始位置 - 玩家\(index): \(brickPosition)")
                                                        }
                                                        if let brick = flyingBrick, brick.toIndex == index {
                                                            brickTargetPosition = CGPoint(x: cardFrame.midX, y: cardFrame.midY)
                                                            print("设置目标位置 - 玩家\(index): \(brickTargetPosition)")
                                                        }
                                                    }
                                                    .onChange(of: flyingBrick) { newValue in
                                                        let cardFrame = cardGeometry.frame(in: .global)
                                                        if index == gameViewModel.playerNumber {
                                                            brickPosition = CGPoint(x: cardFrame.midX, y: cardFrame.midY)
                                                            print("更新起始位置 - 玩家\(index): \(brickPosition)")
                                                        }
                                                        if let brick = newValue, brick.toIndex == index {
                                                            brickTargetPosition = CGPoint(x: cardFrame.midX, y: cardFrame.midY)
                                                            print("更新目标位置 - 玩家\(index): \(brickTargetPosition)")
                                                        }
                                                    }
                                            }
                                        )
                                    
                                    ZStack {
                                        PlayerCardView(
                                            playerIndex: index,
                                            playerName: gameViewModel.playerNames[index] ?? "玩家\(index + 1)",
                                            cardCount: cardCount,
                                            score: gameViewModel.scores[index] ?? 0,
                                            isCurrentPlayer: index == gameViewModel.currentPlayerIndex,
                                            isSelf: index == gameViewModel.playerNumber,
                                            isForking: gameViewModel.forkPlayer == index && gameViewModel.waitingForHook,
                                            isHooking: gameViewModel.hookPlayer == index,
                                            isShaking: gameViewModel.shakeEffects.contains(where: { $0.index == index }),
                                            containerHeight: containerHeight
                                        )
                                        .onTapGesture {
                                            handlePlayerTap(index: index)
                                        }
                                        
                                        // 特效视图
                                        PlayerEffectsView(
                                            index: index,
                                            brickEffects: gameViewModel.brickEffects,
                                            fireEffects: gameViewModel.fireEffects,
                                            cryEmojis: gameViewModel.cryEmojis,
                                            angryEmojis: gameViewModel.angryEmojis,
                                            hotTexts: gameViewModel.hotTexts
                                        )
                                    }
                                }
                            }
                        }
                    }
                    .frame(width: containerWidth, height: containerHeight)
                    
                    // 飞行中的砖头
                    Group {
                        if let _ = flyingBrick {
                            let currentPosition = getParabolicPosition(
                                start: brickPosition,
                                end: brickTargetPosition,
                                progress: brickAnimationProgress
                            )
                            
                            Image(systemName: "rectangle.fill")
                                .resizable()
                                .frame(width: 40, height: 20)
                                .foregroundColor(.brown)
                                .shadow(color: .black.opacity(0.3), radius: 3, x: 2, y: 2)
                                .rotationEffect(.degrees(brickRotation))
                                .position(currentPosition)
                                .zIndex(Double.infinity)
                                .onAppear {
                                    print("当前动画进度: \(brickAnimationProgress)")
                                    print("当前位置: \(currentPosition)")
                                }
                        }
                    }
                }
            }
            .frame(height: containerHeight)
        }
    }
    
    private func handlePlayerTap(index: Int) {
        if index != gameViewModel.playerNumber {
            // 扔砖头
            gameViewModel.throwBrick(toPlayer: index)
            
            // 重置动画状态
            brickAnimationProgress = 0
            brickRotation = 0
            
            // 设置动画
            flyingBrick = BrickAnimation(fromIndex: gameViewModel.playerNumber, toIndex: index)
            
            // 添加调试日志
            print("砖头动画开始 - 从玩家\(gameViewModel.playerNumber)到玩家\(index)")
            print("起始位置: \(brickPosition)")
            print("目标位置: \(brickTargetPosition)")
            
            // 确保位置已经设置好后再开始动画
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                // 执行砖头飞行动画
                withAnimation(
                    .easeInOut(duration: 1.0)
                        .repeatCount(1, autoreverses: false)
                ) {
                    brickAnimationProgress = 1
                    brickRotation += 720
                }
            }
            
            // 添加震动反馈
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.impactOccurred()
            
            // 如果被砖头打中的是自己，添加更强的震动
            if index == gameViewModel.playerNumber {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    let heavyGenerator = UIImpactFeedbackGenerator(style: .rigid)
                    heavyGenerator.impactOccurred()
                }
            }
            
            // 延迟移除特效
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {  // 稍微延长等待时间
                print("砖头动画结束 - 最终位置: \(brickPosition)")
                flyingBrick = nil
                brickAnimationProgress = 0  // 重置动画进度
            }
        } else {
            // 显示火焰
            gameViewModel.showFire()
            
            // 添加震动反馈
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.impactOccurred()
        }
    }
}

// 修改特效视图组件
struct PlayerEffectsView: View {
    let index: Int
    let brickEffects: [(id: UUID, index: Int)]
    let fireEffects: [(id: UUID, index: Int)]
    let cryEmojis: [(id: UUID, index: Int)]
    let angryEmojis: [(id: UUID, index: Int)]
    let hotTexts: [(id: UUID, index: Int)]
    
    var body: some View {
        ZStack {
            // 砖头特效
            ForEach(brickEffects.filter { $0.index == index }, id: \.id) { _ in
                Image(systemName: "rectangle.fill")  // 改用rectangle.fill
                    .resizable()  // 使图标可调整大小
                    .frame(width: 40, height: 20)  // 修改为长方形尺寸
                    .foregroundColor(.brown)
                    .rotationEffect(.degrees(45))
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .move(edge: .leading)),
                        removal: .scale.combined(with: .opacity)
                    ))
            }
            
            // 苦脸表情
            ForEach(cryEmojis.filter { $0.index == index }, id: \.id) { _ in
                Text("😭")
                    .font(.system(size: 30))
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .offset(y: -40)
            }
            
            // 火焰特效
            ForEach(fireEffects.filter { $0.index == index }, id: \.id) { _ in
                ZStack {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.orange.opacity(0.8))
                        .shadow(color: .red, radius: 10)
                    
                    Image(systemName: "flame.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.yellow.opacity(0.8))
                        .shadow(color: .orange, radius: 5)
                }
                .transition(.scale.combined(with: .opacity))
            }
            
            // 发怒表情
            ForEach(angryEmojis.filter { $0.index == index }, id: \.id) { _ in
                Text("😡")
                    .font(.system(size: 30))
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .offset(y: -40)
            }
            
            // "红温了"文字
            ForEach(hotTexts.filter { $0.index == index }, id: \.id) { _ in
                Text("红温了")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        LinearGradient(
                            colors: [.red, .orange],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(8)
                    .shadow(color: .red.opacity(0.5), radius: 5)
                    .transition(.scale.combined(with: .opacity))
                    .offset(y: 40)
            }
        }
    }
}

struct PlayerCardView: View {
    let playerIndex: Int
    let playerName: String
    let cardCount: Int
    let score: Int
    let isCurrentPlayer: Bool
    let isSelf: Bool
    let isForking: Bool
    let isHooking: Bool
    let isShaking: Bool
    let containerHeight: CGFloat  // 添加高度参数
    
    @EnvironmentObject private var gameViewModel: GameViewModel
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // 创建一个固定大小的容器
            Color.clear
                .frame(width: 100, height: containerHeight)
            
            // 玩家卡片内容
            VStack {
                Text(playerName)
                    .font(.headline)
                Text("\(cardCount)张牌")
                    .font(.subheadline)
                Text("得分: \(score)")
                    .font(.caption)
            }
            .frame(width: 100, height: containerHeight)  // 使用传入的高度
            .background(backgroundGradient)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        isCurrentPlayer ? Color.green : Color.clear,
                        lineWidth: 2
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        isSelf ? Color.blue : Color.clear,
                        lineWidth: 2
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        isForking ? Color.purple : Color.clear,
                        lineWidth: 2
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        isHooking ? Color.orange : Color.clear,
                        lineWidth: 2
                    )
            )
            // 使用水平方向的偏移替代缩放
            .offset(x: isAnimating ? -5 : 0)  // 向左偏移5个点
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isAnimating)
            .onChange(of: isShaking) { newValue in
                if newValue {
                    withAnimation(.default.repeatCount(3)) {
                        isAnimating = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        isAnimating = false
                    }
                }
            }
        }
    }
    
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                .white,
                Color.gray.opacity(0.1)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// 添加震动效果修饰符
struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 10
    var shakesPerUnit = 3
    var animatableData: CGFloat
    
    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX:
            amount * sin(animatableData * .pi * CGFloat(shakesPerUnit)),
            y: 0))
    }
}

#Preview {
    PlayerListView()
        .environmentObject(GameViewModel())
} 