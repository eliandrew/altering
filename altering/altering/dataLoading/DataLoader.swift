import Foundation
import UIKit
import CoreData

class DataLoader {
    
    static let shared = DataLoader()
    
    private init() {}
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    func loadAllExercises(completion: @escaping ([Exercise]?) -> Void) {
        DispatchQueue.global().async {
            let fetchRequest = Exercise.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
            
            do {
                let fetchResults = try self.context.fetch(fetchRequest)
                return completion(fetchResults)
            } catch {
                print("Error Fetching All Exercises")
                return completion(nil)
            }
        }
    }
    
    func createNewExercise() -> Exercise {
        return Exercise(context: context)
    }
    
    func deleteExercise(_ exercise: Exercise) {
        self.context.delete(exercise)
    }
    
    func saveContext() -> Bool {
        do {
            try context.save()
            return true
        } catch {
            print("Error saving context")
            return false
        }
    }
}

