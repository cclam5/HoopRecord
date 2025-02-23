import CoreData

class CoreDataManager {
    static let shared = CoreDataManager()
    
    let container: NSPersistentContainer
    
    private init() {
        container = NSPersistentContainer(name: "hoopkit")
        
        // 配置共享存储
        if let storeURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.cc.hoopkit")?.appendingPathComponent("hoopkit.sqlite") {
            let storeDescription = NSPersistentStoreDescription(url: storeURL)
            container.persistentStoreDescriptions = [storeDescription]
        }
        
        container.loadPersistentStores { description, error in
            if let error = error {
                print("Core Data failed to load: \(error.localizedDescription)")
            }
        }
    }
    
    func fetchRecordsForCurrentMonth() -> [BasketballRecord] {
        let context = container.viewContext
        let fetchRequest: NSFetchRequest<BasketballRecord> = BasketballRecord.fetchRequest()
        
        // 获取当前月份的起始和结束日期
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.startOfMonth(for: now)
        let endOfMonth = calendar.endOfMonth(for: now)
        
        // 设置查询条件
        fetchRequest.predicate = NSPredicate(format: "date >= %@ AND date <= %@", startOfMonth as NSDate, endOfMonth as NSDate)
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \BasketballRecord.date, ascending: true)]
        
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("Failed to fetch records: \(error.localizedDescription)")
            return []
        }
    }
} 