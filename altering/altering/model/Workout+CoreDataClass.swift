import Foundation
import CoreData

@objc(Workout)
public class Workout: NSManagedObject {

    func toCSVString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let date = dateFormatter.string(from: self.date ?? Date.now as Date)
        
        let exerciseName = "\"\(self.exercise?.name ?? "none")\""
        let exerciseGroup = "\"\(self.exercise?.group?.name ?? "none")\""
        
        let notes = "\"\(self.notes ?? "none")\""
        let program = "\"\(self.program?.name ?? "none")\""
        
        return [date, exerciseName, exerciseGroup, notes, program].joined(separator: ",")
    }
    
    func programPlan() -> WorkoutPlan? {
        if let program = self.program, let plans = program.plans?.allObjects as? [WorkoutPlan] {
            return plans.filter { p in
                p.exercise == self.exercise
            }.first
        } else {
            return nil
        }
    }
    
    func progressPoints() -> [Float]? {
        guard let plan = self.programPlan() else {
            return nil
        }
        if plan.numWorkouts <= 3 {
            return [0.0, 1.0]
        } else if plan.numWorkouts < 10 {
            return [0.0, 0.5, 1.0]
        } else {
            return [0.0, 0.25, 0.5, 0.75, 1.0]
        }
    }
    
    func progress() -> Float? {
        if self.completed, let _ = self.program  {
            return self.progress(for: self.workoutsCompleted() ?? 0)
        } else {
            return nil
        }
    }
    
    func workoutsCompleted() -> Int? {
        if let workoutsCompleted = self.program?.workouts?.filter({ w in
            let w = w as! Workout
            return w.exercise == self.exercise
        }) {
            return workoutsCompleted.count
        } else {
            return nil
        }
    }
    
    func progress(for workoutsCompleted: Int) -> Float? {
        if let plan = self.programPlan() {
            let planProgress = Float(workoutsCompleted) / Float(plan.numWorkouts)
            return planProgress
        } else {
            return nil
        }
    }

    func progressPointHit() -> Float? {
        if let currentProgress = self.progress(), let workoutsCompleted = self.workoutsCompleted(), let pastProgress = self.progress(for: workoutsCompleted - 1), let progressPoints = self.progressPoints() {
            if workoutsCompleted == 1 {
                return 0.0
            } else {
                return progressPoints.first { p in
                    currentProgress >= p && pastProgress < p
                }
            }
        } else {
            return nil
        }
    }
}
