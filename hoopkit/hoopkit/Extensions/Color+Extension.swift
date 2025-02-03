import SwiftUI

// 定义全局主题色
extension Color {
    static let themeColor = Color(red: 0, green: 0.3, blue: 0)  // 使用深森林绿
    static let darkThemeColor = Color(red: 0, green: 0.2, blue: 0)  // 深绿色
    static let aColor = Color(red: 0.0, green: 0.0, blue: 0.0)  // 使用更亮的绿色

    // 添加强度等级对应的颜色映射
    static func getColorForIntensity(_ intensity: Int) -> Color {
        switch intensity {
        case 1:
            return Color(red: 0.62, green: 0.80, blue: 0.63)  // 最浅的绿色
        case 2:
            return Color(red: 0.0, green: 0.60, blue: 0.0)
        case 3:
            return Color(red: 0.0, green: 0.50, blue: 0.0)
        case 4:
            return Color(red: 0.0, green: 0.35, blue: 0.0)
        case 5:
            return Color(red: 0.0, green: 0.25, blue: 0.0)  // 最深的绿色
        default:
            return Color(red: 0.0, green: 0.50, blue: 0.0)  // 默认颜色
        }
    }
}