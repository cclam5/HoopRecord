import Foundation
import CoreData

@objc(BasketballRecord)
public class BasketballRecord: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID
    @NSManaged public var date: Date
    @NSManaged public var duration: Int16
    @NSManaged public var intensity: Int16
    @NSManaged public var location: String?
    @NSManaged public var notes: String?
    
    public var wrappedDate: Date {
        date
    }
}

extension BasketballRecord {
    static func fetchRequest() -> NSFetchRequest<BasketballRecord> {
        NSFetchRequest<BasketballRecord>(entityName: "BasketballRecord")
    }
} 