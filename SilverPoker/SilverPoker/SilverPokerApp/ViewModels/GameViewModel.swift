import Foundation
import Combine

class GameViewModel: ObservableObject {
    @Published var roomId: String = ""
    @Published var playerNumber: Int = -1
    @Published var playerNames: [Int: String] = [:]
    @Published var playerCardCounts: [Int: Int] = [:]
    @Published var scores: [Int: Int] = [:]
    @Published var currentPlayerIndex: Int = -1
    @Published var cards: [String] = []
    @Published var localCardOrder: [String] = []  // 添加本地手牌顺序数组
    @Published var lastCards: [String] = []
    @Published var lastPlayerName: String = ""
    @Published var canFork: Bool = false
    @Published var waitingForHook: Bool = false
    @Published var canHook: Bool = false
    @Published var isGivingLight: Bool = false
    @Published var selectedCards: Set<String> = []
    @Published var errorMessage: String = ""
    @Published var isGameStarted: Bool = false
    @Published var playerCount: Int = 0
    @Published var forkPlayer: Int?
    @Published var hookPlayer: Int?
    @Published var currentServer: String?
    @Published var isConnected: Bool = false
    @Published var showAlert = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""
    @Published var showThankYouAlert = false  // 添加新的状态变量
    
    // 添加特效状态属性
    @Published var brickEffects: [(id: UUID, index: Int)] = []
    @Published var fireEffects: [(id: UUID, index: Int)] = []
    @Published var cryEmojis: [(id: UUID, index: Int)] = []
    @Published var angryEmojis: [(id: UUID, index: Int)] = []
    @Published var hotTexts: [(id: UUID, index: Int)] = []
    @Published var shakeEffects: [(id: UUID, index: Int)] = []
    
    private let serverUrls = [
        "hk": "wss://silverpoker.redheartco.shop/game",
        "tx": "wss://django-6h56-136494-9-1337520003.sh.run.tcloudbase.com/game"
    ]
    
    private var webSocketService: WebSocketService?
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupWebSocket()
    }
    
    private func setupWebSocket() {
        // 断开现有连接
        webSocketService = nil
        cancellables.removeAll()
        
        let serverUrl = currentServer ?? serverUrls["tx"] ?? "ws://localhost:8000/game"
        print("正在连接到服务器：\(serverUrl)")
        
        webSocketService = WebSocketService(url: serverUrl)
        webSocketService?.messagePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.handleWebSocketMessage(message)
            }
            .store(in: &cancellables)
            
        // 添加连接状态监听
        webSocketService?.connectionStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isConnected in
                self?.isConnected = isConnected
                if !isConnected {
                    self?.errorMessage = "服务器连接断开，请检查网络或切换线路"
                } else {
                    self?.errorMessage = ""
                }
            }
            .store(in: &cancellables)
    }
    
    func setServer(_ type: String) {
        if type == "custom" {
            return
        }
        print("切换到服务器：\(type)")
        currentServer = serverUrls[type]
        setupWebSocket()
        showAlertMessage(title: "提示", message: "正在连接到服务器...")
    }
    
    func setCustomServer(_ url: String) {
        print("切换到自定义服务器：\(url)")
        currentServer = url
        setupWebSocket()
        showAlertMessage(title: "提示", message: "正在连接到自定义服务器...")
    }
    
    func createRoom(deckCount: Int) {
        let message: [String: Any] = ["action": "create_room", "deck_count": deckCount]
        webSocketService?.send(message)
    }
    
    func joinRoom(roomId: String) {
        let message: [String: Any] = ["action": "join_room", "room_id": roomId]
        webSocketService?.send(message)
    }
    
    func startGame() {
        let message: [String: Any] = ["action": "start_game"]
        webSocketService?.send(message)
    }
    
    func playCards() {
        let actualCards = selectedCards.map { cardId -> String in
            // 从cardId中提取实际的卡牌值（格式：card_rowIndex_cardIndex）
            // 例如：从 "♠A_0_1" 中提取 "♠A"
            if cardId.contains("_") {
                return String(cardId.split(separator: "_")[0])
            }
            return cardId
        }
        print("出牌：\(actualCards)") // 添加日志
        let message: [String: Any] = ["action": "play_cards", "cards": actualCards]
        webSocketService?.send(message)
        // 清空选中的牌
        selectedCards.removeAll()
    }
    
    func pass() {
        let message: [String: Any] = ["action": "pass"]
        webSocketService?.send(message)
    }
    
    func changeName(newName: String) {
        let message: [String: Any] = ["action": "change_name", "name": newName]
        webSocketService?.send(message)
    }
    
    func throwBrick(toPlayer: Int) {
        let message: [String: Any] = ["action": "throw_brick", "from_player": playerNumber, "to_player": toPlayer]
        print("发送扔砖头消息：\(message)")
        webSocketService?.send(message)
    }
    
    func showFire() {
        let message: [String: Any] = ["action": "show_fire", "player_index": playerNumber]
        print("发送显示火焰消息：\(message)")
        webSocketService?.send(message)
    }
    
    func showAlertMessage(title: String, message: String) {
        print("显示弹窗 - 标题：\(title), 消息：\(message)")  // 添加日志
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.alertTitle = title
            self.alertMessage = message
            self.showAlert = true
            print("弹窗状态已设置：\(self.showAlert)")  // 添加日志
        }
    }
    
    private func handleWebSocketMessage(_ message: [String: Any]) {
        guard let action = message["action"] as? String else { return }
        print("收到WebSocket消息 - 动作类型：\(action)")
        print("完整消息内容：\(message)")
        
        switch action {
        case "room_created":
            if let roomId = message["room_id"] as? String {
                DispatchQueue.main.async {
                    self.roomId = roomId
                    self.isGameStarted = true
                    self.showAlertMessage(title: "成功", message: "房间创建成功！")
                }
            }
            
        case "joined_room":
            if let success = message["success"] as? Bool {
                DispatchQueue.main.async {
                    if success {
                        self.isGameStarted = true
                        self.showAlertMessage(title: "成功", message: "成功加入房间！")
                    } else if let errorMsg = message["message"] as? String {
                        self.showAlertMessage(title: "错误", message: errorMsg)
                    }
                }
            }
            
        case "game_started":
            DispatchQueue.main.async {
                self.showAlertMessage(title: "游戏开始", message: "游戏开始了！")
            }
            
        case "room_state":
            if let count = message["player_count"] as? Int {
                DispatchQueue.main.async {
                    self.playerCount = count
                }
            }
            
        case "game_state":
            DispatchQueue.main.async {
                self.updateGameState(from: message)
            }
            
        case "game_over":
            print("收到游戏结束消息：\(message)")  // 添加日志
            DispatchQueue.main.async {
                self.handleGameOver(message)
                print("游戏结束处理完成，弹窗状态：\(self.showAlert)")  // 添加日志
            }
            
        case "throw_brick":
            print("收到扔砖头消息，完整内容：\(message)")
            if let fromPlayer = message["from_player"] as? Int,
               let toPlayer = message["to_player"] as? Int {
                print("玩家\(fromPlayer)扔砖头给玩家\(toPlayer)")
                DispatchQueue.main.async {
                    // 触发砖头动画
                    let effectId = UUID()
                    print("创建砖头特效 - ID: \(effectId)")
                    
                    // 添加特效前的状态
                    print("当前特效状态：")
                    print("- 砖头特效数量：\(self.brickEffects.count)")
                    print("- 哭脸特效数量：\(self.cryEmojis.count)")
                    print("- 震动特效数量：\(self.shakeEffects.count)")
                    
                    self.brickEffects.append((id: effectId, index: toPlayer))
                    self.cryEmojis.append((id: effectId, index: toPlayer))
                    self.shakeEffects.append((id: effectId, index: toPlayer))
                    
                    // 添加特效后的状态
                    print("添加特效后的状态：")
                    print("- 砖头特效数量：\(self.brickEffects.count)")
                    print("- 哭脸特效数量：\(self.cryEmojis.count)")
                    print("- 震动特效数量：\(self.shakeEffects.count)")
                    
                    // 延迟移除特效
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        print("准备移除特效 - ID: \(effectId)")
                        let beforeRemoveCount = self.brickEffects.count
                        self.brickEffects.removeAll { $0.id == effectId }
                        self.cryEmojis.removeAll { $0.id == effectId }
                        self.shakeEffects.removeAll { $0.id == effectId }
                        let afterRemoveCount = self.brickEffects.count
                        print("特效移除完成 - 移除前数量: \(beforeRemoveCount), 移除后数量: \(afterRemoveCount)")
                    }
                }
            } else {
                print("❌ 扔砖头消息格式错误：缺少必要参数")
                print("from_player: \(message["from_player"] ?? "nil")")
                print("to_player: \(message["to_player"] ?? "nil")")
            }
            
        case "show_fire":
            print("收到显示火焰消息，完整内容：\(message)")
            if let playerIndex = message["player_index"] as? Int {
                print("玩家\(playerIndex)显示火焰特效")
                DispatchQueue.main.async {
                    // 触发火焰动画
                    let effectId = UUID()
                    print("创建火焰特效 - ID: \(effectId)")
                    
                    // 添加特效前的状态
                    print("当前特效状态：")
                    print("- 火焰特效数量：\(self.fireEffects.count)")
                    print("- 生气表情数量：\(self.angryEmojis.count)")
                    print("- 文字特效数量：\(self.hotTexts.count)")
                    
                    self.fireEffects.append((id: effectId, index: playerIndex))
                    self.angryEmojis.append((id: effectId, index: playerIndex))
                    self.hotTexts.append((id: effectId, index: playerIndex))
                    
                    // 添加特效后的状态
                    print("添加特效后的状态：")
                    print("- 火焰特效数量：\(self.fireEffects.count)")
                    print("- 生气表情数量：\(self.angryEmojis.count)")
                    print("- 文字特效数量：\(self.hotTexts.count)")
                    
                    // 延迟移除特效
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        print("准备移除特效 - ID: \(effectId)")
                        let beforeRemoveCount = self.fireEffects.count
                        self.fireEffects.removeAll { $0.id == effectId }
                        self.angryEmojis.removeAll { $0.id == effectId }
                        self.hotTexts.removeAll { $0.id == effectId }
                        let afterRemoveCount = self.fireEffects.count
                        print("特效移除完成 - 移除前数量: \(beforeRemoveCount), 移除后数量: \(afterRemoveCount)")
                    }
                }
            } else {
                print("❌ 显示火焰消息格式错误：缺少必要参数")
                print("player_index: \(message["player_index"] ?? "nil")")
            }
            
        case "error":
            if let errorMsg = message["message"] as? String {
                DispatchQueue.main.async {
                    self.showAlertMessage(title: "错误", message: errorMsg)
                }
            }
            
        default:
            print("未处理的消息类型：\(action)")
            break
        }
    }
    
    private func updateGameState(from message: [String: Any]) {
        if let cards = message["cards"] as? [String] {
            self.cards = cards
            // 当收到新的手牌时，初始化本地顺序
            if self.localCardOrder.isEmpty {
                self.localCardOrder = cards
                // 显示致谢弹窗
                DispatchQueue.main.asyncAfter(deadline: .now() ) {
                    self.showThankYouAlert = true
                }
            } else {
                // 处理新增和移除的牌
                let newCards = Set(cards)
                let oldCards = Set(self.localCardOrder)
                
                // 移除不存在的牌
                self.localCardOrder.removeAll { !newCards.contains($0) }
                
                // 添加新的牌到末尾
                for card in cards {
                    if !oldCards.contains(card) {
                        self.localCardOrder.append(card)
                    }
                }
            }
        }
        
        if let playerNumber = message["player_number"] as? Int {
            self.playerNumber = playerNumber
        }
        
        if let names = message["player_names"] as? [String: String] {
            self.playerNames = names.compactMapKeys { Int($0) }
        }
        
        if let cardCounts = message["player_card_counts"] as? [String: Int] {
            self.playerCardCounts = cardCounts.compactMapKeys { Int($0) }
        }
        
        if let scores = message["scores"] as? [String: Int] {
            self.scores = scores.compactMapKeys { Int($0) }
        }
        
        // 检查还有手牌的玩家数量
        if let cardCounts = message["player_card_counts"] as? [String: Int],
           let scores = message["scores"] as? [String: Int] {
            // 计算还有手牌的玩家数量
            let playersWithCards = cardCounts.values.filter { $0 > 0 }.count
            print("还有手牌的玩家数量：\(playersWithCards)")
            
            // 当只剩1个玩家有手牌时，游戏结束
            if playersWithCards == 1 {
                print("检测到游戏结束状态：只剩1个玩家有手牌")
                handleGameOver([
                    "scores": scores,
                    "round_scores": cardCounts.mapValues { -$0 }  // 使用剩余手牌数作为负分
                ])
                return
            }
        }
        
        if let currentPlayer = message["current_player"] as? Bool {
            self.currentPlayerIndex = currentPlayer ? playerNumber : -1
        }
        
        if let lastCards = message["last_cards"] as? [String: Any] {
            self.lastCards = lastCards["cards"] as? [String] ?? []
            self.lastPlayerName = lastCards["player_name"] as? String ?? ""
        }
        
        self.canFork = message["can_fork"] as? Bool ?? false
        self.waitingForHook = message["waiting_for_hook"] as? Bool ?? false
        self.canHook = message["can_hook"] as? Bool ?? false
        self.isGivingLight = message["is_giving_light"] as? Bool ?? false
        self.forkPlayer = message["fork_player"] as? Int
        self.hookPlayer = message["hook_player"] as? Int
    }
    
    private func handleGameOver(_ message: [String: Any]) {
        guard let scores = message["scores"] as? [String: Int],
              let roundScores = message["round_scores"] as? [String: Int] else {
            print("游戏结束数据格式错误：\(message)")  // 添加错误日志
            return
        }
        
        // 更新总分
        self.scores = scores.compactMapKeys { Int($0) }
        
        // 构建得分信息字符串
        var scoreMessage = "本局得分\n"
        scoreMessage += "━━━━━━━━━━━━━━\n"
        let sortedPlayers = scores.sorted { Int($0.key)! < Int($1.key)! }
        
        // 显示本局得分
        for (playerKey, _) in sortedPlayers {
            let playerIndex = Int(playerKey)!
            let playerName = self.playerNames[playerIndex] ?? "玩家\(playerIndex + 1)"
            let roundScore = roundScores[playerKey] ?? 0
            let scoreSymbol = roundScore >= 0 ? "+" : ""
            scoreMessage += "\(playerName)：\(scoreSymbol)\(roundScore)分\n"
        }
        
        // 显示总分
        scoreMessage += "\n总分情况\n"
        scoreMessage += "━━━━━━━━━━━━━━\n"
        for (playerKey, totalScore) in sortedPlayers {
            let playerIndex = Int(playerKey)!
            let playerName = self.playerNames[playerIndex] ?? "玩家\(playerIndex + 1)"
            scoreMessage += "\(playerName)：\(totalScore)分\n"
        }
        
        print("准备显示得分弹窗：\n\(scoreMessage)")  // 添加日志
        
        // 显示得分弹窗
        showAlertMessage(title: "游戏结束", message: scoreMessage)
        
        // 重置游戏状态，但保持在房间中
        self.selectedCards.removeAll()
        self.lastCards.removeAll()
        self.lastPlayerName = ""
        self.currentPlayerIndex = -1
        self.canFork = false
        self.waitingForHook = false
        self.canHook = false
        self.isGivingLight = false
        self.forkPlayer = nil
        self.hookPlayer = nil
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("✅ WebSocket 连接成功")
        showAlertMessage(title: "成功", message: "服务器连接成功！")
    }
}

extension Dictionary {
    func compactMapKeys<T>(_ transform: (Key) throws -> T?) rethrows -> [T: Value] {
        var result: [T: Value] = [:]
        for (key, value) in self {
            if let transformedKey = try transform(key) {
                result[transformedKey] = value
            }
        }
        return result
    }
} 