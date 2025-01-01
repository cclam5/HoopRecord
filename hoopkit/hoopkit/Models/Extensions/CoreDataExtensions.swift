import Foundation
import CoreData

// MARK: - BasketballRecord Extensions
extension BasketballRecord {
    // 便利属性
    var wrappedId: UUID {
        get { id ?? UUID() }
        set { id = newValue }
    }
    
    var wrappedDate: Date {
        get { date ?? Date() }
        set { date = newValue }
    }
    
    var wrappedGameType: String {
        get { gameType ?? "" }
        set { gameType = newValue }
    }
    
    var wrappedNotes: String {
        get { notes ?? "" }
        set { notes = newValue }
    }
    
    var tagArray: [BasketballTag] {
        let set = tags as? Set<BasketballTag> ?? []
        return Array(set).sorted { $0.wrappedName < $1.wrappedName }
    }
}

// MARK: - BasketballTag Extensions
extension BasketballTag {
    // 便利属性
    var wrappedId: UUID {
        get { id ?? UUID() }
        set { id = newValue }
    }
    
    var wrappedName: String {
        get { name ?? "" }
        set { name = newValue }
    }
    
    var recordArray: [BasketballRecord] {
        let set = records as? Set<BasketballRecord> ?? []
        return Array(set).sorted { $0.wrappedDate > $1.wrappedDate }
    }
}

// MARK: - Convenience Methods
extension BasketballRecord {
    static func create(in context: NSManagedObjectContext,
                      gameType: String,
                      duration: Int16,
                      intensity: Int16,
                      fatigue: Int16,
                      notes: String) -> BasketballRecord {
        let record = BasketballRecord(context: context)
        record.id = UUID()
        record.date = Date()
        record.gameType = gameType
        record.duration = duration
        record.intensity = intensity
        record.fatigue = fatigue
        record.notes = notes
        return record
    }
}

extension BasketballTag {
    static func create(in context: NSManagedObjectContext, name: String) -> BasketballTag {
        let tag = BasketballTag(context: context)
        tag.id = UUID()
        tag.name = name
        return tag
    }
} 
