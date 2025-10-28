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
            
            // Determine if this is the most recently completed workout in this program
            let isLastCompletedInProgram = self.isLastCompletedWorkoutInProgram(plan: plan, program: workoutProgram)
            
            // Determine if this program hasn't been done the longest across all programs (only show on first row)
            let isOldestProgram = indexPath.row == 0 && self.isProgramOldest(program: workoutProgram)
            
            // Debug logging
            print("Cell [\(indexPath.section), \(indexPath.row)]: \(plan.exercise?.name ?? "unknown")")
            print("  - isLastCompleted: \(isLastCompletedInProgram), isOldest: \(isOldestProgram), workoutCount: \(planWorkouts.count)")
            
            // Configure progress bar
            cell.progressBar.setProgress(Float(progress), animated: false)
            cell.progressBar.tintColor = progress == 1.0 ? .systemGreen : .systemBlue
            
            // Configure status icon - show special icons or nothing
            if progress == 1.0 {
                // Completed - show checkmark
                cell.dateImageView.image = UIImage(systemName: "checkmark.circle.fill")
                cell.dateImageView.tintColor = .systemGreen
                cell.dateLabel.text = "Completed!"
            } else if isLastCompletedInProgram && planWorkouts.count > 0 {
                // This was the last workout done in this program - show clock icon
                cell.dateImageView.image = UIImage(systemName: "clock.arrow.circlepath")
                cell.dateImageView.tintColor = .systemOrange
                let (dateText, _) = self.getDateLabelAndTint(progress: progress, program: workoutProgram, workouts: planWorkouts)
                cell.dateLabel.text = dateText
            } else if isOldestProgram {
                // This program hasn't been done the longest - show warning icon
                cell.dateImageView.image = UIImage(systemName: "exclamationmark.triangle.fill")
                cell.dateImageView.tintColor = .systemRed
                let (dateText, _) = self.getDateLabelAndTint(progress: progress, program: workoutProgram, workouts: planWorkouts)
                cell.dateLabel.text = dateText
            } else {
                // Regular cell - no special icon
                cell.dateImageView.image = nil
                let (dateText, _) = self.getDateLabelAndTint(progress: progress, program: workoutProgram, workouts: planWorkouts)
                cell.dateLabel.text = dateText
            }
        }
        
        return cell
    }
    
    // Helper to find the most recently completed workout in a program
    private func isLastCompletedWorkoutInProgram(plan: WorkoutPlan, program: WorkoutProgram) -> Bool {
        guard let allPlans = program.plans?.allObjects as? [WorkoutPlan] else { return false }
        
        var mostRecentDate: Date? = nil
        var mostRecentPlan: WorkoutPlan? = nil
        
        for p in allPlans {
            let workouts = program.workoutsForPlan(p) ?? []
            if let lastWorkout = workouts.sorted(by: { $0.date ?? Date.distantPast < $1.date ?? Date.distantPast }).last,
               let workoutDate = lastWorkout.date {
                if mostRecentDate == nil || workoutDate > mostRecentDate! {
                    mostRecentDate = workoutDate
                    mostRecentPlan = p
                }
            }
        }
        
        // Compare Core Data objects using objectID
        return mostRecentPlan?.objectID == plan.objectID
    }
    
    // Helper to determine if this program hasn't been done the longest (most days since last workout)
    private func isProgramOldest(program: WorkoutProgram) -> Bool {
        guard programs.count > 1 else { return false }
        
        var oldestDate: Date = Date.distantFuture // Start with future, looking for the oldest (furthest in past)
        var oldestProgram: WorkoutProgram? = nil
        var hasAnyWorkouts = false
        
        for p in programs {
            guard let allPlans = p.plans?.allObjects as? [WorkoutPlan] else { continue }
            
            // Find the most recent workout date for this program
            var programMostRecentDate: Date? = nil
            for plan in allPlans {
                let workouts = p.workoutsForPlan(plan) ?? []
                for workout in workouts {
                    if let workoutDate = workout.date {
                        if programMostRecentDate == nil || workoutDate > programMostRecentDate! {
                            programMostRecentDate = workoutDate
                        }
                    }
                }
            }
            
            // If this program has workouts, check if it's the oldest
            if let programDate = programMostRecentDate {
                hasAnyWorkouts = true
                // We want the OLDEST date (furthest in the past)
                if programDate < oldestDate {
                    oldestDate = programDate
                    oldestProgram = p
                }
            }
        }
        
        // Only mark as oldest if we found workouts and this is the program with the oldest recent workout
        return hasAnyWorkouts && oldestProgram?.objectID == program.objectID
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

