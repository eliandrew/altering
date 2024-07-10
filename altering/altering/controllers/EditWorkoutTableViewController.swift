import UIKit

class EditWorkoutTableViewController: UITableViewController {

    // MARK: Constants
    
    let PREVIOUS_NOTES_SECTION = 3
    let SELECT_EXERCISE_SEGUE = "selectExerciseSegue"
    let SELECT_WORKOUT_PROGRAM_SEGUE = "selectWorkoutProgramSegue"
    
    // MARK: Outlets
    
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var exerciseLabel: UILabel!
    @IBOutlet weak var programLabel: UILabel!
    @IBOutlet weak var currentNotesTextView: UITextView!
    @IBOutlet weak var previousNotesTextView: UITextView!
    
    // MARK: Properties
    
    var workoutDataSource = WorkoutTableViewDataSource()
    
    var workout: Workout?
    var exercise: Exercise?
    var program: WorkoutProgram?
    var previousWorkout: Workout?
    
    var selectedDate: Date?
    
    let dataLoader = DataLoader.shared
    
    // MARK: Actions
    
    @objc func dateChanged() {
        self.selectedDate = self.datePicker.date
        if let exercise = self.exercise {
            self.loadPreviousWorkout(exercise, date: datePicker.date)
        }
    }
    
    func basicAlertController(title: String, message: String) -> UIAlertController {
        let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .cancel))
        return ac
    }
    
    func loadPreviousWorkout(_ exercise: Exercise, date: Date) {
        dataLoader.loadPreviousWorkout(for: exercise, before: date, completion: { result in
            switch result {
                case .success(let previousWorkout):
                    self.previousWorkout = previousWorkout
                    if self.currentNotesTextView.text.isEmpty {
                        self.currentNotesTextView.text = self.previousWorkout?.notes
                    }
                    self.previousNotesTextView.text = self.previousWorkout?.notes
                    self.exerciseLabel.text = self.exercise?.name
                    self.programLabel.text = self.program?.name ?? "None"
                    self.datePicker.date = self.selectedDate ?? Date()
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
        
        self.datePicker.addTarget(self, action: #selector(dateChanged), for: .valueChanged)
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveWorkout))
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(exit))

        // Enable large titles
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        tableView.tableFooterView = nil
        
        if let workout = workout, let exercise = workout.exercise, let date = workout.date, let notes = workout.notes {
            self.exercise = exercise
            self.program = program ?? workout.program
            self.datePicker.date = date
            self.programLabel.text = workout.program?.name ?? "None"
            self.exerciseLabel.text = self.exercise?.name ?? "None"
            self.currentNotesTextView.text = notes
            self.loadPreviousWorkout(exercise, date: date)
            
            // Set the title for the large title
            title = "Edit Workout"
        } else {
            self.datePicker.date = self.selectedDate ?? Date()
            self.exerciseLabel.text = self.exercise?.name ?? "None"
            self.programLabel.text = self.program?.name ?? "None"
            self.currentNotesTextView.text = nil
            self.previousNotesTextView.text = nil
            
            // Set the title for the large title
            title = "Create Workout"
        }
        
        self.selectedDate = self.datePicker.date
    }
    
    @objc func saveWorkout() {
        
        if let workout = workout {
            workout.date = datePicker.date
            workout.notes = self.currentNotesTextView.text
            workout.exercise = self.exercise
            workout.program = self.program
            saveDataContext()
        } else {
            guard let exercise = self.exercise else {
                present(basicAlertController(title: "Missing Exercise", message: "Workout must have an Exercise"), animated: true)
                return
            }
            let newWorkout = dataLoader.createNewWorkout()
            newWorkout.date = self.datePicker.date
            newWorkout.exercise = exercise
            newWorkout.program = self.program
            newWorkout.notes = self.currentNotesTextView.text
            saveDataContext()
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
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 && indexPath.row == 1 {
            self.program = nil
            self.programLabel.text = "None"
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Date"
        case 1:
            return "Program"
        case 2:
            return "Exercise"
        case 3:
            return "Notes"
        case 4:
            if let date = previousWorkout?.date, let title = self.workoutDataSource.dateTitleFrom(date){
                if let dayDifference = self.workoutDataSource.daysBetween(start: date, end: self.datePicker.date) {
                    return "\(title) (\(dayDifference) day\(dayDifference == 1 ? "" : "s") before)"
                } else {
                    return "On \(title)"
                }
            } else {
                return "No Previous Workouts"
            }
        default:
            return ""
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
        self.exerciseLabel.text = exercise.name ?? "None"
        self.loadPreviousWorkout(exercise, date: datePicker.date)
    }
}

extension EditWorkoutTableViewController: SelectWorkoutProgramDelegate {
    
    func didSelectWorkoutProgram(_ program: WorkoutProgram) {
        self.program = program
        self.programLabel.text = program.name ?? "None"
    }
}
