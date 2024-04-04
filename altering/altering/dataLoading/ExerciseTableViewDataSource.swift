import Foundation
import UIKit

class ExerciseTableViewDataSource {
    
    let EXERCISE_CELL_IDENTIFIER = "exerciseCell"
    
    var exercisesByGroup: [String : [Exercise]] = [:]
    var exerciseGroupKeys = [String]()
    
    // MARK: Helpers
    
    func lastPerformed(exercise: Exercise) -> String? {
        let dateFormatter = DateFormatter()
        // Set the date format
        dateFormatter.dateFormat = "EE MM/dd/yy" // Month/day/year
        // Format the Date object as a string
        let lastWorkout = exercise.workouts?.sortedArray(using: [NSSortDescriptor(key: "date", ascending: false)]).first as? Workout
        if let date = lastWorkout?.date {
            return dateFormatter.string(from: date)
        } else {
            return nil
        }
    }
    
    func removeExercise(at indexPath: IndexPath) {
        self.exercisesByGroup[self.exerciseGroupKeys[indexPath.section]]?.remove(at: indexPath.row)
    }
    
    func setExercises(_ exercises: [Exercise]) {
        var newExercisesByGroup: [String : [Exercise]] = [:]
        var newExerciseGroupKeys = [String]()
        for exercise in exercises {
            let groupKey = exercise.group?.name ?? "None"
            if newExercisesByGroup[groupKey] == nil {
                newExercisesByGroup[groupKey] = []
                newExerciseGroupKeys.append(groupKey)
            }
            newExercisesByGroup[groupKey]?.append(exercise)
        }
        self.exercisesByGroup = newExercisesByGroup
        self.exerciseGroupKeys = newExerciseGroupKeys.sorted()
    }
    
    func exercisesForSection(_ section: Int) -> [Exercise]? {
        if section < self.exerciseGroupKeys.count {
            let groupKey = self.exerciseGroupKeys[section]
            let n = self.exercisesByGroup[groupKey]
            return n
        } else {
            return nil
        }
    }
    
    func exerciseForIndexPath(_ indexPath: IndexPath) -> Exercise? {
        if let exercises = self.exercisesForSection(indexPath.section) {
            if indexPath.row < exercises.count {
                return exercises[indexPath.row]
            } else {
                return nil
            }
        }
        return nil
    }
    
    func exerciseNames() -> [String?] {
        return self.exercisesByGroup.values.flatMap { $0.map { $0.name ?? "" } }
    }
    
    func numberOfSections(_ tableView: UITableView) -> Int {
        return self.exerciseGroupKeys.count
    }
    
    func numberOfRowsInSection(_ tableView: UITableView, section: Int) -> Int {
        return self.exercisesForSection(section)?.count ?? 0
    }
    
    func cellForRowAtIndexPath(_ tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: EXERCISE_CELL_IDENTIFIER, for: indexPath)
        
        guard let exercise = exerciseForIndexPath(indexPath) else {
            return cell
        }
        
        var content = UIListContentConfiguration.cell()
        content.text = exercise.name ?? "Missing Name"
        content.textProperties.font = UIFont.systemFont(ofSize: 20)
        content.secondaryText = lastPerformed(exercise: exercise) ?? "No Workouts"
        content.secondaryTextProperties.font = UIFont.systemFont(ofSize: 15)
        cell.contentConfiguration = content
        
        return cell
    }
    
    func titleForSection(_ section: Int) -> String? {
        if section < self.exerciseGroupKeys.count {
            return self.exerciseGroupKeys[section]
        } else {
            return nil
        }
    }
}
