import SwiftUI

struct PlayerCardsView: View {
    @EnvironmentObject private var gameViewModel: GameViewModel
    @State private var draggedCard: String?
    @State private var draggedOffset = CGSize.zero
    @State private var isDragging = false
    @State private var targetPosition: CGPoint = .zero
    @State private var sourceIndex: Int?
    @State private var targetIndex: Int?
    
    private let cardWidth: CGFloat = 27  // 增加卡牌宽度
    private let cardHeight: CGFloat = 45  // 增加卡牌高度
    private let cardOverlap: CGFloat = 3  // 调整水平重叠
    private let rowOverlap: CGFloat = 5  // 调整垂直重叠
    
    var body: some View {
        GeometryReader { geometry in
            let availableWidth = geometry.size.width - 20 // 保持左右padding
            let cardsPerRow = max(1, Int((availableWidth + cardOverlap) / (cardWidth - cardOverlap)))
            let rows = createRows(cards: gameViewModel.localCardOrder, cardsPerRow: cardsPerRow)
            
            ZStack {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: -rowOverlap) {
                        ForEach(Array(rows.enumerated()), id: \.0) { rowIndex, rowCards in
                            HStack(spacing: -cardOverlap) {
                                ForEach(Array(rowCards.enumerated()), id: \.0) { cardIndex, card in
                                    let cardId = "\(card)_\(rowIndex)_\(cardIndex)"
                                    let isBeingDragged = draggedCard == card
                                    
                                    CardView(
                                        card: card,
                                        isSelected: gameViewModel.selectedCards.contains(cardId)
                                    )
                                    .frame(width: cardWidth, height: cardHeight)
                                    .offset(y: gameViewModel.selectedCards.contains(cardId) ? -20 : 0)
                                    .opacity(isBeingDragged ? 0.5 : 1)  // 被拖拽的卡牌变透明
                                    .zIndex(gameViewModel.selectedCards.contains(cardId) ? 1 : 0)
                                    .onTapGesture {
                                        handleCardSelection(cardId, card: card)
                                    }
                                    .overlay(
                                        GeometryReader { proxy in
                                            Color.clear
                                                .preference(
                                                    key: CardPositionPreferenceKey.self,
                                                    value: [CardPosition(card: card, frame: proxy.frame(in: .named("scroll")))]
                                                )
                                        }
                                    )
                                    .gesture(
                                        DragGesture(minimumDistance: 5, coordinateSpace: .named("scroll"))
                                            .onChanged { value in
                                                if draggedCard == nil {
                                                    draggedCard = card
                                                    isDragging = true
                                                    sourceIndex = gameViewModel.localCardOrder.firstIndex(of: card)
                                                }
                                                draggedOffset = value.translation
                                                
                                                // 计算目标位置
                                                if let sourceIdx = sourceIndex {
                                                    targetIndex = findTargetIndex(
                                                        for: value.location,
                                                        in: geometry,
                                                        cardsPerRow: cardsPerRow,
                                                        rowIndex: rowIndex,
                                                        cardIndex: cardIndex
                                                    )
                                                }
                                            }
                                            .onEnded { _ in
                                                // 在拖拽结束时更新卡牌顺序
                                                if let sourceIdx = sourceIndex,
                                                   let targetIdx = targetIndex,
                                                   sourceIdx != targetIdx {
                                                    withAnimation(.easeInOut(duration: 0.2)) {
                                                        let card = gameViewModel.localCardOrder.remove(at: sourceIdx)
                                                        gameViewModel.localCardOrder.insert(card, at: targetIdx)
                                                    }
                                                }
                                                
                                                withAnimation(.easeInOut(duration: 0.2)) {
                                                    draggedCard = nil
                                                    draggedOffset = .zero
                                                    isDragging = false
                                                    sourceIndex = nil
                                                    targetIndex = nil
                                                }
                                            }
                                    )
                                }
                            }
                            .padding(.horizontal, 10)
                        }
                    }
                    .padding(.vertical, 10)
                }
                .frame(minHeight: 200)
                .coordinateSpace(name: "scroll")
                
                // 拖拽时的浮动卡牌
                if let draggingCard = draggedCard {
                    GeometryReader { geo in
                        CardView(
                            card: draggingCard,
                            isSelected: false
                        )
                        .frame(width: cardWidth, height: cardHeight)
                        .position(x: draggedOffset.width + cardWidth/2, y: draggedOffset.height + cardHeight/2)
                    }
                    .zIndex(100)
                }
            }
        }
        .frame(maxHeight: .infinity)
    }
    
    private func findTargetIndex(
        for location: CGPoint,
        in geometry: GeometryProxy,
        cardsPerRow: Int,
        rowIndex: Int,
        cardIndex: Int
    ) -> Int {
        let totalCards = gameViewModel.localCardOrder.count
        
        // 计算垂直方向的行号
        let effectiveCardHeight = cardHeight - rowOverlap
        let verticalPadding: CGFloat = 10
        let relativeY = max(0, location.y - verticalPadding)
        let targetRow = Int(relativeY / effectiveCardHeight)
        
        // 计算水平方向的位置
        let effectiveCardWidth = cardWidth - cardOverlap
        let horizontalPadding: CGFloat = 10
        let relativeX = max(0, location.x - horizontalPadding)
        let targetColumn = Int(relativeX / effectiveCardWidth)
        
        // 计算总行数
        let totalRows = (totalCards + cardsPerRow - 1) / cardsPerRow
        
        // 确保行号不超出范围
        let safeRow = min(targetRow, totalRows - 1)
        
        // 计算最后一行的卡牌数
        let lastRowCards = totalCards % cardsPerRow
        let cardsInTargetRow = safeRow == totalRows - 1 && lastRowCards > 0 ? lastRowCards : cardsPerRow
        
        // 确保列号不超出范围
        let safeColumn = min(targetColumn, cardsInTargetRow - 1)
        
        // 计算目标索引
        let targetIndex = safeRow * cardsPerRow + safeColumn
        
        // 确保最终索引不超出总卡牌数
        return min(max(0, targetIndex), totalCards - 1)
    }
    
    private func createRows(cards: [String], cardsPerRow: Int) -> [[String]] {
        var rows: [[String]] = []
        var currentRow: [String] = []
        
        for card in cards {
            currentRow.append(card)
            if currentRow.count == cardsPerRow {
                rows.append(currentRow)
                currentRow = []
            }
        }
        
        if !currentRow.isEmpty {
            rows.append(currentRow)
        }
        
        return rows
    }
    
    private func handleCardSelection(_ cardId: String, card: String) {
        if isDragging { return }  // 如果正在拖动，不处理选择
        
        if gameViewModel.selectedCards.contains(cardId) {
            gameViewModel.selectedCards.remove(cardId)
        } else {
            gameViewModel.selectedCards.insert(cardId)
        }
    }
}

struct CardView: View {
    let card: String
    let isSelected: Bool
    
    private var isRedCard: Bool {
        card.hasPrefix("♥") || card.hasPrefix("♦")
    }
    
    private var suit: String {
        String(card.prefix(1))
    }
    
    private var rank: String {
        String(card.dropFirst())
    }
    
    var body: some View {
        ZStack {
            // 卡牌背景
            RoundedRectangle(cornerRadius: 6)
                .fill(
                    LinearGradient(
                        colors: [.white, Color.gray.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
            
            // 卡牌边框
            RoundedRectangle(cornerRadius: 6)
                .stroke(
                    isSelected ?
                    LinearGradient(colors: [.green, .blue], startPoint: .topLeading, endPoint: .bottomTrailing) :
                    LinearGradient(colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: isSelected ? 2 : 1
                )
            
            // 卡牌内容 - 竖向排列
            VStack(spacing: 2) {
                Text(rank)
                    .font(.system(size: 16, weight: .medium))  // 增大字体
                Text(suit)
                    .font(.system(size: 16, weight: .medium))  // 增大字体
            }
            .foregroundColor(isRedCard ? .red : .black)
        }
        .frame(width: 27, height: 45)  // 匹配新的卡牌尺寸
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
    }
}

// 添加位置偏好键
struct CardPosition: Equatable {
    let card: String
    let frame: CGRect
}

struct CardPositionPreferenceKey: PreferenceKey {
    static var defaultValue: [CardPosition] = []
    
    static func reduce(value: inout [CardPosition], nextValue: () -> [CardPosition]) {
        value.append(contentsOf: nextValue())
    }
}

#Preview {
    PlayerCardsView()
        .environmentObject(GameViewModel())
} 