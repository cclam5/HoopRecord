//
//  Persistence.swift
//  hoopkit
//
//  Created by CC . on 2024/12/30.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "hoopkit")
        
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Error: \(error.localizedDescription)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
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
