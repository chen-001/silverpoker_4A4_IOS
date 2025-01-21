import SwiftUI

struct GameControlsView: View {
    @EnvironmentObject private var gameViewModel: GameViewModel
    
    var body: some View {
        HStack(spacing: 15) {
            // 过牌按钮
            Button(action: {
                gameViewModel.pass()
            }) {
                Text("过")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(GradientButtonStyle(
                colors: canPass ? [.indigo, .cyan] : [.gray.opacity(0.3), .gray.opacity(0.5)]
            ))
            .disabled(!canPass)
            
            // 出牌按钮
            Button(action: {
                gameViewModel.playCards()
            }) {
                Text("出牌")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(GradientButtonStyle(
                colors: isCurrentPlayer ? [.red, .orange] : [.gray.opacity(0.3), .gray.opacity(0.5)]
            ))
            .disabled(!canPlayCards)
            
            // 叉牌按钮
            if gameViewModel.canFork {
                Button(action: {
                    gameViewModel.playCards()
                }) {
                    Text("叉牌")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(GradientButtonStyle(colors: [.purple, .blue]))
            }
            
            // 勾牌按钮
            if gameViewModel.waitingForHook && gameViewModel.canHook {
                Button(action: {
                    gameViewModel.playCards()
                }) {
                    Text("勾牌")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(GradientButtonStyle(colors: [.green, .mint]))
            }
        }
        .padding(.horizontal)
    }
    
    private var isCurrentPlayer: Bool {
        gameViewModel.currentPlayerIndex == gameViewModel.playerNumber
    }
    
    private var canPass: Bool {
        // 当是当前玩家，或者可以叉牌时，都可以过牌
        return isCurrentPlayer || gameViewModel.canFork
    }
    
    private var canPlayCards: Bool {
        let hasSelectedCards = !gameViewModel.selectedCards.isEmpty
        // 当是当前玩家，有选中的牌，并且不是在等待勾牌时，就可以出牌
        return isCurrentPlayer && hasSelectedCards && !gameViewModel.waitingForHook
    }
}

#Preview {
    GameControlsView()
        .environmentObject(GameViewModel())
} 