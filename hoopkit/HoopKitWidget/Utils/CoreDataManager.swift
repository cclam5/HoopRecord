import CoreData
import os

class CoreDataManager {
    static let shared = CoreDataManager()
    private let logger = Logger(subsystem: "com.cc.hoopkit.widget", category: "CoreData")
    
    let container: NSPersistentContainer
    
    private init() {
        logger.debug("Initializing CoreDataManager")
        container = NSPersistentContainer(name: "hoopkit")
        
        // 配置共享存储
        if let storeURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.cc.hoopkit")?.appendingPathComponent("hoopkit.sqlite") {
            logger.debug("CoreData store URL: \(storeURL.path)")
            let storeDescription = NSPersistentStoreDescription(url: storeURL)
            container.persistentStoreDescriptions = [storeDescription]
        } else {
            logger.error("❌ Failed to get App Group container URL")
        }
        
        container.loadPersistentStores { description, error in
            if let error = error {
                self.logger.error("❌ Core Data failed to load: \(error.localizedDescription)")
            } else {
                self.logger.debug("✅ Core Data loaded successfully: \(description.url?.path ?? "unknown path")")
            }
        }
    }
    
    func fetchRecordsForCurrentMonth() -> [BasketballRecord] {
        logger.debug("Starting fetchRecordsForCurrentMonth")
        let context = container.viewContext
        let fetchRequest: NSFetchRequest<BasketballRecord> = BasketballRecord.fetchRequest()
        
        // 获取当前月份的起始和结束日期
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.startOfMonth(for: now)
        let endOfMonth = calendar.endOfMonth(for: now)
        
        logger.debug("Fetching records from \(startOfMonth) to \(endOfMonth)")
        
        // 设置查询条件
        fetchRequest.predicate = NSPredicate(format: "date >= %@ AND date <= %@", startOfMonth as NSDate, endOfMonth as NSDate)
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \BasketballRecord.date, ascending: true)]
        
        do {
            let records = try context.fetch(fetchRequest)
            logger.debug("✅ Found \(records.count) records for current month")
            for record in records {
                logger.debug("Record: date=\(record.date), duration=\(record.duration)")
            }
            return records
        } catch {
            logger.error("❌ Failed to fetch records: \(error.localizedDescription)")
            return []
        }
    }
} 