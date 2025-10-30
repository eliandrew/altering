import Foundation
import UIKit

struct WorkoutSection {
    var isExpanded: Bool
    var workouts: [Workout]
}

class WorkoutTableViewDataSource {
    
    let WORKOUT_CELL_IDENTIFIER = "workoutCellIdentifier"
    let EXPAND_WORKOUT_CELL_IDENTIFIER = "expandWorkoutCell"
    let MAX_WORKOUTS = 3
    var allWorkouts: [Workout] = []
    
    var firstWorkout: [String : Workout] = [:]
    
    var sectionTitles: [String]?
    
    var isPreview = false
    
    private var searchText: String?
    private var searchWorkoutsByDate: [String : WorkoutSection] = [:]
    private var searchWorkoutDateKeys = [String]()
    
    var workoutsByDate: [String : WorkoutSection] = [:]
    var workoutDateKeys = [String]()
    
    func setSearchText(_ text: String?) {
        self.searchText = text
        self.searchWorkoutsByDate = [:]
        self.searchWorkoutDateKeys = [String]()
        if let searchText = self.searchText?.lowercased(), !searchText.isEmpty {
            self.searchWorkoutsByDate = self.workoutsByDate.filter({ (date, workoutSection) in
                workoutSection.workouts.contains { workout in
                    workout.exercise?.name?.lowercased().contains(searchText) ?? false
                }
            })
            self.searchWorkoutDateKeys = self.searchWorkoutsByDate.map{ $0.key }
        } else {
            self.searchWorkoutDateKeys = self.workoutDateKeys
            self.searchWorkoutsByDate = self.workoutsByDate
        }
    }
    
    
    // MARK: Helpers
    
    func removeWorkout(at indexPath: IndexPath) {
        if let group = self.workoutsByDate[self.workoutDateKeys[indexPath.section]] {
            let key = self.workoutDateKeys[indexPath.section]
            if group.workouts.count == 1 {
                self.workoutDateKeys.remove(at: indexPath.section)
                self.workoutsByDate.removeValue(forKey: key)
                self.sectionTitles?.removeAll(where: { title in
                    title == convertDateStringToTitle(key)
                })
            } else {
                self.workoutsByDate[key]?.workouts.remove(at: indexPath.row)
            }
        }
        self.searchWorkoutDateKeys = self.workoutDateKeys
        self.searchWorkoutsByDate = self.workoutsByDate
    }
    
    func setWorkouts(_ workouts: [Workout]) {
        var newWorkoutDateKeys = [Date]()
        var newWorkoutsByDateKey: [String : WorkoutSection] = [:]
        for workout in workouts {
            if let exerciseName = workout.exercise?.name, let date = workout.date {
                if firstWorkout[exerciseName] == nil {
                    firstWorkout[exerciseName] = workout
                } else if let currentDate = firstWorkout[exerciseName]?.date, date < currentDate {
                    firstWorkout[exerciseName] = workout
                }
            }
            if let date = workout.date, let dateKey = self.dateTitleFrom(date) {
                if newWorkoutsByDateKey[dateKey] == nil {
                    newWorkoutsByDateKey[dateKey] = WorkoutSection(isExpanded: false, workouts: [])
                    newWorkoutDateKeys.append(date)
                }
                newWorkoutsByDateKey[dateKey]?.workouts.append(workout)
            }
        }
        newWorkoutDateKeys.sort { d1, d2 in
            d1 > d2
        }
        self.allWorkouts = workouts
        self.workoutDateKeys = newWorkoutDateKeys.map({ date in
            self.dateTitleFrom(date) ?? "No Date"
        })
        let allTitles = newWorkoutDateKeys.map { d in
            formatSectionTitle(d)
        }
        var seen = Set<String>()
        self.sectionTitles = allTitles.filter { element in
            if seen.contains(element) {
                return false
            } else {
                seen.insert(element)
                return true
            }
        }
        self.workoutsByDate = newWorkoutsByDateKey
        self.searchWorkoutDateKeys = self.workoutDateKeys
        self.searchWorkoutsByDate = self.workoutsByDate
    }
    
    func toggleExpandSection(_ section: Int) {
        let isExpanded = self.searchWorkoutsByDate[self.searchWorkoutDateKeys[section]]?.isExpanded ?? false
        self.searchWorkoutsByDate[self.searchWorkoutDateKeys[section]]?.isExpanded = !isExpanded
    }
    
    func workoutSection(_ section: Int) -> WorkoutSection? {
        if section < self.searchWorkoutDateKeys.count {
            let dateKey = self.searchWorkoutDateKeys[section]
            return self.searchWorkoutsByDate[dateKey]
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
        
        if workoutSection.isExpanded || isPreview {
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
    
    func sectionIndexTitles() -> [String]? {
        return self.sectionTitles
    }
    
    func sectionForSectionIndexTitle(_ title: String, at index: Int) -> Int {
        return self.searchWorkoutDateKeys.firstIndex { dateKey in
            title == convertDateStringToTitle(dateKey)
        } ?? 0
    }
    
    func numberOfSections(_ tableView: UITableView) -> Int {
        return self.searchWorkoutDateKeys.count
    }
    
    func numberOfRowsInSection(_ tableView: UITableView, section: Int) -> Int {
        if let workoutSection = self.workoutSection(section) {
            if isPreview { return workoutSection.workouts.count }
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
        
        let cell = tableView.dequeueReusableCell(withIdentifier: WORKOUT_CELL_IDENTIFIER, for: indexPath) as! MultiIconTableViewCell
        
        cell.subtitleLabel.text = workout.exercise?.group?.name ?? "None"
        cell.iconImageView.image = nil
        cell.subIconImageView.image = nil
        if let exerciseName = workout.exercise?.name {
            let firstWorkout = firstWorkout[exerciseName]
            if firstWorkout == workout && !isPreview {
                cell.iconImageView.image = UIImage(systemName: "figure.wave")
            }
            if !workout.completed {
                cell.iconImageView.image = UIImage(systemName: "pencil.and.list.clipboard")
            }
            cell.titleLabel.text = exerciseName
            cell.titleLabel.tintColor = .label
            cell.iconImageView.tintColor = .systemBlue
        } else {
            cell.titleLabel.text = "Exercise Deleted!"
            cell.titleLabel.tintColor = .systemRed
            cell.iconImageView.image = UIImage(systemName: "exclamationmark.circle.fill")
            cell.iconImageView.tintColor = .systemRed
        }
        if let _ = workout.program {
            cell.subIconImageView.image = UIImage(systemName: "doc.text.fill")
        }
        
        cell.accessoryType = isPreview ? .none : .disclosureIndicator
        cell.selectionStyle = isPreview ? .none : .default
        
        // Store whether this is an uncompleted program workout for later styling
        // tag=1 means uncompleted program workout, tag=0 means other
        cell.tag = (workout.program != nil && !workout.completed) ? 1 : 0
        
        
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
        if section < self.searchWorkoutDateKeys.count {
            return self.searchWorkoutDateKeys[section]
        } else {
            return nil
        }
    }
    
    func isSectionToday(_ section: Int) -> Bool {
        if section < self.searchWorkoutDateKeys.count {
            return self.searchWorkoutDateKeys[section] == dateTitleFrom(Date())
        } else {
            return false
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
    
    func restDaysBetween(start: WorkoutSection, end: WorkoutSection) -> Int? {
        if let nextWorkoutDate = end.workouts.first?.date,
           let currentWorkoutDate = start.workouts.first?.date {
                if let daysBetween = daysBetween(start: nextWorkoutDate, end: currentWorkoutDate) {
                    let restDays = daysBetween - 1
                    return restDays
                } else {
                    return nil
                }
            } else {
                return nil
            }
    }
    
    func streakLength(maxRestDays: Int) -> Int {
        let sectionsWithCompletedWorkouts = self.workoutsByDate.filter { (dateString: String, section: WorkoutSection) in
            section.workouts.contains { w in
                w.completed
            }
        }.map { (key: String, value: WorkoutSection) in
            value
        }.sorted { ws1, ws2 in
            ws1.workouts.first?.date ?? Date() > ws2.workouts.first?.date ?? Date()
        }
        
        guard sectionsWithCompletedWorkouts.count > 0, let firstWorkout = sectionsWithCompletedWorkouts[0].workouts.first?.date, let currentRestDays = self.daysBetween(start: firstWorkout, end: Date()) else {
            return 0
        }
        
        if currentRestDays > maxRestDays {
            return 0
        }
        
        var streakLength = 1
        
        let nSections = sectionsWithCompletedWorkouts.count
        if nSections == 0 {
            return 0
        }
        for i in 0..<nSections-1 {
            guard let restDays = restDaysBetween(start: sectionsWithCompletedWorkouts[i], end: sectionsWithCompletedWorkouts[i + 1]) else {
                return streakLength
            }
            if restDays <= maxRestDays {
                streakLength += 1
            } else {
                return streakLength
            }
        }
        return streakLength
        
    }
    
    func restDaysDatesForSection(_ tableView: UITableView, section: Int) -> (Date, Date)? {
        if self.numberOfSections(tableView) > section {
            if let nextWorkoutDate = self.workoutsForSection(section + 1)?.first?.date,
               let currentWorkoutDate = self.workoutsForSection(section)?.first?.date {
                return (currentWorkoutDate, nextWorkoutDate)
            } else {
                return nil
            }
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
