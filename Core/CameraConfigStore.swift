import Foundation
import SwiftUI
import Combine

// 对应 TS 中的数据结构
struct Vec3: Codable, Equatable {
    var x: Double
    var y: Double
    var z: Double
}

struct CameraSetting: Codable, Equatable {
    var position: Vec3
    var target: Vec3
    var fov: Double
}

struct CameraConfig: Codable, Equatable {
    var head: CameraSetting
    var body: CameraSetting
    var lerpSpeed: Double
    
    // 默认配置 (你可以根据之前的 camera.json 填入)
    static let defaultValue = CameraConfig(
        head: CameraSetting(
            position: Vec3(x: 0, y: 1.4, z: 0.6),
            target: Vec3(x: 0, y: 1.4, z: 0),
            fov: 40
        ),
        body: CameraSetting(
            position: Vec3(x: 0, y: 1.25, z: 1.3),
            target: Vec3(x: 0, y: 1.15, z: 0),
            fov: 35
        ),
        lerpSpeed: 0.05
    )
}

class CameraConfigStore: ObservableObject {
    static let shared = CameraConfigStore()
    
    @Published var config: CameraConfig {
        didSet {
            save()
            sendToWeb()
        }
    }
    
    private let key = "CameraConfigV1"
    
    init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode(CameraConfig.self, from: data) {
            self.config = decoded
        } else {
            self.config = CameraConfig.defaultValue
        }
    }
    
    func save() {
        if let encoded = try? JSONEncoder().encode(config) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }
    
    func sendToWeb() {
        // 任何变动都发送给前端
        SharedWebViewHelper.shared.updateCameraConfig(config)
    }
    
    // 恢复默认
    func reset() {
        config = CameraConfig.defaultValue
    }
}
