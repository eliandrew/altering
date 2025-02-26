import Foundation
import UIKit

class WorkoutProgramTableViewDataSource {
    
    let PROGRAM_CELL_IDENTIFIER = "programCell"
    let WORKOUT_PROGRAM_CELL_IDENTIFIER = "workoutProgramCellIdentifier"
    let SEARCH_WORKOUT_PROGRAM_CELL_IDENTIFIER = "searchWorkoutProgramCell"
    
    var programs = [WorkoutProgram]()
    
    // MARK: Search
    private var searchText: String?
    var searchPrograms = [WorkoutProgram]()
    
    func setSearchText(_ text: String?) {
        self.searchText = text
        self.searchPrograms = [WorkoutProgram]()
        if let searchText = self.searchText?.lowercased(), !searchText.isEmpty {
            let searchPrograms = programs.filter { program in
                program.name?.lowercased().contains(searchText) ?? false
            }
            if searchPrograms.count > 0 {
                self.searchPrograms = searchPrograms
            }
        } else {
            self.searchPrograms = self.programs
        }
    }
    
    // MARK: Helpers
    
    func removeProgram(at section: Int) {
        self.programs.remove(at: section)
    }
    
    func setPrograms(_ programs: [WorkoutProgram]) {
        self.programs = programs
        let _ = self.programs.partition { p in
            p.isComplete() ?? false
        }
        self.searchPrograms = self.programs
    }
    
    func numberOfSections(_ tableView: UITableView) -> Int {
        return self.programs.count
    }
    
    func numberOfRowsInSection(_ tableView: UITableView, section: Int) -> Int {
        return self.programs[section].plans?.count ?? 0
    }
    
    func planForIndexPath(_ indexPath: IndexPath) -> WorkoutPlan? {
        let workoutProgram = self.programs[indexPath.section]
        if let plans = workoutProgram.plans?.allObjects as? [WorkoutPlan] {
            let plansSorted = plans.sorted { w1, w2 in
                w1.exercise?.name ?? "" < w2.exercise?.name ?? ""
            }
            return plansSorted[indexPath.row]
        } else {
            return nil
        }
    }
    
    func programForIndexPath(_ indexPath: IndexPath) -> WorkoutProgram? {
        return self.programs[indexPath.section]
    }
    
    func cellForRowAtIndexPath(_ tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: WORKOUT_PROGRAM_CELL_IDENTIFIER, for: indexPath) as! WorkoutProgramTableViewCell
        let workoutProgram = self.programs[indexPath.section]
        if let plans = workoutProgram.plans?.allObjects as? [WorkoutPlan] {
            let plansSorted = plans.sorted { w1, w2 in
                w1.exercise?.name ?? "" < w2.exercise?.name ?? ""
            }
            let plan = plansSorted[indexPath.row]
            cell.exerciseLabel.text = plan.exercise?.name ?? "Exercise Missing"
            let planWorkouts = workoutProgram.workoutsForPlan(plan) ?? []
            let progress = Float(planWorkouts.count) / Float(plan.numWorkouts)
            if progress == 1.0 {
                cell.progressBar.tintColor = .systemGreen
                cell.remainingWorkoutCountLabel.text = "0"
                cell.remainingSubtitleLabel.text = "remaining"
                cell.progressBar.setProgress(Float(progress), animated: false)
                cell.dateImageView.image = UIImage(systemName: "checkmark.circle.fill")
                cell.dateImageView.tintColor = .systemGreen
                cell.dateLabel.text = "Completed!"
            } else {
                cell.progressBar.tintColor = .systemBlue
                cell.remainingWorkoutCountLabel.text = "\(plan.numWorkouts - Int64(planWorkouts.count))"
                cell.remainingSubtitleLabel.text = "remaining"
                cell.progressBar.setProgress(Float(progress), animated: false)
                cell.dateImageView.image = UIImage(systemName: "calendar")
                let (dateText, tintColor) = self.getDateLabelAndTint(progress: progress, program: workoutProgram, workouts: planWorkouts)
                cell.dateImageView.tintColor = tintColor
                cell.dateLabel.text = dateText
            }
        }
        
        return cell
    }
    
    func getDateLabelAndTint(progress: Float, program: WorkoutProgram, workouts: [Workout]) -> (String, UIColor) {
        let completedColor: UIColor = .systemGreen
        let lateColor: UIColor = .systemRed
        let defaultColor: UIColor = .systemBlue
        if progress == 1.0 {
            return ("Completed!", completedColor)
        }
        if let endDate = program.end {
            if endDate < Date.now {
                let days = daysBetween(start: endDate, end: Date.now) ?? 0
                return ("Ended \(days) day\(days == 1 ? "" : "s") ago", lateColor)
            } else {
                let days = daysBetween(start: Date.now, end: endDate) ?? 0
                return ("Ends in \(days) day\(days == 1 ? "" : "s")", defaultColor)
            }
        }
        if let startDate = program.start {
            if startDate < Date.now {
                let days = daysBetween(start: startDate, end: Date.now) ?? 0
                return ("Started \(days) day\(days == 1 ? "" : "s") ago", defaultColor)
            } else {
                let days = daysBetween(start: Date.now, end: startDate) ?? 0
                return ("Starts in \(days) day\(days == 1 ? "" : "s")", defaultColor)
            }
        } else if let firstWorkout = workouts.sorted(by: { w1, w2 in
            w1.date! < w2.date!
        }).last {
            let days = daysBetween(start: firstWorkout.date ?? Date.now, end: Date.now) ?? 0
            return ("Last workout \(days == 0 ? "was today" : "\(days) day\(days == 1 ? "" : "s") ago")", defaultColor)
        } else {
            return ("No workouts yet", defaultColor)
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
    
    func searchCellForRowAtIndexPath(_ tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SEARCH_WORKOUT_PROGRAM_CELL_IDENTIFIER, for: indexPath)
        cell.textLabel?.text = self.searchPrograms[indexPath.row].name ?? "Missing Name"
        cell.detailTextLabel?.text = nil
        return cell
    }
    
    func titleForSection(_ section: Int) -> String? {
        return self.programs[section].name
    }
}

