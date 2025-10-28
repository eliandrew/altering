import UIKit

class EditExerciseTableViewController: UITableViewController {
    
    // MARK: Constants
    let WORKOUT_CELL_IDENTIFIER = "workoutNotesCell"
    let NAME_CELL_IDENTIFIER = "nameCell"
    let DATE_CELL_IDENTIFIER = "dateCell"
    let GROUP_CELL_IDENTIFIER = "groupCell"
    
    
    let SELECT_GROUP_SEGUE_IDENTIFIER = "selectGroupSegue"
    let ADD_WORKOUT_SEGUE_IDENTIFIER = "addExerciseWorkout"
    
    enum EditExerciseSection: Int {
        case name = 0
        case group = 1
        case addWorkout = 2
        case workouts = 3
        case numSections = 4
    }
    
    // MARK: Properties
    var exercise: Exercise?
    var existingExerciseNames: [String?]?
    
    var exerciseName: String?
    var exerciseGroup: ExerciseGroup?
    var workouts: [Workout]?
    
    let dataLoader = DataLoader.shared
    private var hasAnimatedCells = false
    private var initialDataLoadComplete = false
    
    // MARK: - Modern UI Constants
    private let cardCornerRadius: CGFloat = 16
    private let cardShadowRadius: CGFloat = 8
    private let cardShadowOpacity: Float = 0.1
    private let sectionSpacing: CGFloat = 20
    
    // MARK: Actions
    
    func isExistingName(name: String?) -> Bool {
        guard let existingNames = existingExerciseNames else {
            return false
        }
        if let exercise = exercise {
            if exercise.name == name {
                return false
            } else {
                return existingNames.contains { existingName in
                    existingName == name
                }
            }
        } else {
            return existingNames.contains { existingName in
                existingName == name
            }
        }
    }
    
    func basicAlertController(title: String, message: String) -> UIAlertController {
        let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .cancel))
        return ac
    }
    
    func saveDataContext() {
        // Success haptic
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
        
        dataLoader.saveContext()
        navigationController?.popViewController(animated: true)
    }
    
    @objc func saveExercise() {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        if isExistingName(name: exerciseName) {
            // Error haptic
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.error)
            
            present(basicAlertController(title: "Duplicate Exercise Name", message: "Exercise must have unique name"), animated: true)
            return
        }
        if let exercise = exercise {
            guard let name = exerciseName, name != "" else {
                // Error haptic
                let notificationFeedback = UINotificationFeedbackGenerator()
                notificationFeedback.notificationOccurred(.error)
                
                present(basicAlertController(title: "Missing Exercise Name", message: "Exercise must have a name"), animated: true)
                return
            }
            exercise.name = name
            exercise.group = self.exerciseGroup
            saveDataContext()
        } else {
            guard let name = exerciseName else {
                // Error haptic
                let notificationFeedback = UINotificationFeedbackGenerator()
                notificationFeedback.notificationOccurred(.error)
                
                present(basicAlertController(title: "Missing Exercise Name", message: "Exercise must have a name"), animated: true)
                return
            }
            let newExercise = dataLoader.createNewExercise()
            newExercise.name = name
            newExercise.group = self.exerciseGroup
            saveDataContext()
        }
    }
    
    @objc func exit() {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        navigationController?.popViewController(animated: true)
    }
    
    // MARK: View Lifecycle
    
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
            action: #selector(saveExercise)
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
        
        // No separators
        tableView.separatorStyle = .none
        
        // Better spacing
        tableView.sectionHeaderTopPadding = 8
        
        // Use automatic dimensions for dynamic sizing
        tableView.estimatedRowHeight = 44
        tableView.rowHeight = UITableView.automaticDimension
        
        tableView.tableFooterView = nil
        
        // Keyboard handling
        tableView.keyboardDismissMode = .interactive
    }
    
    private func registerCells() {
        tableView.register(UINib(nibName: "WorkoutNotesTableViewCell", bundle: nil), forCellReuseIdentifier: WORKOUT_CELL_IDENTIFIER)
        tableView.register(UINib(nibName: "TextFieldTableViewCell", bundle: nil), forCellReuseIdentifier: NAME_CELL_IDENTIFIER)
        tableView.register(UINib(nibName: "DatePickerTableViewCell", bundle: nil), forCellReuseIdentifier: DATE_CELL_IDENTIFIER)
        tableView.register(UINib(nibName: "ButtonTableViewCell", bundle: nil), forCellReuseIdentifier: GROUP_CELL_IDENTIFIER)
    }
    
    private func loadData() {
        if let exercise = self.exercise {
            dataLoader.loadWorkouts(for: exercise) { result in
                switch result {
                case .success(let fetchedWorkouts):
                    self.workouts = fetchedWorkouts
                    // Use non-animated reload on initial load to prevent visible reload
                    if !self.initialDataLoadComplete {
                        UIView.performWithoutAnimation {
                            self.tableView.reloadData()
                        }
                        self.initialDataLoadComplete = true
                        self.triggerAnimationIfReady()
                    } else {
                        self.tableView.reloadData()
                    }
                case .failure(let error):
                    print("Error fetching workouts: \(error)")
                    self.initialDataLoadComplete = true
                    self.triggerAnimationIfReady()
                }
            }
            title = "Edit Exercise"
        } else {
            self.workouts = nil
            self.initialDataLoadComplete = true
            title = "Create Exercise"
        }
        
        exerciseName = self.exercise?.name
        self.exerciseGroup = self.exercise?.group
    }
    
    // MARK: - Modern Cell Styling
    
    private func styleCardCell(_ cell: UITableViewCell) {
        // Minimal styling - no cards
        cell.selectionStyle = .default
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Only animate after initial data load is complete
        triggerAnimationIfReady()
    }
    
    // MARK: - Animations
    
    private func triggerAnimationIfReady() {
        // Only animate if we haven't animated yet AND initial data is loaded
        if !hasAnimatedCells && initialDataLoadComplete {
            animateCellsEntrance()
            hasAnimatedCells = true
        }
    }
    
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
    
    @objc func groupButtonPressed() {
        // Haptic feedback
        let selectionFeedback = UISelectionFeedbackGenerator()
        selectionFeedback.selectionChanged()
        
        self.performSegue(withIdentifier: SELECT_GROUP_SEGUE_IDENTIFIER, sender: nil)
    }
    
    @objc func addWorkoutPressed() {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        if let tabBarController = self.tabBarController {
            if let secondTabNavController = tabBarController.viewControllers?[1] as? UINavigationController {
                   // Pop to the root view controller of the second tab
                   secondTabNavController.popToRootViewController(animated: false)
               }
            
            // Change to the desired tab index (e.g., 1 for the second tab)
            tabBarController.selectedIndex = 0
            
            // Step 2: Push the new view controller after the tab change
               if let newNavController = tabBarController.selectedViewController as? UINavigationController {
                   let storyboard = UIStoryboard(name: "Main", bundle: nil)
                   if let editWorkoutVC = storyboard.instantiateViewController(withIdentifier: "EditWorkoutTableViewController") as? EditWorkoutTableViewController {
                       editWorkoutVC.exercise = self.exercise
                       newNavController.pushViewController(editWorkoutVC, animated: true)
                   }
               }
        }
    }
    
    // MARK: Segues
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == SELECT_GROUP_SEGUE_IDENTIFIER {
            let vc = segue.destination as? SelectGroupTableViewController
            vc?.delegate = self
        }
    }
}

extension EditExerciseTableViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.exerciseName = textField.text
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidChangeSelection(_ textField: UITextField) {
        self.exerciseName = textField.text
    }
}

extension EditExerciseTableViewController: SelectGroupDelegate {
    func didSelectGroup(_ exerciseGroup: ExerciseGroup) {
        self.exerciseGroup = exerciseGroup
        tableView.reloadData()
    }
}

extension EditExerciseTableViewController {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return EditExerciseSection.numSections.rawValue
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch EditExerciseSection(rawValue: section) {
        case .addWorkout:
            return 1
        case .name:
            return 1
        case .group:
            return 1
        case .workouts:
            return self.workouts?.count ?? 0
        default:
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell
        
        switch EditExerciseSection(rawValue: indexPath.section) {
        case .addWorkout:
            cell = tableView.dequeueReusableCell(withIdentifier: GROUP_CELL_IDENTIFIER, for: indexPath)
            styleCardCell(cell)
            cell.selectionStyle = .none
            
            if let groupCell = cell as? ButtonTableViewCell {
                // Modern icon configuration
                let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .semibold)
                let plusImage = UIImage(systemName: "plus.circle.fill", withConfiguration: config)
                
                groupCell.button.setImage(plusImage, for: .normal)
                groupCell.button.setImage(plusImage, for: .highlighted)
                groupCell.button.setImage(plusImage, for: .selected)
                groupCell.button.setImage(plusImage, for: .focused)
                groupCell.button.tintColor = .systemBlue
                groupCell.button.addTarget(self, action: #selector(addWorkoutPressed), for: .touchUpInside)
            }
            return cell
            
        case .name:
            cell = tableView.dequeueReusableCell(withIdentifier: NAME_CELL_IDENTIFIER, for: indexPath)
            styleCardCell(cell)
            
            if let textFieldCell = cell as? TextFieldTableViewCell {
                textFieldCell.textField.placeholder = "e.g. DB Bench Press"
                textFieldCell.textField.text = exerciseName
                textFieldCell.textField.delegate = self
                textFieldCell.textField.font = UIFont.systemFont(ofSize: 20, weight: .medium)
            }
            return cell
            
        case .group:
            cell = tableView.dequeueReusableCell(withIdentifier: GROUP_CELL_IDENTIFIER, for: indexPath)
            styleCardCell(cell)
            cell.selectionStyle = .none
            
            if let groupCell = cell as? ButtonTableViewCell {
                let title = self.exerciseGroup?.name ?? (self.exercise?.group?.name ?? "Select Group")
                
                groupCell.button.setImage(nil, for: .normal)
                groupCell.button.setTitle(title, for: .normal)
                groupCell.button.setImage(nil, for: .highlighted)
                groupCell.button.setTitle(title, for: .highlighted)
                groupCell.button.setImage(nil, for: .selected)
                groupCell.button.setTitle(title, for: .selected)
                groupCell.button.setImage(nil, for: .focused)
                groupCell.button.setTitle(title, for: .focused)
                
                // Modern button styling
                groupCell.button.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .medium)
                groupCell.button.setTitleColor(.systemPurple, for: .normal)
                
                groupCell.button.addTarget(self, action: #selector(groupButtonPressed), for: .touchUpInside)
            }
            return cell
            
        case .workouts:
            cell = tableView.dequeueReusableCell(withIdentifier: WORKOUT_CELL_IDENTIFIER, for: indexPath)
            styleCardCell(cell)
            
            if let notesViewCell = cell as? WorkoutNotesTableViewCell, let workout = workouts?[indexPath.row] {
                notesViewCell.dateLabel.text = standardDateTitle(workout.date, referenceDate: Date.now, reference: .ago)
                notesViewCell.dateLabel.font = UIFont.systemFont(ofSize: 17, weight: .medium)
                notesViewCell.dateLabel.textColor = .secondaryLabel
                
                notesViewCell.notesTextView.text = workout.notes
                notesViewCell.notesTextView.isEditable = false
                notesViewCell.notesTextView.isScrollEnabled = false
                notesViewCell.notesTextView.backgroundColor = .clear
                notesViewCell.notesTextView.font = UIFont.systemFont(ofSize: 18)
            }
            return cell
            
        default:
            return tableView.dequeueReusableCell(withIdentifier: NAME_CELL_IDENTIFIER, for: indexPath)
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch EditExerciseSection(rawValue: section) {
        case .name:
            return "Name"
        case .group:
            return "Group"
        case .addWorkout:
            return "Add Workout"
        case .workouts:
            let workoutCount = workouts?.count ?? 0
            let title = "\(workoutCount == 0 ? "No" : "\(workoutCount)") Workout\(workoutCount == 1 ? "" : "s")"
            return title
        default:
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let header = view as? UITableViewHeaderFooterView else { return }
        
        // Modern header styling
        header.textLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        header.textLabel?.textColor = .secondaryLabel
        header.textLabel?.text = header.textLabel?.text?.uppercased()
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // Shadow path is set once during cell styling, no need for async updates here
        // Removing async updates prevents visual flickering during initial load
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        // Minimal footer spacing
        return 0
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }
}
