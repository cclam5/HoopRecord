import SwiftUI

// 定义全局主题色
extension Color {
    static let themeColor = Color(red: 0, green: 0.3, blue: 0)  // 使用深森林绿
    static let darkThemeColor = Color(red: 0, green: 0.2, blue: 0)  // 深绿色
    static let aColor = Color(red: 0.0, green: 0.0, blue: 0.0)  // 使用更亮的绿色
    
    // 添加一个在深色模式下更亮的蓝色
    static let customBlue = Color(red: 0.4, green: 0.6, blue: 1.0)  // 更亮的蓝色
    
    // 添加 checkmark 图标的颜色
    static let checkmarkColor = Color(red: 0.4, green: 0.8, blue: 0.4)  // 更浅的绿色
    
    // 添加强度选择器的颜色
    static let intensityColor = Color(red: 0.0, green: 0.35, blue: 0.0)  // 使用原来的绿色

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