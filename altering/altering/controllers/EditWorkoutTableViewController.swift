import UIKit

class EditWorkoutTableViewController: UITableViewController {
    
    enum EditWorkoutTableViewSection: Int {
        case completed = 0
        case date = 1
        case exercise = 2
        case program = 3
        case notes = 4
        case workouts = 5
        case numSections = 6
    }

    // MARK: - Constants
    
    let PREVIOUS_NOTES_SECTION = 3
    let SELECT_EXERCISE_SEGUE = "selectExerciseSegue"
    let SELECT_WORKOUT_PROGRAM_SEGUE = "selectWorkoutProgramSegue"
    
    let DATE_CELL_IDENTIFIER = "dateCell"
    let BUTTON_CELL_IDENTIFIER = "buttonCell"
    let BASIC_CELL_IDENTIFIER = "basicCell"
    let WORKOUT_CELL_IDENTIFIER = "workoutCell"
    let COMPLETED_CELL_IDENTIFIER = "completeCell"
    
    // MARK: - Properties
    
    var workoutDataSource = WorkoutTableViewDataSource()
    
    var workout: Workout?
    var exercise: Exercise?
    var program: WorkoutProgram?
    var previousWorkouts: [Workout]?
    var currentNotes: String?
    var workoutCompleted: Bool?
    
    var selectedDate: Date?
    var originalWorkoutProgram: WorkoutProgram?
    var originalCompletion: Bool?
    
    let dataLoader = DataLoader.shared
    var allExercises: [Exercise]?
    
    private var hasAnimatedCells = false
    
    // MARK: - Modern UI Constants
    private let cardCornerRadius: CGFloat = 16
    private let cardShadowRadius: CGFloat = 8
    private let cardShadowOpacity: Float = 0.1
    private let sectionSpacing: CGFloat = 20
    
    // MARK: - Actions
    
    // Helper method to determine the appropriate date for a new workout
    func getDefaultWorkoutDate() -> Date {
        let now = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)
        
        // If it's after 9pm (21:00), set the date to the next day
        if hour >= 21 {
            return calendar.date(byAdding: .day, value: 1, to: now) ?? now
        }
        
        return now
    }
    
    @objc func workoutTypeChanged(_ sender: Any?) {
        if let segmentedControl = sender as? UISegmentedControl {
            // Haptic feedback
            let selectionFeedback = UISelectionFeedbackGenerator()
            selectionFeedback.selectionChanged()
            
            self.workoutCompleted = segmentedControl.selectedSegmentIndex == 0
        }
    }
    
    @objc func dateChanged(_ sender: Any?) {
        if let datePicker = sender as? UIDatePicker {
            // Haptic feedback
            let selectionFeedback = UISelectionFeedbackGenerator()
            selectionFeedback.selectionChanged()
            
            self.selectedDate = datePicker.date
            if let exercise = self.exercise {
                self.loadPreviousWorkouts(exercise, date: datePicker.date)
            }
        }
    }
    
    func basicAlertController(title: String, message: String) -> UIAlertController {
        let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .cancel))
        return ac
    }
    
    func loadPreviousWorkouts(_ exercise: Exercise, date: Date) {
        print("loading previous workouts")
        dataLoader.loadPreviousWorkouts(for: exercise, before: date, completion: { result in
            switch result {
                case .success(let previousWorkouts):
                    self.previousWorkouts = previousWorkouts
                    var indexSet = IndexSet(integer: EditWorkoutTableViewSection.workouts.rawValue)
                    if self.currentNotes?.isEmpty ?? true  {
                        self.currentNotes = previousWorkouts.first?.notes
                        indexSet.insert(EditWorkoutTableViewSection.notes.rawValue)
                    }
                    self.tableView.reloadSections(indexSet, with: .automatic)
                case .failure(let error):
                    print("Error fetching previous exercise: \(error)")
            }
        })
    }
    
    func loadAllExercises() {
        print("loading all exercises")
        dataLoader.loadAllExercises { result in
            switch result {
            case .success(let exercises):
                self.allExercises = Array(exercises.prefix(10))
            case .failure(let error):
                print("Error fetching all exercises: \(error)")
            }
        }
    }
    
    func saveDataContext() {
        // Success haptic
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
        
        dataLoader.saveContext()
        navigationController?.popViewController(animated: true)
    }
    
    func setupView() {
        setupNavigationBar()
        setupTableViewStyle()
        registerCells()
        loadData()
    }
    
    private func setupNavigationBar() {
        // Modern save button
        let saveButton = UIBarButtonItem(
            image: UIImage(systemName: "checkmark.circle.fill"),
            style: .done,
            target: self,
            action: #selector(saveWorkout)
        )
        saveButton.tintColor = .systemGreen
        navigationItem.rightBarButtonItem = saveButton
        
        // Modern close button
        let closeButton = UIBarButtonItem(
            image: UIImage(systemName: "xmark.circle.fill"),
            style: .plain,
            target: self,
            action: #selector(exit)
        )
        closeButton.tintColor = .systemGray
        navigationItem.leftBarButtonItem = closeButton
        
        // Enable large titles
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
    }
    
    private func setupTableViewStyle() {
        // Modern grouped style
        if #available(iOS 13.0, *) {
            tableView.backgroundColor = .systemGroupedBackground
        }
        
        // Remove separators for card-style design
        tableView.separatorStyle = .none
        
        // Better spacing
        tableView.sectionHeaderTopPadding = 16
        
        // Use automatic dimensions for dynamic sizing
        tableView.estimatedRowHeight = 70
        tableView.rowHeight = UITableView.automaticDimension
        
        tableView.tableFooterView = nil
        
        // Keyboard handling
        tableView.keyboardDismissMode = .interactive
        
        // Enable selection for card design
        tableView.allowsSelection = true
    }
    
    // MARK: - Modern Cell Styling
    
    private func styleCardCell(_ cell: UITableViewCell) {
        // Apply corner radius and background to content view
        cell.contentView.layer.cornerRadius = cardCornerRadius
        cell.contentView.layer.masksToBounds = true
        
        // Add subtle background for card effect
        if #available(iOS 13.0, *) {
            cell.contentView.backgroundColor = .secondarySystemGroupedBackground
            cell.backgroundColor = .clear
        } else {
            cell.contentView.backgroundColor = .white
            cell.backgroundColor = .clear
        }
        
        // Remove default selection style for better card appearance
        cell.selectionStyle = .none
        
        // Add shadow to the cell layer (not content view to avoid clipping)
        cell.layer.shadowColor = UIColor.black.cgColor
        cell.layer.shadowOffset = CGSize(width: 0, height: 2)
        cell.layer.shadowRadius = cardShadowRadius
        cell.layer.shadowOpacity = cardShadowOpacity
        cell.layer.masksToBounds = false
        
        // Performance optimization for shadows
        cell.layer.shadowPath = UIBezierPath(
            roundedRect: cell.bounds.insetBy(dx: 16, dy: 4),
            cornerRadius: cardCornerRadius
        ).cgPath
    }
    
    private func registerCells() {
        tableView.register(UINib(nibName: "DatePickerTableViewCell", bundle: nil), forCellReuseIdentifier: DATE_CELL_IDENTIFIER)
        tableView.register(UINib(nibName: "ButtonTableViewCell", bundle: nil), forCellReuseIdentifier: BUTTON_CELL_IDENTIFIER)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: BASIC_CELL_IDENTIFIER)
        tableView.register(UINib(nibName: "WorkoutNotesTableViewCell", bundle: nil), forCellReuseIdentifier: WORKOUT_CELL_IDENTIFIER)
        tableView.register(UINib(nibName: "SegmentedControlTableViewCell", bundle: nil), forCellReuseIdentifier: COMPLETED_CELL_IDENTIFIER)
    }
    
    private func loadData() {
        if let workout = workout {
            self.exercise = exercise ?? workout.exercise
            self.program = program ?? workout.program
            self.selectedDate = workout.date
            self.currentNotes = workout.notes
            self.workoutCompleted = workout.completed
            
            title = "Edit Workout"
        } else {
            title = "Create Workout"
            
            self.selectedDate = self.selectedDate ?? getDefaultWorkoutDate()
            self.workoutCompleted = self.workoutCompleted ?? false
        }
        
        if let exercise {
            self.loadPreviousWorkouts(exercise, date: self.selectedDate ?? Date.now)
        }
        self.loadAllExercises()
    }
    
    @objc func saveWorkout() {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        if let workout = workout {
            workout.date = self.selectedDate
            workout.notes = self.currentNotes
            workout.exercise = self.exercise
            workout.program = self.program
            workout.completed = self.workoutCompleted ?? true
            saveDataContext()
            if let newProgram = workout.program, originalWorkoutProgram != newProgram || originalCompletion != workoutCompleted, workout.completed {
                NotificationCenter.default.post(name: .workoutUpdate, object: nil, userInfo: ["workout" : workout])
            }
        } else {
            guard let exercise = self.exercise else {
                present(basicAlertController(title: "Missing Exercise", message: "Workout must have an Exercise"), animated: true)
                return
            }
            let newWorkout = dataLoader.createNewWorkout()
            newWorkout.date = self.selectedDate
            newWorkout.exercise = exercise
            newWorkout.program = self.program
            newWorkout.notes = self.currentNotes
            newWorkout.completed = self.workoutCompleted ?? true
            print("NEW WORKOUT COMPLETED: \(newWorkout.completed)")
            saveDataContext()
            if let _ = self.program {
                NotificationCenter.default.post(name: .workoutUpdate, object: nil, userInfo: ["workout" : newWorkout])
            }
        }
       
    }
    
    @objc func exit() {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        self.navigationController?.popViewController(animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Animate cells on first appearance
        if !hasAnimatedCells {
            animateCellsEntrance()
            hasAnimatedCells = true
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
    
    // MARK: - Table View Data Source
    
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell
        
        switch EditWorkoutTableViewSection(rawValue: indexPath.section) {
        case .date:
            cell = tableView.dequeueReusableCell(withIdentifier: DATE_CELL_IDENTIFIER, for: indexPath)
            if let dateCell = cell as? DatePickerTableViewCell {
                dateCell.dateSwitch.isHidden = true
                dateCell.datePicker.setDate(self.selectedDate ?? Date.now, animated: false)
                dateCell.datePicker.addTarget(self, action: #selector(dateChanged), for: .valueChanged)
                styleCardCell(dateCell)
            }
            return cell
            
        case .exercise:
            cell = tableView.dequeueReusableCell(withIdentifier: BASIC_CELL_IDENTIFIER, for: indexPath)
            styleCardCell(cell)
            
            // Modern icon with tint
            let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)
            cell.imageView?.image = UIImage(systemName: "dumbbell.fill", withConfiguration: config)
            cell.imageView?.tintColor = .systemBlue
            
            cell.textLabel?.text = exercise?.name ?? "Select Exercise"
            cell.textLabel?.numberOfLines = 0
            cell.textLabel?.font = UIFont.systemFont(ofSize: 17, weight: .medium)
            
            // Modern disclosure indicator
            cell.accessoryType = .disclosureIndicator
            cell.tintColor = .systemGray3
            return cell
            
        case .program:
            cell = tableView.dequeueReusableCell(withIdentifier: BASIC_CELL_IDENTIFIER, for: indexPath)
            styleCardCell(cell)
            
            if indexPath.row == 0 {
                let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)
                cell.imageView?.image = UIImage(systemName: "doc.text.fill", withConfiguration: config)
                cell.imageView?.tintColor = .systemPurple
                
                cell.textLabel?.text = self.program?.name ?? "Select Program"
                cell.textLabel?.numberOfLines = 0
                cell.textLabel?.font = UIFont.systemFont(ofSize: 17, weight: .medium)
                cell.textLabel?.textColor = .label
                
                cell.accessoryType = .disclosureIndicator
                cell.tintColor = .systemGray3
            } else {
                let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
                cell.imageView?.image = UIImage(systemName: "minus.circle.fill", withConfiguration: config)
                cell.imageView?.tintColor = .systemRed
                
                cell.textLabel?.text = "Remove Program"
                cell.textLabel?.font = UIFont.systemFont(ofSize: 17, weight: .medium)
                cell.textLabel?.textColor = .systemRed
                cell.accessoryType = .none
            }
            return cell
            
        case .notes:
            cell = tableView.dequeueReusableCell(withIdentifier: WORKOUT_CELL_IDENTIFIER, for: indexPath)
            styleCardCell(cell)
            
            if let notesViewCell = cell as? WorkoutNotesTableViewCell {
                notesViewCell.dateLabel.text = "Current Workout"
                notesViewCell.dateLabel.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
                notesViewCell.dateLabel.textColor = .systemGreen
                
                notesViewCell.notesTextView.text = self.currentNotes
                notesViewCell.notesTextView.delegate = self
                notesViewCell.notesTextView.backgroundColor = .tertiarySystemGroupedBackground
                notesViewCell.notesTextView.isEditable = true
                notesViewCell.notesTextView.isScrollEnabled = true
                notesViewCell.notesTextView.font = UIFont.systemFont(ofSize: 16)
                notesViewCell.notesTextView.layer.cornerRadius = 12
            }
            return cell
            
        case .completed:
            cell = tableView.dequeueReusableCell(withIdentifier: COMPLETED_CELL_IDENTIFIER, for: indexPath)
            styleCardCell(cell)
            
            if let completedCell = cell as? SegmentedControlTableViewCell {
                completedCell.segmentedControl.selectedSegmentIndex = self.workoutCompleted ?? true ? 0 : 1
                completedCell.segmentedControl.addTarget(self, action: #selector(workoutTypeChanged), for: .valueChanged)
            }
            return cell
            
        case .workouts:
            cell = tableView.dequeueReusableCell(withIdentifier: WORKOUT_CELL_IDENTIFIER, for: indexPath)
            styleCardCell(cell)
            
            if let notesViewCell = cell as? WorkoutNotesTableViewCell {
                let workout = previousWorkouts?[indexPath.row]
                notesViewCell.dateLabel.text = standardDateTitle(workout?.date, referenceDate: self.workout?.date ?? Date.now, reference: .before)
                notesViewCell.dateLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
                notesViewCell.dateLabel.textColor = .secondaryLabel
                
                notesViewCell.notesTextView.text = workout?.notes
                notesViewCell.notesTextView.isEditable = false
                notesViewCell.notesTextView.isScrollEnabled = false
                notesViewCell.notesTextView.backgroundColor = .clear
                notesViewCell.notesTextView.font = UIFont.systemFont(ofSize: 15)
            }
            return cell
            
        default:
            return tableView.dequeueReusableCell(withIdentifier: BASIC_CELL_IDENTIFIER, for: indexPath)
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return EditWorkoutTableViewSection.numSections.rawValue
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch EditWorkoutTableViewSection(rawValue: section) {
        case .date:
            return 1
        case .exercise:
            return 1
        case .program:
            return 2
        case .notes:
            return 1
        case .completed:
            return 1
        case .workouts:
            return self.previousWorkouts?.count ?? 0
        default:
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch EditWorkoutTableViewSection(rawValue: section) {
        case .date:
            return "Date"
        case .exercise:
            return "Exercise"
        case .program:
            return "Program"
        case .notes:
            return "Notes"
        case .completed:
            return "Workout Type"
        case .workouts:
            if let prevWorkouts = self.previousWorkouts, prevWorkouts.count > 0 {
                return "\(prevWorkouts.count) Previous Workout\(prevWorkouts.count == 1 ? "" : "s")"
            } else {
                return "No Previous Workouts"
            }
        default:
            return ""
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let header = view as? UITableViewHeaderFooterView else { return }
        
        // Modern header styling
        header.textLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        header.textLabel?.textColor = .secondaryLabel
        header.textLabel?.text = header.textLabel?.text?.uppercased()
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // Update shadow path when cell is about to be displayed (after layout)
        DispatchQueue.main.async {
            if cell.layer.shadowOpacity > 0 {
                cell.layer.shadowPath = UIBezierPath(
                    roundedRect: cell.bounds.insetBy(dx: 16, dy: 4),
                    cornerRadius: self.cardCornerRadius
                ).cgPath
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        // Add spacing between sections for card layout
        return 8
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        // Return clear view for spacing
        let footer = UIView()
        footer.backgroundColor = .clear
        return footer
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch EditWorkoutTableViewSection(rawValue: indexPath.section) {
        case .date:
            return UITableView.automaticDimension
        case .exercise:
            return UITableView.automaticDimension
        case .program:
            return UITableView.automaticDimension
        case .notes:
            return 350.0
        case .completed:
            return UITableView.automaticDimension
        case .workouts:
            return UITableView.automaticDimension
        default:
            return UITableView.automaticDimension
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Haptic feedback for selection
        let selectionFeedback = UISelectionFeedbackGenerator()
        selectionFeedback.selectionChanged()
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        // Add subtle animation on selection
        if let cell = tableView.cellForRow(at: indexPath) {
            UIView.animate(withDuration: 0.1, animations: {
                cell.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            }) { _ in
                UIView.animate(withDuration: 0.1) {
                    cell.transform = .identity
                }
            }
        }
        
        switch EditWorkoutTableViewSection(rawValue: indexPath.section) {
        case .date:
            return
        case .exercise:
            self.performSegue(withIdentifier: SELECT_EXERCISE_SEGUE, sender: self)
            return
        case .program:
            if indexPath.row == 0 {
                self.performSegue(withIdentifier: SELECT_WORKOUT_PROGRAM_SEGUE, sender: self)
            } else {
                // Haptic for destructive action
                let impactFeedback = UINotificationFeedbackGenerator()
                impactFeedback.notificationOccurred(.warning)
                
                self.program = nil
                tableView.reloadRows(at: [IndexPath(row: 0, section: EditWorkoutTableViewSection.program.rawValue)], with: .automatic)
            }
            return
        case .notes:
            return
        case .completed:
            return
        case .workouts:
            return
        default:
            return
        }
    }

    // MARK: Segues
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == SELECT_EXERCISE_SEGUE {
            let vc = segue.destination as? SelectExerciseTableViewController
            vc?.delegate = self
        } else if segue.identifier == SELECT_WORKOUT_PROGRAM_SEGUE {
            if let exercise = self.exercise {
                let vc = segue.destination as? SelectWorkoutProgramTableViewController
                vc?.delegate = self
                vc?.exercise = exercise
            } else {
                present(basicAlertController(title: "Missing Exercise", message: "An exercise must be selected before the program"), animated: true)
            }
            
        }
    }
}

extension EditWorkoutTableViewController: SelectExerciseDelegate {
    func didSelectExercise(_ exercise: Exercise) {
        self.exercise = exercise
        self.tableView.reloadSections(IndexSet(integer: EditWorkoutTableViewSection.exercise.rawValue), with: .automatic)
        self.loadPreviousWorkouts(exercise, date: self.selectedDate ?? Date.now)
    }
}

extension EditWorkoutTableViewController: SelectWorkoutProgramDelegate {
    
    func didSelectWorkoutProgram(_ program: WorkoutProgram) {
        self.program = program
        self.tableView.reloadRows(at: [IndexPath(row: 0, section: EditWorkoutTableViewSection.program.rawValue)], with: .automatic)
    }
}

extension EditWorkoutTableViewController: UITextViewDelegate {
//    // Function to filter emojis from a string
//    func filterEmojis(from input: String) -> String {
//        let emojiPattern = "[\\p{So}\\p{C}]"
//        let regex = try! NSRegularExpression(pattern: emojiPattern, options: [])
//        let range = NSRange(location: 0, length: input.utf16.count)
//        return regex.stringByReplacingMatches(in: input, options: [], range: range, withTemplate: "")
//    }
//
//    func findMatchingExerciseNames(from textInput: String, exerciseNames: [String]) -> [String] {
//        // Strip trailing whitespace from the input text
//        let trimmedInput = textInput.trimmingCharacters(in: .whitespacesAndNewlines)
//        
//        // Filter out emojis from the exerciseNames and trim whitespace
//        let filteredExerciseNames = exerciseNames.map { filterEmojis(from: $0).trimmingCharacters(in: .whitespacesAndNewlines) }
//        
//        // Split the input text into words
//        let words = trimmedInput.split(separator: " ").map { String($0) }
//        var matchedNames = [String]()
//
//        // Check consecutive tokens
//        for length in 1...words.count {
//            for i in 0...(words.count - length) {
//                let token = words[i...(i + length - 1)].joined(separator: " ")
//                if filteredExerciseNames.contains(token) {
//                    matchedNames.append(token)
//                }
//            }
//        }
//        
//        return matchedNames
//    }
    func textViewDidChange(_ textView: UITextView) {
        self.currentNotes = textView.text
        // Search the textView text to see if it contains any of the exercise names from allExercises
//        if let exerciseNames = allExercises?.compactMap({ $0.name }) {
//            print("\(findMatchingExerciseNames(from: textView.text, exerciseNames: exerciseNames))")
//        }
    }
}
