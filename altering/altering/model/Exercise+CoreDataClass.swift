import Foundation
import CoreData

@objc(Exercise)
public class Exercise: NSManagedObject {
    
    func toCSVString() -> String {
        
        let exerciseName = "\"\(self.name ?? "none")\""
        let exerciseGroup = "\"\(self.group?.name ?? "none")\""
        
        return [exerciseName, exerciseGroup].joined(separator: ",")
    }
}
