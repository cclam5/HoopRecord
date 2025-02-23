import Foundation
import CoreData

class PreviewData {
    static let shared = PreviewData()
    
    var sampleRecords: [BasketballRecord] {
        // 创建一个临时的 Core Data 容器
        let container = NSPersistentContainer(name: "hoopkit")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]
        
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Failed to load preview store: \(error)")
            }
        }
        
        let context = container.viewContext
        
        // 创建示例数据
        var records: [BasketballRecord] = []
        let calendar = Calendar.current
        let today = Date()
        
        // 在本月随机添加5条记录
        let startOfMonth = calendar.startOfMonth(for: today)
        for i in 0..<5 {
            let record = BasketballRecord(context: context)
            record.id = UUID()
            record.date = calendar.date(byAdding: .day, value: i * 3, to: startOfMonth)!
            record.duration = Int16.random(in: 60...120)
            record.intensity = Int16.random(in: 5...9)
            record.location = "室内篮球场"
            record.notes = "示例记录\(i + 1)"
            records.append(record)
        }
        
        // 添加今天的记录
        let todayRecord = BasketballRecord(context: context)
        todayRecord.id = UUID()
        todayRecord.date = today
        todayRecord.duration = 90
        todayRecord.intensity = 7
        todayRecord.location = "室外篮球场"
        todayRecord.notes = "今天的记录"
        records.append(todayRecord)
        
        return records
    }
} 