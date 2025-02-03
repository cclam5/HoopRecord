import SwiftUI

extension Color {
    // 背景色
    static var customBackground: Color {
        Color("backgroundColor")
    }
    
    // 主要文本颜色
    static var customPrimaryText: Color {
        Color("primaryText")
    }
    
    // 次要文本颜色
    static var customSecondaryText: Color {
        Color("secondaryText")
    }
    
    // 分割线颜色
    static var customDivider: Color {
        Color("dividerColor")  // 改名避免与系统 separator 冲突
    }
    
    // 卡片背景色
    static var customCardBackground: Color {
        Color("cardBackground")
    }
    
    // 主题色（品牌色）
    static var customBrandPrimary: Color {
        Color("brandPrimary")
    }
    
    // 次要主题色
    static var customBrandSecondary: Color {
        Color("brandSecondary")
    }
    
    // 列表背景色
    static var customListBackground: Color {
        Color("listBackground")
    }
    
    // 导航栏背景色
    static var customNavigationBackground: Color {
        Color("navigationBackground")
    }
    
    // 标签文字颜色
    static var customTagText: Color {
        Color("tagText")
    }
    
    // 标签背景色
    static var customTagBackground: Color {
        Color("tagBackground")
    }
} 
