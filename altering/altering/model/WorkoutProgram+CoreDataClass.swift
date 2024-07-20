import Foundation
import CoreData

@objc(WorkoutProgram)
public class WorkoutProgram: NSManagedObject {
    
    func workoutsForPlan(_ plan: WorkoutPlan) -> [Workout]? {
        if let workouts = self.workouts?.allObjects as? [Workout] {
            return workouts.filter { w in
                w.exercise == plan.exercise
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
            for workout in workouts {
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
