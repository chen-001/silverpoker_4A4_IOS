import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var gameViewModel: GameViewModel
    @State private var showingNamePrompt = false
    @State private var newName = ""
    @State private var selectedDeckCount = 1
    @State private var roomIdInput = ""
    @State private var currentBackgroundIndex = 0
    @State private var showingServerDialog = false
    @State private var customServerUrl = ""
    @State private var showingCustomServerInput = false
    
    private let backgrounds = [
        "p1", "p2", "p3", "p4", "p5",
        "7", "8", "9", "10", "11", "12", "13",
        "14", "15", "16", "17", "18", "19"
    ]
    
    var body: some View {
        ZStack {
            // 背景图片
            Image(backgrounds[currentBackgroundIndex])
                .resizable()
                .ignoresSafeArea()
                .overlay(Color.white.opacity(0.8))
            
            VStack(spacing: 20) {
                // 标题
                Text("银姐快乐牌")
                    .font(.system(size: 36))
                    .fontWeight(.bold)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .green, .pink],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .padding(.top, 5)
                
                // 换装按钮
                Button(action: changeBackground) {
                    Text("银姐换装")
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [.pink, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
                if !gameViewModel.isGameStarted {
                    // 登录部分
                    loginSection
                } else {
                    // 游戏部分
                    gameSection
                }
            }
            .padding()
        }
        .alert("修改名称", isPresented: $showingNamePrompt) {
            TextField("新名称", text: $newName)
            Button("确定") {
                if !newName.isEmpty {
                    gameViewModel.changeName(newName: newName)
                }
            }
            Button("取消", role: .cancel) {}
        }
        .alert(gameViewModel.alertTitle, isPresented: $gameViewModel.showAlert) {
            Button("确定", role: .cancel) {
                print("关闭弹窗")
            }
        } message: {
            Text(gameViewModel.alertMessage)
                .font(.system(.body, design: .monospaced))
                .multilineTextAlignment(.leading)
        }
        .onChange(of: gameViewModel.showAlert) { newValue in
            print("弹窗状态改变：\(newValue)")
        }
        .overlay {
            if gameViewModel.showThankYouAlert {
                CustomThankYouAlert(
                    isPresented: $gameViewModel.showThankYouAlert,
                    title: "六六让我致谢",
                    message: "感谢银姐及其爱人帮助测试bug\n银姐祝各位玩家牌运🤙🤙🤙"
                )
            }
        }
    }
    
    private func changeBackground() {
        withAnimation(.easeInOut(duration: 0.5)) {
            let randomIndex = Int.random(in: 0..<backgrounds.count)
            currentBackgroundIndex = randomIndex
        }
        
        // 添加震动反馈
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        // 添加衣物动画效果
        // 这部分可以在后续实现
    }
    
    private var loginSection: some View {
        VStack(spacing: 15) {
            // 选择牌数
            Picker("牌数", selection: $selectedDeckCount) {
                Text("1副牌").tag(1)
                Text("2副牌").tag(2)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            
            // 选择线路按钮
            Button(action: {
                showingServerDialog = true
            }) {
                HStack {
                    Text("选择线路")
                    if gameViewModel.isConnected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    } else {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundColor(.red)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            
            // 创建房间按钮
            Button(action: {
                if gameViewModel.isConnected {
                    gameViewModel.createRoom(deckCount: selectedDeckCount)
                } else {
                    gameViewModel.showAlertMessage(title: "错误", message: "请先连接到服务器")
                }
            }) {
                Text("创建/重回房间")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [.purple, .pink],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(!gameViewModel.isConnected)
            
            // 加入房间
            HStack {
                TextField("输入房间号", text: $roomIdInput)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button(action: {
                    if gameViewModel.isConnected {
                        gameViewModel.joinRoom(roomId: roomIdInput)
                    } else {
                        gameViewModel.showAlertMessage(title: "错误", message: "请先连接到服务器")
                    }
                }) {
                    Text("加入房间")
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(!gameViewModel.isConnected)
            }
        }
        .sheet(isPresented: $showingServerDialog) {
            serverDialogView
        }
    }
    
    private var serverDialogView: some View {
        NavigationView {
            List {
                Button(action: {
                    gameViewModel.setServer("hk")
                    showingServerDialog = false
                }) {
                    Text("线路1: 香港服务器")
                }
                
                Button(action: {
                    gameViewModel.setServer("tx")
                    showingServerDialog = false
                }) {
                    Text("线路2: 腾讯服务器")
                }
                
                Button(action: {
                    showingCustomServerInput = true
                }) {
                    Text("线路3: 自定义线路")
                }
                
                if showingCustomServerInput {
                    TextField("请输入服务器地址", text: $customServerUrl)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onSubmit {
                            if !customServerUrl.isEmpty {
                                gameViewModel.setCustomServer(customServerUrl)
                                showingServerDialog = false
                            }
                        }
                }
            }
            .navigationTitle("选择服务器线路")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        showingServerDialog = false
                    }
                }
            }
        }
    }
    
    private var gameSection: some View {
        VStack(spacing: 10) {
            // 房间信息
            HStack {
                Text("房间号：\(gameViewModel.roomId)")
                Text("(\(gameViewModel.playerCount)/6 玩家)")
            }
            
            // 玩家列表
            PlayerListView()
            
            // 上一手牌
            LastCardsView()
            
            // 玩家手牌区域 - 使用Spacer来占据所有可用空间
            ScrollView(.vertical, showsIndicators: false) {
                PlayerCardsView()
                    .padding(.bottom, 5)
            }
            
            // 游戏控制按钮
            GameControlsView()
                .padding(.bottom, 5)
            
            // 底部按钮栏 - 使用最小间距
            HStack(spacing: 10) {
                Button("开始游戏") {
                    gameViewModel.startGame()
                }
                .buttonStyle(GradientButtonStyle(colors: [.blue, .cyan]))
                
                Button("回到首页") {
                    gameViewModel.isGameStarted = false
                }
                .buttonStyle(GradientButtonStyle(colors: [.purple, .pink]))
                
                Button("修改名称") {
                    showingNamePrompt = true
                }
                .buttonStyle(GradientButtonStyle(colors: [.orange, .yellow]))
            }
            .padding(.horizontal, 5)
            .padding(.bottom, 5)
        }
    }
}

struct GradientButtonStyle: ButtonStyle {
    let colors: [Color]
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(
                LinearGradient(
                    colors: colors,
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
    }
}

#Preview {
    ContentView()
        .environmentObject(GameViewModel())
} 