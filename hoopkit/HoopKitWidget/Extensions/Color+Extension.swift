import SwiftUI

extension Color {
    static let themeColor = Color(red: 0, green: 0.3, blue: 0)  // 深森林绿
    static let darkThemeColor = Color(red: 0, green: 0.2, blue: 0)  // 深绿色
    static let lightThemeColor = Color(red: 0, green: 0.6, blue: 0)  // 浅绿色
    
    // 根据强度返回不同透明度的主题色
    static func getColorForIntensity(_ intensity: Int) -> Color {
        let opacity: Double
        switch intensity {
        case 1:
            opacity = 0.2  // 最浅
        case 2:
            opacity = 0.3
        case 3:
            opacity = 0.4
        case 4:
            opacity = 0.5
        case 5:
            opacity = 0.6  // 最深
        default:
            opacity = 0.4  // 默认中等强度
        }
        return lightThemeColor.opacity(opacity)
    }
} 