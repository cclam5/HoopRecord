import Foundation
import CoreData

public class Tag: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID
    @NSManaged public var name: String?
    @NSManaged public var records: NSSet?
    
    public var wrappedName: String {
        name ?? "未命名标签"
    }
} 