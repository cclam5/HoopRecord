import SwiftUI

// 定义全局主题色
extension Color {
    static let themeColor = Color(red: 0, green: 0.3, blue: 0)  // 使用深森林绿
    static let darkThemeColor = Color(red: 0, green: 0.2, blue: 0)  // 深绿色
    static let aColor = Color(red: 0, green: 0.2, blue: 0)  // 使用深森林绿

    // 添加强度等级对应的透明度映射
    static let intensityOpacities: [Int: Double] = [
        1: 0.65,  // 很轻松
        2: 0.75, // 轻松
        3: 0.85,  // 适中
        4: 0.93, // 疲劳
        5: 1   // 非常疲劳
    ]

    // 添加获取透明度的静态方法
    static func getOpacityForIntensity(_ intensity: Int) -> Double {
        return intensityOpacities[intensity] ?? 0.3
    }
}