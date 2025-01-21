import Foundation
import Combine

class WebSocketService: NSObject, URLSessionWebSocketDelegate {
    private var webSocket: URLSessionWebSocketTask?
    private let messageSubject = PassthroughSubject<[String: Any], Never>()
    private let connectionStateSubject = PassthroughSubject<Bool, Never>()
    private let serverUrl: String
    
    var messagePublisher: AnyPublisher<[String: Any], Never> {
        messageSubject.eraseToAnyPublisher()
    }
    
    var connectionStatePublisher: AnyPublisher<Bool, Never> {
        connectionStateSubject.eraseToAnyPublisher()
    }
    
    init(url: String = "wss://silverpoker.redheartco.shop/game") {
        self.serverUrl = url
        super.init()
        print("初始化 WebSocket，服务器地址：\(url)")
        connect()
    }
    
    private func connect() {
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        guard let url = URL(string: serverUrl) else {
            print("❌ 无效的服务器 URL：\(serverUrl)")
            connectionStateSubject.send(false)
            return
        }
        print("正在连接到服务器：\(url)")
        webSocket = session.webSocketTask(with: url)
        webSocket?.resume()
        receiveMessage()
    }
    
    func send(_ message: [String: Any]) {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: message),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            print("❌ 消息序列化失败")
            return
        }
        
        print("发送消息：\(jsonString)")
        let message = URLSessionWebSocketTask.Message.string(jsonString)
        webSocket?.send(message) { error in
            if let error = error {
                print("❌ WebSocket 发送错误：\(error)")
            } else {
                print("✅ 消息发送成功")
            }
        }
    }
    
    private func receiveMessage() {
        webSocket?.receive { [weak self] result in
            switch result {
            case .success(let message):
                print("收到消息：\(message)")
                switch message {
                case .string(let text):
                    if let data = text.data(using: .utf8),
                       let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        print("✅ 解析消息成功：\(json)")
                        self?.messageSubject.send(json)
                    } else {
                        print("❌ 消息解析失败：\(text)")
                    }
                case .data(let data):
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        print("✅ 解析二进制消息成功：\(json)")
                        self?.messageSubject.send(json)
                    } else {
                        print("❌ 二进制消息解析失败")
                    }
                @unknown default:
                    print("❌ 未知的消息类型")
                    break
                }
                self?.receiveMessage()
                
            case .failure(let error):
                print("❌ WebSocket 接收错误：\(error)")
                print("🔄 5秒后尝试重新连接...")
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    self?.connect()
                }
            }
        }
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("✅ WebSocket 连接成功")
        connectionStateSubject.send(true)
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("❌ WebSocket 连接断开，关闭代码：\(closeCode)")
        connectionStateSubject.send(false)
        if let reason = reason,
           let reasonString = String(data: reason, encoding: .utf8) {
            print("断开原因：\(reasonString)")
        }
    }
    
    deinit {
        print("WebSocket 服务销毁")
        webSocket?.cancel()
    }
} 