import Foundation
import UIKit
import CoreData

class DataLoader {
    
    static let shared = DataLoader()
    
    private init() {}
    
    let persistentContainer = (UIApplication.shared.delegate as! AppDelegate).persistentContainer
    
    private var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
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
            
    func loadPreviousWorkout(for exercise: Exercise, before date: Date, completion: @escaping (Result<Workout?, Error>) -> Void) {
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
                    completion(.success(workouts.first))
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

