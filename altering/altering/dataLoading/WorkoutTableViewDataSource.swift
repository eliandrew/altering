import Foundation
import UIKit

struct WorkoutSection {
    var isExpanded: Bool
    var workouts: [Workout]
}

class WorkoutTableViewDataSource {
    
    let WORKOUT_CELL_IDENTIFIER = "workoutCell"
    let EXPAND_WORKOUT_CELL_IDENTIFIER = "expandWorkoutCell"
    let MAX_WORKOUTS = 3
    var allWorkouts: [Workout] = []
    var workoutsByDate: [String : WorkoutSection] = [:]
    var workoutDateKeys = [String]()
    
    
    // MARK: Helpers
    
    func removeWorkout(at indexPath: IndexPath) {
        self.workoutsByDate[self.workoutDateKeys[indexPath.section]]?.workouts.remove(at: indexPath.row)
    }
    
    func setWorkouts(_ workouts: [Workout]) {
        var newWorkoutDateKeys = [Date]()
        var newWorkoutsByDateKey: [String : WorkoutSection] = [:]
        for workout in workouts {
            if let date = workout.date, let dateKey = self.dateTitleFrom(date) {
                if newWorkoutsByDateKey[dateKey] == nil {
                    newWorkoutsByDateKey[dateKey] = WorkoutSection(isExpanded: false, workouts: [])
                    newWorkoutDateKeys.append(date)
                }
                newWorkoutsByDateKey[dateKey]?.workouts.append(workout)
            }
        }
        self.allWorkouts = workouts
        self.workoutDateKeys = newWorkoutDateKeys.sorted { $0 > $1 }.map({ date in
            self.dateTitleFrom(date) ?? "No Date"
        })
        self.workoutsByDate = newWorkoutsByDateKey
    }
    
    func toggleExpandSection(_ section: Int) {
        let isExpanded = self.workoutsByDate[self.workoutDateKeys[section]]?.isExpanded ?? false
        self.workoutsByDate[self.workoutDateKeys[section]]?.isExpanded = !isExpanded
    }
    
    func workoutSection(_ section: Int) -> WorkoutSection? {
        if section < self.workoutDateKeys.count {
            let dateKey = self.workoutDateKeys[section]
            return self.workoutsByDate[dateKey]
        } else {
            return nil
        }
    }
    
    func workoutsForSection(_ section: Int) -> [Workout]? {
        self.workoutSection(section)?.workouts
    }
    
    func workoutForIndexPath(_ indexPath: IndexPath) -> Workout? {
        guard let workoutSection = self.workoutSection(indexPath.section) else {
            return nil
        }
        
        if workoutSection.isExpanded {
            if indexPath.row < workoutSection.workouts.count {
                return workoutSection.workouts[indexPath.row]
            } else {
                return nil
            }
        } else {
            if indexPath.row < MAX_WORKOUTS {
                return workoutSection.workouts[indexPath.row]
            } else {
                return nil
            }
        }
    }
    
    func numberOfSections(_ tableView: UITableView) -> Int {
        return self.workoutDateKeys.count
    }
    
    func numberOfRowsInSection(_ tableView: UITableView, section: Int) -> Int {
        if let workoutSection = self.workoutSection(section) {
            let unexpandedCount = workoutSection.workouts.count <= MAX_WORKOUTS ? workoutSection.workouts.count : MAX_WORKOUTS + 1
            let expandedCount = workoutSection.workouts.count <= MAX_WORKOUTS ? workoutSection.workouts.count : workoutSection.workouts.count + 1
            return workoutSection.isExpanded ? expandedCount : unexpandedCount
        } else {
            return 0
        }
    }
    
    func cellForRowAtIndexPath(_ tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
        
        guard let workout = workoutForIndexPath(indexPath) else {
            let cell = tableView.dequeueReusableCell(withIdentifier: EXPAND_WORKOUT_CELL_IDENTIFIER, for: indexPath) as! ExpandWorkoutsTableViewCell
            cell.expandLabel.text = self.expandTitleForSection(indexPath.section)
            cell.expandImageView.image = self.expandImageForSection(indexPath.section)
            return cell
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: WORKOUT_CELL_IDENTIFIER, for: indexPath)
        
        var content = UIListContentConfiguration.cell()
        content.text = workout.exercise?.name ?? "Missing Name"
        content.textProperties.font = UIFont.systemFont(ofSize: 20)
        content.secondaryText = workout.exercise?.group?.name ?? "None"
        content.secondaryTextProperties.font = UIFont.systemFont(ofSize: 15)
        cell.contentConfiguration = content
        
        return cell
    }
    
    func expandTitleForSection(_ section: Int) -> String? {
        guard let workoutSection = self.workoutSection(section) else {
            return nil
        }
        
        if !workoutSection.isExpanded {
            return "Show \(workoutSection.workouts.count - MAX_WORKOUTS) More"
        } else {
            return "Collapse"
        }
    }
    
    func expandImageForSection(_ section: Int) -> UIImage? {
        guard let workoutSection = self.workoutSection(section) else {
            return nil
        }
        
        if !workoutSection.isExpanded {
            return UIImage(systemName:"chevron.down.circle")
        } else {
            return UIImage(systemName:"chevron.up.circle")
        }
    }
    
    func titleForSection(_ section: Int) -> String? {
        if section < self.workoutDateKeys.count {
            return self.workoutDateKeys[section]
        } else {
            return nil
        }
    }
    
    func dateTitleFrom(_ date: Date?, includeYear: Bool = true) -> String? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = includeYear ? "EE MM/dd/yy" : "EE MM/dd"
        
        if let date = date {
            return dateFormatter.string(from: date)
        } else {
            return nil
        }
    }
    
    func daysBetween(start: Date, end: Date) -> Int? {
        let calendar = Calendar.current
        // Remove the time component by extracting only the year, month, and day components
        let startDate = calendar.startOfDay(for: start)
        let endDate = calendar.startOfDay(for: end)
        
        let components = calendar.dateComponents([.day], from: startDate, to: endDate)
        if let days = components.day {
            return days
        } else {
            return nil
        }
    }
    
    func restDaysNumberForSection(_ tableView: UITableView, section: Int) -> Int? {
        if self.numberOfSections(tableView) > section {
            if let nextWorkoutDate = self.workoutsForSection(section + 1)?.first?.date,
               let currentWorkoutDate = self.workoutsForSection(section)?.first?.date {
                if let daysBetween = daysBetween(start: nextWorkoutDate, end: currentWorkoutDate) {
                    let restDays = daysBetween - 1
                    return restDays
                } else {
                    return nil
                }
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
    
    func restDaysForSection(_ tableView: UITableView, section: Int) -> String? {
        if let restDaysNumber = self.restDaysNumberForSection(tableView, section: section) {
            return restDaysNumber == 0 ? nil : "\(restDaysNumber) rest day\(restDaysNumber == 1 ? "" : "s")"
        } else {
            return nil
        }
    }
}
