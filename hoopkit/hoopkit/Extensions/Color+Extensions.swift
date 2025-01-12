import SwiftUI

extension Color {
    // 添加强度等级对应的透明度映射
    static let intensityOpacities: [Int: Double] = [
        1: 0.3,  // 很轻松
        2: 0.45, // 轻松
        3: 0.6,  // 适中
        4: 0.75, // 疲劳
        5: 0.9   // 非常疲劳
    ]
    
    // 添加获取透明度的静态方法
    static func getOpacityForIntensity(_ intensity: Int) -> Double {
        return intensityOpacities[intensity] ?? 0.3
    }
} 