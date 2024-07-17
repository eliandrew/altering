import UIKit

protocol EditWorkoutDelegate {
    func didUpdateWorkoutProgram(_ workout: Workout)
}

class EditWorkoutTableViewController: UITableViewController {
    
    enum EditWorkoutTableViewSection: Int {
        case date = 0
        case exercise = 1
        case program = 2
        case notes = 3
        case workouts = 4
        case numSections = 5
    }

    // MARK: Constants
    
    let PREVIOUS_NOTES_SECTION = 3
    let SELECT_EXERCISE_SEGUE = "selectExerciseSegue"
    let SELECT_WORKOUT_PROGRAM_SEGUE = "selectWorkoutProgramSegue"
    
    let DATE_CELL_IDENTIFIER = "dateCell"
    let BUTTON_CELL_IDENTIFIER = "buttonCell"
    let BASIC_CELL_IDENTIFIER = "basicCell"
    let WORKOUT_CELL_IDENTIFIER = "workoutCell"
    
    // MARK: Outlets
    
    // MARK: Properties
    
    var delegate: EditWorkoutDelegate?
    
    var workoutDataSource = WorkoutTableViewDataSource()
    
    var workout: Workout?
    var exercise: Exercise?
    var program: WorkoutProgram?
    var previousWorkouts: [Workout]?
    var currentNotes: String?
    
    var selectedDate: Date?
    var originalWorkoutProgram: WorkoutProgram?
    
    let dataLoader = DataLoader.shared
    
    // MARK: Actions
    
    @objc func dateChanged(_ sender: Any?) {
        if let datePicker = sender as? UIDatePicker {
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
    
    func saveDataContext() {
        dataLoader.saveContext()
        navigationController?.popViewController(animated: true)
    }
    
    func setupView() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveWorkout))
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(exit))

        self.tableView.register(UINib(nibName: "DatePickerTableViewCell", bundle: nil), forCellReuseIdentifier: DATE_CELL_IDENTIFIER)
        self.tableView.register(UINib(nibName: "ButtonTableViewCell", bundle: nil), forCellReuseIdentifier: BUTTON_CELL_IDENTIFIER)
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: BASIC_CELL_IDENTIFIER)
        self.tableView.register(UINib(nibName: "WorkoutNotesTableViewCell", bundle: nil), forCellReuseIdentifier: WORKOUT_CELL_IDENTIFIER)
        
        self.tableView.separatorStyle = .none
        
        // Enable large titles
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        tableView.tableFooterView = nil
        
        if let workout = workout {
            self.exercise = exercise ?? workout.exercise
            self.program = program ?? workout.program
            self.selectedDate = workout.date
            self.currentNotes = workout.notes
            if let exercise {
                self.loadPreviousWorkouts(exercise, date: self.selectedDate ?? Date.now)
            }
            
            // Set the title for the large title
            title = "Edit Workout"
        } else {
            title = "Create Workout"
            
            self.selectedDate = self.selectedDate ?? Date.now
        }
    }
    
    @objc func saveWorkout() {
        
        if let workout = workout {
            workout.date = self.selectedDate
            workout.notes = self.currentNotes
            workout.exercise = self.exercise
            workout.program = self.program
            saveDataContext()
            if let newProgram = workout.program, originalWorkoutProgram != newProgram {
                self.delegate?.didUpdateWorkoutProgram(workout)
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
            saveDataContext()
            if let _ = self.program {
                self.delegate?.didUpdateWorkoutProgram(newWorkout)
            }
        }
       
    }
    
    @objc func exit() {
        self.navigationController?.popViewController(animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupView()
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch EditWorkoutTableViewSection(rawValue: indexPath.section) {
        case .date:
            let cell = tableView.dequeueReusableCell(withIdentifier: DATE_CELL_IDENTIFIER, for: indexPath)
            if let dateCell = cell as? DatePickerTableViewCell {
                dateCell.dateSwitch.isHidden = true
                dateCell.datePicker.setDate(self.selectedDate ?? Date.now, animated: false)
                dateCell.datePicker.addTarget(self, action: #selector(dateChanged), for: .valueChanged)
            }
            return cell
        case .exercise:
            let cell = tableView.dequeueReusableCell(withIdentifier: BASIC_CELL_IDENTIFIER, for: indexPath)
            cell.imageView?.image = UIImage(systemName: "dumbbell.fill")
            cell.textLabel?.text = exercise?.name ?? "None"
            cell.textLabel?.numberOfLines = 0
            cell.accessoryType = .disclosureIndicator
            return cell
        case .program:
            let cell = tableView.dequeueReusableCell(withIdentifier: BASIC_CELL_IDENTIFIER, for: indexPath)
            if indexPath.row == 0 {
                cell.imageView?.image = UIImage(systemName: "doc.text.fill")
                cell.textLabel?.text = self.program?.name ?? "None"
                cell.textLabel?.numberOfLines = 0
                cell.accessoryType = .disclosureIndicator
            } else {
                cell.imageView?.image = UIImage(systemName: "minus.circle")
                cell.imageView?.tintColor = .systemRed
                cell.textLabel?.text = "Remove Plan"
                cell.textLabel?.textColor = .systemRed
                cell.accessoryType = .none
            }
            return cell
        case .notes:
            let cell = tableView.dequeueReusableCell(withIdentifier: WORKOUT_CELL_IDENTIFIER, for: indexPath)
            if let notesViewCell = cell as? WorkoutNotesTableViewCell {
                notesViewCell.dateLabel.text = "Current Workout"
                notesViewCell.notesTextView.text = self.currentNotes
                notesViewCell.notesTextView.delegate = self
                notesViewCell.notesTextView.backgroundColor = .secondarySystemBackground
                notesViewCell.notesTextView.isEditable = true
                notesViewCell.notesTextView.isScrollEnabled = true
            }
            return cell
        case .workouts:
            let cell = tableView.dequeueReusableCell(withIdentifier: WORKOUT_CELL_IDENTIFIER, for: indexPath)
            if let notesViewCell = cell as? WorkoutNotesTableViewCell {
                let workout = previousWorkouts?[indexPath.row]
                notesViewCell.dateLabel.text = standardDateTitle(workout?.date, referenceDate: self.workout?.date ?? Date.now, reference: .before)
                notesViewCell.notesTextView.text = workout?.notes
                notesViewCell.notesTextView.isEditable = false
                notesViewCell.notesTextView.isScrollEnabled = false
                notesViewCell.notesTextView.backgroundColor = .systemBackground
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
        case .workouts:
            return UITableView.automaticDimension
        default:
            return UITableView.automaticDimension
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
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
                self.program = nil
                tableView.reloadRows(at: [IndexPath(row: 0, section: EditWorkoutTableViewSection.program.rawValue)], with: .automatic)
            }
            return
        case .notes:
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
    func textViewDidChange(_ textView: UITextView) {
        self.currentNotes = textView.text
    }
}
