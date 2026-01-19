import Foundation
import Network

class LocalServer {
    static let shared = LocalServer()
    private var listener: NWListener?
    private let port: NWEndpoint.Port = 11451 // 监听端口

    // 回调闭包：当收到有效 JSON 时通知 ViewModel
    var onMessageReceived: ((APIRequest) -> Void)?

    func start() {
        do {
            let params = NWParameters.tcp
            let listener = try NWListener(using: params, on: port)

            listener.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    print("🚀 Local Server listening on port \(self.port)")
                case let .failed(error):
                    print("❌ Server failed: \(error)")
                default:
                    break
                }
            }

            listener.newConnectionHandler = { [weak self] connection in
                self?.handleConnection(connection)
            }

            listener.start(queue: .global(qos: .userInitiated))
            self.listener = listener

        } catch {
            print("❌ Failed to create listener: \(error)")
        }
    }

    private func handleConnection(_ connection: NWConnection) {
        connection.start(queue: .global())

        // 简单读取：假设 JSON 数据不会超过 64KB 且一次性到达
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] content, _, _, _ in
            if let data = content, !data.isEmpty {
                self?.processData(data)

                // 返回 200 OK
                let response = "HTTP/1.1 200 OK\r\nContent-Length: 2\r\n\r\nok"
                connection.send(content: response.data(using: .utf8), completion: .contentProcessed { _ in
                    connection.cancel()
                })
            } else {
                connection.cancel()
            }
        }
    }

    private func processData(_ data: Data) {
        // 1. 简易 HTTP 解析：找到 Body
        // [修复] 修正了参数标签 qh -> encoding
        guard let dataStr = String(data: data, encoding: .utf8) else { return }

        let components = dataStr.components(separatedBy: "\r\n\r\n")
        var jsonString = ""

        if components.count > 1 {
            // 取 header 之后的部分作为 body
            jsonString = components.dropFirst().joined(separator: "\r\n\r\n")
        } else {
            // 也许没有 header，直接尝试解析
            jsonString = dataStr
        }

        // [修复] 函数名现在可以正确调用了
        guard let jsonData = QHJsonString(jsonString) else { return }

        // 2. 解码 JSON
        do {
            let request = try JSONDecoder().decode(APIRequest.self, from: jsonData)
            // [修复] 添加 [weak self] 以允许使用 self?
            DispatchQueue.main.async { [weak self] in
                self?.onMessageReceived?(request)
            }
        } catch {
            print("⚠️ JSON Decode Error: \(error)")
            // print("Received raw: \(jsonString)")
        }
    }

    // 辅助：处理可能的 Curl 格式问题
    // [修复] 补充了 func 关键字后的空格
    private func QHJsonString(_ str: String) -> Data? {
        return str.trimmingCharacters(in: .whitespacesAndNewlines).data(using: .utf8)
    }
}
