import SwiftUI

struct LastCardsView: View {
    @EnvironmentObject private var gameViewModel: GameViewModel
    
    private let cardOverlap: CGFloat = 5  // 卡牌重叠的距离
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("上一手牌")
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: -cardOverlap) {  // 使用负值的spacing来创建重叠效果
                    if !gameViewModel.lastCards.isEmpty {
                        if !gameViewModel.lastPlayerName.isEmpty {
                            Text("\(gameViewModel.lastPlayerName)：")
                                .foregroundColor(.gray)
                                .padding(.trailing, cardOverlap)  // 补偿重叠距离
                        }
                        ForEach(gameViewModel.lastCards, id: \.self) { card in
                            CardView(card: card, isSelected: false)
                                .frame(width: 27, height: 45)
                                .zIndex(Double(gameViewModel.lastCards.firstIndex(of: card) ?? 0))  // 确保正确的重叠顺序
                        }
                    } else {
                        Text("无")
                            .foregroundColor(.gray)
                            .padding()
                    }
                }
                .padding(.horizontal)
            }
            .frame(height: 80)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
        }
    }
}

#Preview {
    LastCardsView()
        .environmentObject(GameViewModel())
} 