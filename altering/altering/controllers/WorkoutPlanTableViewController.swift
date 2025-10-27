import UIKit

class WorkoutPlanTableViewController: UITableViewController {
    
    // MARK: - Constants
    
    let ADD_WORKOUT_SEGUE = "addWorkoutSegue"
    let EDIT_WORKOUT_SEGUE = "editWorkoutSegue"
    
    let WORKOUT_NOTES_CELL_IDENTIFIER = "workoutNotesCell"
    let WORKOUT_PROGRAM_CELL_IDENTIFIER = "workoutProgramCellIdentifier"
    
    // MARK: - Properties
    
    let dataLoader = DataLoader.shared
    
    var workouts: [Workout]?
    var workoutPlan: WorkoutPlan?
    var program: WorkoutProgram?
    
    private var hasAnimatedCells = false
    
    enum WorkoutPlanSections: Int {
        case workouts = 0
        case numSections = 1
    }

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupTableViewStyle()
        registerCells()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Animate cells on first appearance
        if !hasAnimatedCells && (workouts?.count ?? 0) > 0 {
            animateCellsEntrance()
            hasAnimatedCells = true
        }
    }
    
    // MARK: - Setup
    
    private func setupNavigationBar() {
        // Modern add button with SF Symbol
        let addButton = UIBarButtonItem(
            image: UIImage(systemName: "plus.circle.fill"),
            style: .plain,
            target: self,
            action: #selector(addWorkout)
        )
        addButton.tintColor = .systemBlue
        navigationItem.rightBarButtonItem = addButton
        
        navigationItem.largeTitleDisplayMode = .never
    }
    
    private func setupTableViewStyle() {
        // Modern grouped style
        if #available(iOS 13.0, *) {
            tableView.backgroundColor = .systemGroupedBackground
        }
        
        // Remove separators for modern card look
        tableView.separatorStyle = .none
        
        // Better spacing
        tableView.sectionHeaderTopPadding = 12
    }
    
    private func registerCells() {
        tableView.register(UINib(nibName: "WorkoutNotesTableViewCell", bundle: nil), forCellReuseIdentifier: WORKOUT_NOTES_CELL_IDENTIFIER)
    }
    
    func setupView() {
        if let program {
            dataLoader.reloadWorkoutProgram(program) { result in
                switch result {
                case .success(let updatedProgram):
                    if let reloadedProgram = updatedProgram, let plan = self.workoutPlan {
                        self.program = reloadedProgram
                        self.workouts = self.program?.workoutsForPlan(plan)
                    }
                    DispatchQueue.main.async {
                        self.tableView.tableHeaderView = self.setupHeaderView()
                        (self.tableView.tableHeaderView as? WorkoutPlanHeaderView)?.setPlanProgress()
                        self.tableView.reloadData()
                    }
                case .failure(let error):
                    print("Error reloading program: \(error)")
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                }
            }
        }
    }
    
    @objc func addWorkout() {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        self.performSegue(withIdentifier: ADD_WORKOUT_SEGUE, sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == ADD_WORKOUT_SEGUE {
            if let vc = segue.destination as? EditWorkoutTableViewController {
                vc.exercise = self.workoutPlan?.exercise
                vc.program = self.program
                if let workout = sender as? Workout {
                    vc.workout = workout
                }
            }
        }
    }
    
    func setupHeaderView() -> UIView? {
        if let workoutPlan, let workouts {
            let headerView: WorkoutPlanHeaderView = WorkoutPlanHeaderView.fromNib()
            headerView.setupView(workoutPlan: workoutPlan, workouts: workouts)
            headerView.applyModernStyling()
            return headerView
        } else {
            return nil
        }
    }

    // MARK: - Table View Data Source
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch WorkoutPlanSections(rawValue: section) {
        case .workouts:
            return "WORKOUTS"
        default:
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        // Modern header styling
        if let headerView = view as? UITableViewHeaderFooterView {
            headerView.textLabel?.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
            headerView.textLabel?.textColor = .secondaryLabel
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
            cell.applyModernStyling()
            return cell
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: WORKOUT_NOTES_CELL_IDENTIFIER, for: indexPath) as! WorkoutNotesTableViewCell
            return cell
        }
    }
    
    // MARK: - Table View Delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch WorkoutPlanSections(rawValue: indexPath.section) {
        case .workouts:
            // Haptic feedback
            let selectionFeedback = UISelectionFeedbackGenerator()
            selectionFeedback.selectionChanged()
            
            // Animate cell selection
            if let cell = tableView.cellForRow(at: indexPath) {
                UIView.animate(withDuration: 0.1, delay: 0, options: .curveEaseOut, animations: {
                    cell.transform = CGAffineTransform(scaleX: 0.97, y: 0.97)
                }) { _ in
                    UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.8, options: .curveEaseOut) {
                        cell.transform = .identity
                    }
                }
            }
            
            if let workout = self.workouts?[indexPath.row] {
                self.performSegue(withIdentifier: ADD_WORKOUT_SEGUE, sender: workout)
            }
        default:
            return
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // Add subtle entrance animation for cells
        if !hasAnimatedCells {
            cell.alpha = 0
            cell.transform = CGAffineTransform(translationX: 0, y: 20)
        }
    }
    
    // MARK: - Animations
    
    private func animateCellsEntrance() {
        let cells = tableView.visibleCells
        
        for (index, cell) in cells.enumerated() {
            cell.alpha = 0
            cell.transform = CGAffineTransform(translationX: 0, y: 30)
            
            UIView.animate(
                withDuration: 0.5,
                delay: Double(index) * 0.05,
                usingSpringWithDamping: 0.8,
                initialSpringVelocity: 0.5,
                options: .curveEaseOut
            ) {
                cell.alpha = 1.0
                cell.transform = .identity
            }
        }
    }
    
    // MARK: - Utilities
    
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
