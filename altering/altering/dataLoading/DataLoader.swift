import Foundation
import UIKit
import CoreData

class DataLoader {
    
    static let shared = DataLoader()
    
    private init() {}
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    // MARK: Exercises
    
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
    
    // MARK: Workouts
    
    func loadAllWorkouts(completion: @escaping ([Workout]?) -> Void) {
        DispatchQueue.global().async {
            let fetchRequest = Workout.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
            
            do {
                let fetchResults = try self.context.fetch(fetchRequest)
                return completion(fetchResults)
            } catch {
                print("Error Fetching All Workouts")
                return completion(nil)
            }
        }
    }
    
    func loadWorkoutsFor(_ exercise: Exercise, completion: @escaping ([Workout]?) -> Void) {
        DispatchQueue.global().async {
            let fetchRequest = Workout.fetchRequest()
            let exercisePredicate = NSPredicate(format: "exercise == %@", exercise)
            fetchRequest.predicate = exercisePredicate
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
            
            do {
                let fetchResults = try self.context.fetch(fetchRequest)
                return completion(fetchResults)
            } catch {
                print("Error Fetching Exercise Workouts")
                return completion(nil)
            }
        }
    }
    
    func loadPreviousWorkout(_ exercise: Exercise, date: Date, completion: @escaping (Workout?) -> Void) {
        DispatchQueue.global().async {
            let fetchRequest = Workout.fetchRequest()
            let exercisePredicate = NSPredicate(format: "exercise == %@", exercise)
            let datePredicate = NSPredicate(format: "date < %@", date as NSDate)
            let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [exercisePredicate, datePredicate])
            fetchRequest.predicate = compoundPredicate
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
            
            do {
                let workouts = try self.context.fetch(fetchRequest)
                return completion(workouts.first)
            } catch {
                print("Error: Could not fetch previous workout")
                return completion(nil)
            }
        }
    }
    
    func createNewWorkout() -> Workout {
        return Workout(context: context)
    }
    
    func deleteWorkout(_ workout: Workout) {
        self.context.delete(workout)
    }
    
    // MARK: Groups
    
    func loadAllGroups(completion: @escaping ([ExerciseGroup]?) -> Void) {
        DispatchQueue.global().async {
            let fetchRequest = ExerciseGroup.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: false)]
            
            do {
                let fetchResults = try self.context.fetch(fetchRequest)
                return completion(fetchResults)
            } catch {
                print("Error Fetching All Group")
                return completion(nil)
            }
        }
    }
    
    func createNewGroup() -> ExerciseGroup {
        return ExerciseGroup(context: context)
    }
    
    // MARK: Saving
    
    func saveContext() {
        DispatchQueue.global().async {
            do {
                try self.context.save()
            } catch {
                print("Error saving context")
            }
        }
    }
}

