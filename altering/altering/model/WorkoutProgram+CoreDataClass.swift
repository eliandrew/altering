import Foundation
import CoreData

@objc(WorkoutProgram)
public class WorkoutProgram: NSManagedObject {
    
    func toCSVString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let startDate = self.start != nil ? dateFormatter.string(from: self.start ?? Date.now as Date) : "none"
        let endDate = self.end != nil ? dateFormatter.string(from: self.end ?? Date.now as Date) : "none"
        
        let programName = "\"\(self.name ?? "none")\""
        
       return ""
    }
    
    func workoutsForPlan(_ plan: WorkoutPlan) -> [Workout]? {
        if let workouts = self.workouts?.allObjects as? [Workout] {
            return workouts.filter { w in
                w.exercise == plan.exercise && w.completed
            }.sorted { w1, w2 in
                if let w1Date = w1.date, let w2Date = w2.date {
                    return w1Date > w2Date
                } else {
                    return w1.exercise?.name ?? "a" > w2.exercise?.name ?? "b"
                }
            }
        } else {
            return nil
        }
    }
    
    func isComplete() -> Bool? {
        if let workouts = self.workouts?.allObjects as? [Workout], let plans = self.plans?.allObjects as? [WorkoutPlan] {
            var workoutCountForExercises: [Exercise : Int] = [:]
            let completedWorkouts = workouts.filter { w in
                w.completed
            }
            for workout in completedWorkouts {
                if let exercise = workout.exercise {
                    if workoutCountForExercises[exercise] == nil {
                        workoutCountForExercises[exercise] = 0
                    }
                    workoutCountForExercises[exercise]? += 1
                }
            }
            return plans.allSatisfy { p in
                if let exercise = p.exercise {
                    return workoutCountForExercises[exercise] ?? 0 == p.numWorkouts
                } else {
                    return false
                }
            }
        } else {
            return nil
        }
    }
}
