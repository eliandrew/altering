import UIKit

class EditWorkoutProgramTableViewController: UITableViewController {
    
    // MARK: - Constants
    let NUM_SECTIONS = 5
    
    let NAME_SECTION = 0
    let START_DATE_SECTION = 1
    let END_DATE_SECTION = 2
    let ADD_WORKOUT_SECTION = 3
    let WORKOUT_PLAN_SECTION = 4
    
    let ADD_PROGRAM_EXERCISE_SEGUE = "addProgramExerciseSegue"
    
    let NAME_CELL_IDENTIFIER = "nameCellIdentifier"
    let DATE_CELL_IDENTIFIER = "dateCellIdentifier"
    let WORKOUT_PLAN_CELL_IDENTIFIER = "workoutPlanCell"
    let ADD_WORKOUT_CELL_IDENTIFIER = "addWorkoutCell"
    
    // MARK: - Properties
    
    var workoutPlans = [WorkoutPlan]()
    var programName: String?
    var programStartDate: Date?
    var programStartDateActive = true
    var programEndDate: Date?
    var programEndDateActive = true
    
    var selectedIndexPath: IndexPath?
    var workoutProgram: WorkoutProgram?
    
    let dataLoader = DataLoader.shared
    
    private var hasAnimatedCells = false

    // MARK: - View Lifecycle
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == ADD_PROGRAM_EXERCISE_SEGUE {
            let vc = segue.destination as! SelectExerciseTableViewController
            vc.delegate = self
        }
    }
    
    func saveDataContext() {
        // Success haptic
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
        
        dataLoader.saveContext()
        navigationController?.popViewController(animated: true)
    }
    
    @objc func saveProgram() {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        if let program = workoutProgram {
            program.name = programName
            program.start = programStartDateActive ? programStartDate : nil
            program.end = programEndDateActive ? programEndDate : nil
            program.plans = NSSet(array: workoutPlans)
            saveDataContext()
        } else {
            guard let name = self.programName, !name.isEmpty else {
                // Error haptic
                let notificationFeedback = UINotificationFeedbackGenerator()
                notificationFeedback.notificationOccurred(.error)
                
                present(createModernAlert(title: "Missing Program Name", message: "Program must have a name"), animated: true)
                return
            }
            
            let newProgram = dataLoader.createNewWorkoutProgram()
            newProgram.name = self.programName
            newProgram.start = self.programStartDateActive ? self.programStartDate : nil
            newProgram.end = self.programEndDateActive ? self.programEndDate : nil
            newProgram.plans = NSSet(array: workoutPlans)
            saveDataContext()
        }
    }
    
    @objc func exit() {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        navigationController?.popViewController(animated: true)
    }
    
    func setupView() {
        setupNavigationBar()
        setupTableViewStyle()
        loadProgramData()
        registerCells()
    }
    
    private func setupNavigationBar() {
        // Modern navigation buttons with SF Symbols
        let saveButton = UIBarButtonItem(
            image: UIImage(systemName: "checkmark.circle.fill"),
            style: .done,
            target: self,
            action: #selector(saveProgram)
        )
        saveButton.tintColor = .systemGreen
        navigationItem.rightBarButtonItem = saveButton
        
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
        
        // Set title based on mode
        title = workoutProgram != nil ? "Edit Program" : "Create Program"
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
        
        // Keyboard handling
        tableView.keyboardDismissMode = .interactive
    }
    
    private func loadProgramData() {
        if let program = self.workoutProgram {
            programName = program.name
            programStartDate = program.start
            programStartDateActive = program.start != nil
            programEndDate = program.end
            programEndDateActive = program.end != nil
            
            if let plans = program.plans?.allObjects as? [WorkoutPlan] {
                workoutPlans = plans
            }
        }
    }
    
    private func registerCells() {
        tableView.register(UINib(nibName: "TextFieldTableViewCell", bundle: nil), forCellReuseIdentifier: NAME_CELL_IDENTIFIER)
        tableView.register(UINib(nibName: "DatePickerTableViewCell", bundle: nil), forCellReuseIdentifier: DATE_CELL_IDENTIFIER)
        tableView.register(UINib(nibName: "WorkoutPlanTableViewCell", bundle: nil), forCellReuseIdentifier: WORKOUT_PLAN_CELL_IDENTIFIER)
        tableView.register(UINib(nibName: "ButtonTableViewCell", bundle: nil), forCellReuseIdentifier: ADD_WORKOUT_CELL_IDENTIFIER)
    }
    
    @objc func addExercisePressed() {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        performSegue(withIdentifier: ADD_PROGRAM_EXERCISE_SEGUE, sender: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Animate cells on first appearance
        if !hasAnimatedCells {
            animateCellsEntrance()
            hasAnimatedCells = true
        }
    }
    
    // MARK: - Table View Data Source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return NUM_SECTIONS
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case NAME_SECTION:
            return 1
        case START_DATE_SECTION:
            return 1
        case END_DATE_SECTION:
            return 1
        case ADD_WORKOUT_SECTION:
            return 1
        case WORKOUT_PLAN_SECTION:
            return self.workoutPlans.count
        default:
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case NAME_SECTION:
            return "PROGRAM NAME"
        case START_DATE_SECTION:
            return "START DATE"
        case END_DATE_SECTION:
            return "END DATE"
        case ADD_WORKOUT_SECTION:
            return "WORKOUT PLANS"
        default:
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        // Modern header styling
        if let headerView = view as? UITableViewHeaderFooterView {
            headerView.textLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
            headerView.textLabel?.textColor = .secondaryLabel
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case NAME_SECTION:
            let cell = tableView.dequeueReusableCell(withIdentifier: NAME_CELL_IDENTIFIER, for: indexPath) as! TextFieldTableViewCell
            cell.textField.delegate = self
            cell.textField.text = programName
            cell.applyModernStyling()
            return cell
            
        case START_DATE_SECTION:
            let cell = tableView.dequeueReusableCell(withIdentifier: DATE_CELL_IDENTIFIER, for: indexPath) as! DatePickerTableViewCell
            cell.datePicker.tag = START_DATE_SECTION
            cell.dateSwitch.tag = START_DATE_SECTION
            cell.datePicker.addTarget(self, action: #selector(datePickerChanged), for: .valueChanged)
            cell.dateSwitch.addTarget(self, action: #selector(switchChanged), for: .valueChanged)
            cell.datePicker.date = self.programStartDate ?? Date.now
            cell.dateSwitch.isOn = self.programStartDateActive
            cell.applyModernStyling()
            return cell
            
        case END_DATE_SECTION:
            let cell = tableView.dequeueReusableCell(withIdentifier: DATE_CELL_IDENTIFIER, for: indexPath) as! DatePickerTableViewCell
            cell.datePicker.tag = END_DATE_SECTION
            cell.dateSwitch.tag = END_DATE_SECTION
            cell.datePicker.addTarget(self, action: #selector(datePickerChanged), for: .valueChanged)
            cell.dateSwitch.addTarget(self, action: #selector(switchChanged), for: .valueChanged)
            cell.datePicker.date = self.programEndDate ?? Date.now
            cell.dateSwitch.isOn = self.programEndDateActive
            cell.applyModernStyling()
            return cell
            
        case ADD_WORKOUT_SECTION:
            let cell = tableView.dequeueReusableCell(withIdentifier: ADD_WORKOUT_CELL_IDENTIFIER, for: indexPath) as! ButtonTableViewCell
            cell.button.addTarget(self, action: #selector(addExercisePressed), for: .touchUpInside)
            cell.button.setImage(UIImage(systemName: "plus.circle.fill"), for: .normal)
            cell.button.setImage(UIImage(systemName: "plus.circle.fill"), for: .focused)
            cell.button.setImage(UIImage(systemName: "plus.circle.fill"), for: .selected)
            cell.button.setImage(UIImage(systemName: "plus.circle.fill"), for: .highlighted)
            cell.applyModernStyling()
            return cell
            
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: WORKOUT_PLAN_CELL_IDENTIFIER, for: indexPath) as! WorkoutPlanTableViewCell
            let plan = workoutPlans[indexPath.row]
            cell.exerciseLabel.text = plan.exercise?.name ?? "Exercise Name"
            cell.setWorkoutCount(plan.numWorkouts)
            cell.workoutCountSlider.tag = indexPath.row
            cell.workoutCountSlider.addTarget(self, action: #selector(sliderChanged), for: .valueChanged)
            cell.applyModernStyling()
            return cell
        }
    }
    
    // MARK: - Table View Delegate
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Haptic feedback
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.success)
            
            let plan = self.workoutPlans[indexPath.row]
            dataLoader.deleteWorkoutPlan(plan)
            dataLoader.saveContext()
            self.workoutPlans.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return "Delete"
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section == WORKOUT_PLAN_SECTION
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == WORKOUT_PLAN_SECTION {
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
            
            self.selectedIndexPath = indexPath
            self.performSegue(withIdentifier: ADD_PROGRAM_EXERCISE_SEGUE, sender: nil)
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // Add subtle entrance animation for cells
        if !hasAnimatedCells {
            cell.alpha = 0
            cell.transform = CGAffineTransform(translationX: 0, y: 20)
        }
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard indexPath.section == WORKOUT_PLAN_SECTION else { return nil }
        
        let deleteAction = UIContextualAction(style: .destructive, title: nil) { [weak self] (_, _, completionHandler) in
            self?.deleteWorkoutPlan(at: indexPath)
            completionHandler(true)
        }
        deleteAction.image = UIImage(systemName: "trash.fill")
        deleteAction.backgroundColor = .systemRed
        
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
    
    private func deleteWorkoutPlan(at indexPath: IndexPath) {
        // Haptic feedback
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
        
        let plan = self.workoutPlans[indexPath.row]
        dataLoader.deleteWorkoutPlan(plan)
        dataLoader.saveContext()
        self.workoutPlans.remove(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .fade)
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
    
    func basicAlertController(title: String, message: String) -> UIAlertController {
        let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .cancel))
        return ac
    }
    
    private func createModernAlert(title: String, message: String) -> UIAlertController {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "OK", style: .default) { _ in
            // Focus on the name text field if it's empty
            if let nameCell = self.tableView.cellForRow(at: IndexPath(row: 0, section: self.NAME_SECTION)) as? TextFieldTableViewCell {
                nameCell.textField.becomeFirstResponder()
            }
        }
        
        alertController.addAction(okAction)
        return alertController
    }
    
    // MARK: - Actions
    
    @objc func datePickerChanged(_ sender: Any?) {
        if let sender = sender as? UIDatePicker {
            if sender.tag == START_DATE_SECTION {
                self.programStartDate = sender.date
            } else {
                self.programEndDate = sender.date
            }
        }
    }
    
    @objc func switchChanged(_ sender: Any?) {
        if let sender = sender as? UISwitch {
            if sender.tag == START_DATE_SECTION {
                self.programStartDateActive = sender.isOn
            } else {
                self.programEndDateActive = sender.isOn
            }
        }
    }
    
    @objc func sliderChanged(_ sender: Any?) {
        if let sender = sender as? UISlider {
            self.workoutPlans[sender.tag].numWorkouts = Int64(sender.value)
        }
    }
    
}

extension EditWorkoutProgramTableViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        self.programName = textField.text
    }
    
    func textFieldDidChangeSelection(_ textField: UITextField) {
        self.programName = textField.text
    }
}

extension EditWorkoutProgramTableViewController: SelectExerciseDelegate {
    func didSelectExercise(_ exercise: Exercise) {
        let allExercises = self.workoutPlans.map { p in
            p.exercise
        }
        if allExercises.contains(exercise) {
            return
        }
        if let indexPath = self.selectedIndexPath {
            workoutPlans[indexPath.row].exercise = exercise
            self.tableView.reloadRows(at: [indexPath], with: .automatic)
            self.selectedIndexPath = nil
        } else {
            let newPlan = dataLoader.createNewWorkoutPlan()
            newPlan.exercise = exercise
            newPlan.numWorkouts = 5
            dataLoader.saveContext()
            workoutPlans.append(newPlan)
            self.tableView.insertRows(at: [IndexPath(row: self.workoutPlans.count - 1, section: WORKOUT_PLAN_SECTION)], with: .automatic)
        }
        dataLoader.saveContext()
    }
}
