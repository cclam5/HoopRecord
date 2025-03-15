//
//  hoopkitApp.swift
//  hoopkit
//
//  Created by CC . on 2024/12/30.
//

import SwiftUI
import CoreData

@main
struct HoopKitApp: App {
    @StateObject private var themeManager = ThemeManager.shared
    let persistenceController = PersistenceController.shared

    init() {
        createInitialRecord()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(themeManager)
                .preferredColorScheme(themeManager.currentTheme.colorScheme)
        }
    }

    // 在应用启动时创建一条初始记录
    private func createInitialRecord() {
        let defaults = UserDefaults.standard
        let hasCreatedInitialRecordKey = "hasCreatedInitialRecord"

        // 检查是否已经创建过初始记录
        if defaults.bool(forKey: hasCreatedInitialRecordKey) {
            return
        }

        let context = PersistenceController.shared.container.viewContext
        let initialRecord = BasketballRecord(context: context)
        initialRecord.gameType = "新人指南"
        initialRecord.duration = 60 // 1小时
        initialRecord.intensity = 1 // 1级
        initialRecord.notes = """
        欢迎使用 HoopMemo！🏀 这是一款为篮球爱好者量身打造的应用，助您轻松记录篮球生活。

        主要功能
        比赛记录 📋：记录每场比赛的类型、时长、强度和体会。
        添加标签 🏷️：为比赛添加个性化标签，便于分类和回顾。
        生成分享图 📸：生成精美分享图，与朋友分享您的篮球成就。
        周/月数据统计 📊：提供详细的周/月数据统计，帮助您了解进步。
        Widget 插件 📱：在主屏幕快速查看最新比赛记录和统计数据。

        鼓励写下您的想法 ✍️
        篮球不仅是一项运动，更是一种生活方式。记录下您的想法和感受，珍藏每一个精彩瞬间。HoopMemo 将陪伴您每一步，享受篮球的乐趣！🎉
        如有问题或建议，欢迎随时联系我们。祝您玩得开心！😊
        """
        let guideTag = BasketballTag(context: context)
        guideTag.name = "新人指南"
        initialRecord.addToTags(guideTag)
        do {
            try context.save()
            // 设置标志，表示已经创建过初始记录
            defaults.set(true, forKey: hasCreatedInitialRecordKey)
        } catch {
            print("Failed to save initial guide record: \(error)")
        }
    }
}
