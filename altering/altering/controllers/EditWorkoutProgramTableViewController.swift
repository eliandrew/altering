import UIKit

class EditWorkoutProgramTableViewController: UITableViewController {
    
    // MARK: Constants
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
    
    // MARK: Properties
    
    var workoutPlans = [WorkoutPlan]()
    var programName: String?
    var programStartDate: Date?
    var programStartDateActive = true
    var programEndDate: Date?
    var programEndDateActive = true
    
    var selectedIndexPath: IndexPath?
    var workoutProgram: WorkoutProgram?
    
    let dataLoader = DataLoader.shared

    // MARK: View Lifecycle
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == ADD_PROGRAM_EXERCISE_SEGUE {
            let vc = segue.destination as! SelectExerciseTableViewController
            vc.delegate = self
        }
    }
    
    func saveDataContext() {
        dataLoader.saveContext()
        navigationController?.popViewController(animated: true)
    }
    
    @objc func saveProgram() {
        if let program = workoutProgram {
            
        } else {
            let newProgram = dataLoader.createNewWorkoutProgram()
            newProgram.name = self.programName
            newProgram.start = self.programStartDateActive ? self.programStartDate : nil
            newProgram.end = self.programEndDateActive ? self.programEndDate : nil
            newProgram.plans = NSSet(array: workoutPlans)
            saveDataContext()
        }
    }
    
    @objc func exit() {
        navigationController?.popViewController(animated: true)
    }
    
    func setupView() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveProgram))
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(exit))
        
        // Enable large titles
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        
        if let program = self.workoutProgram {
            title = "Edit Program"
        } else {
            title = "Create Program"
        }
        
        self.tableView.register(UINib(nibName: "TextFieldTableViewCell", bundle: nil), forCellReuseIdentifier: NAME_CELL_IDENTIFIER)
        self.tableView.register(UINib(nibName: "DatePickerTableViewCell", bundle: nil), forCellReuseIdentifier: DATE_CELL_IDENTIFIER)
        self.tableView.register(UINib(nibName: "WorkoutPlanTableViewCell", bundle: nil), forCellReuseIdentifier: WORKOUT_PLAN_CELL_IDENTIFIER)
        self.tableView.register(UINib(nibName: "ButtonTableViewCell", bundle: nil), forCellReuseIdentifier: ADD_WORKOUT_CELL_IDENTIFIER)
        
        self.tableView.separatorStyle = .none
    }
    
    @objc func addExercisePressed() {
        performSegue(withIdentifier: ADD_PROGRAM_EXERCISE_SEGUE, sender: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupView()
    }
    
    // MARK: Tableview
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
            return "Program Name"
        case START_DATE_SECTION:
            return "Start Date"
        case END_DATE_SECTION:
            return "End Date"
        case ADD_WORKOUT_SECTION:
            return "Workout Plan"
        default:
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case NAME_SECTION:
            let cell = tableView.dequeueReusableCell(withIdentifier: NAME_CELL_IDENTIFIER, for: indexPath) as! TextFieldTableViewCell
            cell.textField.delegate = self
            return cell
        case START_DATE_SECTION:
            let cell = tableView.dequeueReusableCell(withIdentifier: DATE_CELL_IDENTIFIER, for: indexPath) as! DatePickerTableViewCell
            cell.datePicker.tag = START_DATE_SECTION
            cell.dateSwitch.tag = START_DATE_SECTION
            cell.datePicker.addTarget(self, action: #selector(datePickerChanged), for: .valueChanged)
            cell.dateSwitch.addTarget(self, action: #selector(switchChanged), for: .valueChanged)
            return cell
        case END_DATE_SECTION:
            let cell = tableView.dequeueReusableCell(withIdentifier: DATE_CELL_IDENTIFIER, for: indexPath) as! DatePickerTableViewCell
            cell.datePicker.tag = END_DATE_SECTION
            cell.dateSwitch.tag = END_DATE_SECTION
            cell.datePicker.addTarget(self, action: #selector(datePickerChanged), for: .valueChanged)
            cell.dateSwitch.addTarget(self, action: #selector(switchChanged), for: .valueChanged)
            return cell
        case ADD_WORKOUT_SECTION:
            let cell = tableView.dequeueReusableCell(withIdentifier: ADD_WORKOUT_CELL_IDENTIFIER, for: indexPath) as! ButtonTableViewCell
            cell.button.addTarget(self, action: #selector(addExercisePressed), for: .touchUpInside)
            return cell
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: WORKOUT_PLAN_CELL_IDENTIFIER, for: indexPath) as! WorkoutPlanTableViewCell
            let plan = workoutPlans[indexPath.row]
            cell.exerciseLabel.text = plan.exercise?.name ?? "Exercise Name"
            cell.setWorkoutCount(plan.numWorkouts)
            cell.workoutCountSlider.tag = indexPath.row
            cell.workoutCountSlider.addTarget(self, action: #selector(sliderChanged), for: .valueChanged)
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let plan = self.workoutPlans[indexPath.row]
            dataLoader.deleteWorkoutPlan(plan)
            dataLoader.saveContext()
            self.workoutPlans.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
            return "Delete Workout"
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if indexPath.section == WORKOUT_PLAN_SECTION {
            return true
        }
        return false
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == WORKOUT_PLAN_SECTION {
            self.selectedIndexPath = indexPath
            self.performSegue(withIdentifier: ADD_PROGRAM_EXERCISE_SEGUE, sender: nil)
        }
    }
    
    // MARK: Utilities
    
    func basicAlertController(title: String, message: String) -> UIAlertController {
        let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .cancel))
        return ac
    }
    
    // MARK: Actions
    
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
