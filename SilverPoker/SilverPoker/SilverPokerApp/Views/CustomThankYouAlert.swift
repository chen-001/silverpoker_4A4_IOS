import SwiftUI

struct CustomThankYouAlert: View {
    @Binding var isPresented: Bool
    let title: String
    let message: String
    
    var body: some View {
        ZStack {
            // 半透明背景
            Color.black.opacity(0.5)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    withAnimation {
                        isPresented = false
                    }
                }
            
            // 弹窗内容
            VStack(spacing: 20) {
                // 背景图片
                Image("brick_hand")  // 使用提供的图片
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 150, height: 150)
                
                // 标题
                Text(title)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                // 消息内容
                Text(message)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // 确定按钮
                Button(action: {
                    withAnimation {
                        isPresented = false
                    }
                }) {
                    Text("确定")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 10)
                        .background(
                            LinearGradient(
                                colors: [.purple, .pink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(20)
                }
                .padding(.top, 10)
            }
            .padding(30)
            .background(
                Color.black.opacity(0.8)
                    .cornerRadius(20)
            )
            .shadow(radius: 10)
            .transition(.scale.combined(with: .opacity))
        }
    }
}

#Preview {
    CustomThankYouAlert(
        isPresented: .constant(true),
        title: "六六让我致谢",
        message: "感谢银姐及其爱人帮助测试bug\n银姐祝各位玩家牌运🤙🤙🤙"
    )
} 