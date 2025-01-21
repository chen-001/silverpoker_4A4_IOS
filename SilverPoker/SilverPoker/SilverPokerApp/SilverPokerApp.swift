import SwiftUI

@main
struct SilverPokerApp: App {
    @StateObject private var gameViewModel = GameViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(gameViewModel)
        }
    }
} 