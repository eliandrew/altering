import Foundation
import UIKit

class WorkoutTableViewDataSource {
    
    let WORKOUT_CELL_IDENTIFIER = "workoutCell"
    var workoutsByDate: [String : [Workout]] = [:]
    var workoutDateKeys = [String]()
    
    // MARK: Helpers
    
    func removeWorkout(at indexPath: IndexPath) {
        self.workoutsByDate[self.workoutDateKeys[indexPath.section]]?.remove(at: indexPath.row)
    }
    
    func setWorkouts(_ workouts: [Workout]) {
        var newWorkoutDateKeys = [Date]()
        var newWorkoutsByDateKey: [String : [Workout]] = [:]
        for workout in workouts {
            if let date = workout.date, let dateKey = self.dateTitleFrom(date) {
                if newWorkoutsByDateKey[dateKey] == nil {
                    newWorkoutsByDateKey[dateKey] = []
                    newWorkoutDateKeys.append(date)
                }
                newWorkoutsByDateKey[dateKey]?.append(workout)
            }
        }
        self.workoutDateKeys = newWorkoutDateKeys.sorted { $0 > $1 }.map({ date in
            self.dateTitleFrom(date) ?? "No Date"
        })
        self.workoutsByDate = newWorkoutsByDateKey
    }
    
    func workoutsForSection(_ section: Int) -> [Workout]? {
        if section < self.workoutDateKeys.count {
            let dateKey = self.workoutDateKeys[section]
            return self.workoutsByDate[dateKey]
        } else {
            return nil
        }
    }
    
    func workoutForIndexPath(_ indexPath: IndexPath) -> Workout? {
        if let workouts = self.workoutsForSection(indexPath.section) {
            if indexPath.row < workouts.count {
                return workouts[indexPath.row]
            } else {
                return nil
            }
        }
        return nil
    }
    
    func numberOfSections(_ tableView: UITableView) -> Int {
        return self.workoutDateKeys.count
    }
    
    func numberOfRowsInSection(_ tableView: UITableView, section: Int) -> Int {
        return self.workoutsForSection(section)?.count ?? 0
    }
    
    func cellForRowAtIndexPath(_ tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: WORKOUT_CELL_IDENTIFIER, for: indexPath)
        
        guard let workout = workoutForIndexPath(indexPath) else {
            return cell
        }
        
        var content = UIListContentConfiguration.cell()
        content.text = workout.exercise?.name ?? "Missing Name"
        content.textProperties.font = UIFont.systemFont(ofSize: 20)
        content.secondaryText = workout.exercise?.group?.name ?? "None"
        content.secondaryTextProperties.font = UIFont.systemFont(ofSize: 15)
        cell.contentConfiguration = content
        
        return cell
    }
    
    func titleForSection(_ section: Int) -> String? {
        if section < self.workoutDateKeys.count {
            return self.workoutDateKeys[section]
        } else {
            return nil
        }
    }
    
    func dateTitleFrom(_ date: Date?) -> String? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE MM/dd/yyyy"
        
        if let date = date {
            return dateFormatter.string(from: date)
        } else {
            return nil
        }
    }
}
