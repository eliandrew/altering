import UIKit

class EditExerciseTableViewController: UITableViewController {
    
    // MARK: Constants
    let WORKOUT_CELL_IDENTIFIER = "workoutNotesCell"
    let NAME_CELL_IDENTIFIER = "nameCell"
    let DATE_CELL_IDENTIFIER = "dateCell"
    let GROUP_CELL_IDENTIFIER = "groupCell"
    
    
    let SELECT_GROUP_SEGUE_IDENTIFIER = "selectGroupSegue"
    
    enum EditExerciseSection: Int {
        case name = 0
        case group = 1
        case workouts = 2
        case numSections = 3
    }
    
    // MARK: Properties
    var exercise: Exercise?
    var existingExerciseNames: [String?]?
    
    var exerciseName: String?
    var exerciseGroup: ExerciseGroup?
    var workouts: [Workout]?
    
    let dataLoader = DataLoader.shared
    
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
        dataLoader.saveContext()
        navigationController?.popViewController(animated: true)
    }
    
    @objc func saveExercise() {
        if isExistingName(name: exerciseName) {
            present(basicAlertController(title: "Duplicate Exercise Name", message: "Exercise must have unique name"), animated: true)
            return
        }
        if let exercise = exercise {
            guard let name = exerciseName, name != "" else {
                present(basicAlertController(title: "Missing Exercise Name", message: "Exercise must have a name"), animated: true)
                return
            }
            exercise.name = name
            exercise.group = self.exerciseGroup
            saveDataContext()
        } else {
            guard let name = exerciseName else {
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
        navigationController?.popViewController(animated: true)
    }
    
    // MARK: View Lifecycle
    
    func setupView() {
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveExercise))
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(exit))
        
        // Enable large titles
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        self.tableView.separatorStyle = .none
        
        self.tableView.register(UINib(nibName: "WorkoutNotesTableViewCell", bundle: nil), forCellReuseIdentifier: WORKOUT_CELL_IDENTIFIER)
        self.tableView.register(UINib(nibName: "TextFieldTableViewCell", bundle: nil), forCellReuseIdentifier: NAME_CELL_IDENTIFIER)
        self.tableView.register(UINib(nibName: "DatePickerTableViewCell", bundle: nil), forCellReuseIdentifier: DATE_CELL_IDENTIFIER)
        self.tableView.register(UINib(nibName: "ButtonTableViewCell", bundle: nil), forCellReuseIdentifier: GROUP_CELL_IDENTIFIER)
        
        if let exercise = self.exercise {
            dataLoader.loadWorkouts(for: exercise) { result in
                switch result {
                case .success(let fetchedWorkouts):
                    self.workouts = fetchedWorkouts
                    self.tableView.reloadData()
                case .failure(let error):
                    print("Error fetching workouts: \(error)")
                }
            }
            title = "Edit Exercise"
        } else {
            self.workouts = nil
            self.tableView.reloadData()
            
            title = "Create Exercise"
        }
        
        exerciseName = self.exercise?.name
        self.exerciseGroup = self.exercise?.group
//        self.setGroupTitle(self.exercise?.group?.name ?? "None")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    @objc func groupButtonPressed() {
        self.performSegue(withIdentifier: SELECT_GROUP_SEGUE_IDENTIFIER, sender: nil)
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
        switch EditExerciseSection(rawValue: indexPath.section) {
        case .name:
            let cell = tableView.dequeueReusableCell(withIdentifier: NAME_CELL_IDENTIFIER, for: indexPath)
            if let textFieldCell = cell as? TextFieldTableViewCell {
                textFieldCell.textField.placeholder = "e.g. DB Bench Press"
                textFieldCell.textField.text = exerciseName
                textFieldCell.textField.delegate = self
            }
            return cell
        case .group:
            let cell = tableView.dequeueReusableCell(withIdentifier: GROUP_CELL_IDENTIFIER, for: indexPath)
            if let groupCell = cell as? ButtonTableViewCell {
                let title = self.exerciseGroup?.name ?? (self.exercise?.group?.name ?? "None")
                groupCell.button.setImage(nil, for: .normal)
                groupCell.button.setTitle(title, for: .normal)
                groupCell.button.setImage(nil, for: .highlighted)
                groupCell.button.setTitle(title, for: .highlighted)
                groupCell.button.setImage(nil, for: .selected)
                groupCell.button.setTitle(title, for: .selected)
                groupCell.button.setImage(nil, for: .focused)
                groupCell.button.setTitle(title, for: .focused)
                groupCell.button.addTarget(self, action: #selector(groupButtonPressed), for: .touchUpInside)
                return cell
            }
            return cell
        case .workouts:
            let cell = tableView.dequeueReusableCell(withIdentifier: WORKOUT_CELL_IDENTIFIER, for: indexPath)
            if let notesViewCell = cell as? WorkoutNotesTableViewCell, let workout = workouts?[indexPath.row] {
                notesViewCell.dateLabel.text = standardDateTitle(workout.date, referenceDate: Date.now, reference: .ago)
                notesViewCell.notesTextView.text = workout.notes
                notesViewCell.notesTextView.isEditable = false
                notesViewCell.notesTextView.isScrollEnabled = false
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
        case .workouts:
            let workoutCount = workouts?.count ?? 0
            let title = "\(workoutCount == 0 ? "No" : "\(workoutCount)") Workout\(workoutCount == 1 ? "" : "s")"
            return title
        default:
            return nil
        }
    }
}
