import CoreData

class PreviewData {
    static let shared = PreviewData()
    
    let container: NSPersistentContainer
    let context: NSManagedObjectContext
    var sampleRecords: [BasketballRecord] = []
    
    init() {
        container = NSPersistentContainer(name: "BallTrack")
        container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Error: \(error.localizedDescription)")
            }
        }
        
        context = container.viewContext
        createSampleData()
    }
    
    func createSampleData() {
        // 创建示例记录
        let dates = [
            Calendar.current.date(byAdding: .day, value: -5, to: Date())!,
            Calendar.current.date(byAdding: .day, value: -3, to: Date())!,
            Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
            Date()
        ]
        
        let gameTypes = ["5v5", "3v3", "单练", "街球"]
        let notes = [
            "今天手感不错，三分球命中率很高",
            "配合默契，防守到位",
            "主要练习投篮和运球",
            "和朋友打得很开心"
        ]
        
        for i in 0..<4 {
            let record = BasketballRecord(context: context)
            record.id = UUID()
            record.date = dates[i]
            record.gameType = gameTypes[i]
            record.duration = Int16(60 + i * 15)
            record.intensity = Int16(3 + i % 3)
            record.fatigue = Int16(2 + i % 4)
            record.notes = notes[i]
            
            // 添加标签
            let tag1 = BasketballTag(context: context)
            tag1.id = UUID()
            tag1.name = "投篮"
            
            let tag2 = BasketballTag(context: context)
            tag2.id = UUID()
            tag2.name = "配合"
            
            record.addToTags([tag1, tag2])
            
            sampleRecords.append(record)
        }
        
        try? context.save()
    }
} 
