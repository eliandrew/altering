import Foundation
import UIKit
import CoreData

class DataLoader {
    
    static let shared = DataLoader()
    
    private init() {}
    
    var persistentContainer = (UIApplication.shared.delegate as! AppDelegate).persistentContainer
    
    private var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    // MARK: - Core Data File Management
        
    func exportCoreData(to destinationURL: URL, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let storeURL = persistentContainer.persistentStoreCoordinator.persistentStores.first?.url else {
            completion(.failure(NSError(domain: "DataLoader", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unable to locate Core Data store"])))
            return
        }
        
        do {
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }
            try fileManager.copyItem(at: storeURL, to: destinationURL)
            completion(.success(()))
        } catch {
            completion(.failure(error))
        }
    }

    func importCoreData(from sourceURL: URL, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let storeURL = persistentContainer.persistentStoreCoordinator.persistentStores.first?.url else {
            completion(.failure(NSError(domain: "DataLoader", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unable to locate Core Data store"])))
            return
        }
        
        do {
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: storeURL.path) {
                try persistentContainer.persistentStoreCoordinator.destroyPersistentStore(at: storeURL, ofType: NSSQLiteStoreType, options: nil)
                try fileManager.removeItem(at: storeURL)
            }
            try fileManager.copyItem(at: sourceURL, to: storeURL)
            persistentContainer = NSPersistentContainer(name: persistentContainer.name)
            persistentContainer.loadPersistentStores { _, error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        } catch {
            completion(.failure(error))
        }
    }

    // MARK: Exercises
    
    func loadAllExercises(completion: @escaping (Result<[Exercise], Error>) -> Void) {
        DispatchQueue.global().async {
            let fetchRequest: NSFetchRequest<Exercise> = Exercise.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
            
            do {
                let fetchResults = try self.viewContext.fetch(fetchRequest)
                DispatchQueue.main.async {
                    completion(.success(fetchResults))
                }
            } catch {
                print("Error Fetching All Exercises: \(error)")
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    func createNewExercise() -> Exercise {
        return Exercise(context: viewContext)
    }
    
    func deleteExercise(_ exercise: Exercise) {
        viewContext.delete(exercise)
    }
    
    // MARK: Workouts
    
    func loadAllWorkouts(completion: @escaping (Result<[Workout], Error>) -> Void) {
        DispatchQueue.global().async {
            let fetchRequest: NSFetchRequest<Workout> = Workout.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
            
            do {
                let fetchResults = try self.viewContext.fetch(fetchRequest)
                DispatchQueue.main.async {
                    completion(.success(fetchResults))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
        
    func loadWorkouts(for exercise: Exercise, completion: @escaping (Result<[Workout], Error>) -> Void) {
        DispatchQueue.global().async {
            let fetchRequest: NSFetchRequest<Workout> = Workout.fetchRequest()
            let exercisePredicate = NSPredicate(format: "exercise == %@", exercise)
            fetchRequest.predicate = exercisePredicate
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
            
            do {
                let fetchResults = try self.viewContext.fetch(fetchRequest)
                DispatchQueue.main.async {
                    completion(.success(fetchResults))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
            
    func loadPreviousWorkouts(for exercise: Exercise, before date: Date, completion: @escaping (Result<[Workout], Error>) -> Void) {
        DispatchQueue.global().async {
            let fetchRequest: NSFetchRequest<Workout> = Workout.fetchRequest()
            let exercisePredicate = NSPredicate(format: "exercise == %@", exercise)
            let datePredicate = NSPredicate(format: "date < %@", date as NSDate)
            let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [exercisePredicate, datePredicate])
            fetchRequest.predicate = compoundPredicate
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
            
            do {
                let workouts = try self.viewContext.fetch(fetchRequest)
                DispatchQueue.main.async {
                    completion(.success(workouts))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
            
    func createNewWorkout() -> Workout {
        return Workout(context: viewContext)
    }
    
    func deleteWorkout(_ workout: Workout) {
        viewContext.delete(workout)
    }
            
    // MARK: - Groups
    
    func loadAllGroups(completion: @escaping (Result<[ExerciseGroup], Error>) -> Void) {
        DispatchQueue.global().async {
            let fetchRequest: NSFetchRequest<ExerciseGroup> = ExerciseGroup.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
            
            do {
                let fetchResults = try self.viewContext.fetch(fetchRequest)
                DispatchQueue.main.async {
                    completion(.success(fetchResults))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    func createNewGroup() -> ExerciseGroup {
        return ExerciseGroup(context: viewContext)
    }
    
    // MARK: - Plans
    
    func createNewWorkoutPlan() -> WorkoutPlan {
        return WorkoutPlan(context: viewContext)
    }
    
    func deleteWorkoutPlan(_ workoutPlan: WorkoutPlan) {
        viewContext.delete(workoutPlan)
    }
    
    // MARK: - Programs
    
    func loadAllWorkoutPrograms(completion: @escaping (Result<[WorkoutProgram], Error>) -> Void) {
        DispatchQueue.global().async {
            let fetchRequest: NSFetchRequest<WorkoutProgram> = WorkoutProgram.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
            
            do {
                let fetchResults = try self.viewContext.fetch(fetchRequest)
                DispatchQueue.main.async {
                    completion(.success(fetchResults))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    func reloadWorkoutProgram(_ program: WorkoutProgram, completion: @escaping (Result<WorkoutProgram?, Error>) -> Void) {
        DispatchQueue.global().async {
            let fetchRequest: NSFetchRequest<WorkoutProgram> = WorkoutProgram.fetchRequest()
            let programPredicate = NSPredicate(format: "name == %@", program.name ?? "program")
            fetchRequest.predicate = programPredicate
            
            do {
                let fetchResults = try self.viewContext.fetch(fetchRequest)
                DispatchQueue.main.async {
                    completion(.success(fetchResults.first))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    func createNewWorkoutProgram() -> WorkoutProgram {
        return WorkoutProgram(context: viewContext)
    }
    
    func deleteWorkoutProgram(_ workoutProgram: WorkoutProgram) {
        viewContext.delete(workoutProgram)
    }
    
    
    // MARK: - Saving
    
    func saveContext(completion: ((Result<Void, Error>) -> Void)? = nil) {
        DispatchQueue.global().async {
            do {
                try self.viewContext.save()
                DispatchQueue.main.async {
                    completion?(.success(()))
                }
            } catch {
                DispatchQueue.main.async {
                    completion?(.failure(error))
                }
            }
        }
    }
}

