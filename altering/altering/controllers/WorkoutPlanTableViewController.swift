import UIKit

class WorkoutPlanTableViewController: UITableViewController {
    
    let WORKOUT_NOTES_CELL_IDENTIFIER = "workoutNotesCell"
    let WORKOUT_PROGRAM_CELL_IDENTIFIER = "workoutProgramCellIdentifier"
    
    var workouts: [Workout]?
    var workoutPlan: WorkoutPlan?
    
    enum WorkoutPlanSections: Int {
        case workouts = 0
        case numSections = 1
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UINib(nibName: "WorkoutNotesTableViewCell", bundle: nil), forCellReuseIdentifier: WORKOUT_NOTES_CELL_IDENTIFIER)
        self.tableView.tableHeaderView = self.setupHeaderView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        (self.tableView.tableHeaderView as? WorkoutPlanHeaderView)?.setPlanProgress()
    }
    
    func setupHeaderView() -> UIView? {
        if let workoutPlan, let workouts {
            let headerView: WorkoutPlanHeaderView = WorkoutPlanHeaderView.fromNib()
            headerView.setupView(workoutPlan: workoutPlan, workouts: workouts)
            return headerView
        } else {
            return nil
        }
    }

    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch WorkoutPlanSections(rawValue: section) {
        case .workouts:
            return "Workouts"
        default:
            return nil
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return WorkoutPlanSections.numSections.rawValue
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch WorkoutPlanSections(rawValue: section) {
        case .workouts:
            return self.workouts?.count ?? 0
        default:
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch WorkoutPlanSections(rawValue: indexPath.section) {
        case .workouts:
            let cell = tableView.dequeueReusableCell(withIdentifier: WORKOUT_NOTES_CELL_IDENTIFIER, for: indexPath) as! WorkoutNotesTableViewCell
            if let workout = self.workouts?[indexPath.row] {
                cell.dateLabel.text = self.dateTitle(workout)
                cell.notesTextView.text = workout.notes
            }
            cell.notesTextView.isEditable = false
            cell.notesTextView.isScrollEnabled = false
            return cell
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: WORKOUT_NOTES_CELL_IDENTIFIER, for: indexPath) as! WorkoutNotesTableViewCell
            return cell
        }
    }
    
    func dateTitle(_ workout: Workout) -> String {
        if let date = workout.date, let dayDifference = self.daysBetween(start: date, end: Date.now), let title = self.dateTitleFrom(date, includeYear: true) {
            if dayDifference == 0 {
                return "\(title) (Today)"
            } else if dayDifference == 1 {
                return "\(title) (Yesterday)"
            } else {
                return "\(title) (\(dayDifference) day\(dayDifference == 1 ? "" : "s") ago)"
            }
        } else {
            return "Workout Date"
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
}
