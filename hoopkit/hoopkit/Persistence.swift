//
//  Persistence.swift
//  hoopkit
//
//  Created by CC . on 2024/12/30.
//

import CoreData
import WidgetKit

struct PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "hoopkit")
        
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        } else {
            // 获取默认存储位置
            let defaultStoreURL = NSPersistentContainer
                .defaultDirectoryURL()
                .appendingPathComponent("hoopkit.sqlite")
            
            // 获取共享存储位置
            if let sharedStoreURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.cc.hoopkit")?.appendingPathComponent("hoopkit.sqlite") {
                
                // 如果共享存储不存在，但默认存储存在，则进行迁移
                if !FileManager.default.fileExists(atPath: sharedStoreURL.path) && FileManager.default.fileExists(atPath: defaultStoreURL.path) {
                    do {
                        try FileManager.default.copyItem(at: defaultStoreURL, to: sharedStoreURL)
                        // 复制相关文件
                        try FileManager.default.copyItem(at: defaultStoreURL.appendingPathExtension("shm"), to: sharedStoreURL.appendingPathExtension("shm"))
                        try FileManager.default.copyItem(at: defaultStoreURL.appendingPathExtension("wal"), to: sharedStoreURL.appendingPathExtension("wal"))
                    } catch {
                        print("Migration failed: \(error)")
                    }
                }
                
                let storeDescription = NSPersistentStoreDescription(url: sharedStoreURL)
                container.persistentStoreDescriptions = [storeDescription]
            }
        }
        
        container.loadPersistentStores { description, error in
            if let error = error {
                print("Core Data failed to load: \(error.localizedDescription)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        
        // 添加保存后的通知观察者
        NotificationCenter.default.addObserver(forName: .NSManagedObjectContextDidSave, object: container.viewContext, queue: nil) { _ in
            // 触发 Widget 更新
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    
    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // 添加示例数据
        let record = BasketballRecord.create(
            in: viewContext,
            gameType: "5v5",
            duration: 90,
            intensity: 4,
            fatigue: 3,
            notes: "今天打得不错，投篮手感很好"
        )
        
        let tag = BasketballTag.create(in: viewContext, name: "投篮")
        record.addToTags(tag)
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError)")
        }
        
        return result
    }()
}
