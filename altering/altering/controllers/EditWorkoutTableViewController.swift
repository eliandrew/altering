import UIKit

class EditWorkoutTableViewController: UITableViewController {

    // MARK: Constants
    
    let PREVIOUS_NOTES_SECTION = 3
    let SELECT_EXERCISE_SEGUE = "selectExerciseSegue"
    
    // MARK: Outlets
    
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var exerciseLabel: UILabel!
    @IBOutlet weak var currentNotesTextView: UITextView!
    @IBOutlet weak var previousNotesTextView: UITextView!
    
    // MARK: Properties
    
    var workoutDataSource = WorkoutTableViewDataSource()
    
    var workout: Workout?
    var exercise: Exercise?
    var previousWorkout: Workout?
    
    let dataLoader = DataLoader.shared
    
    // MARK: Actions
    
    @objc func dateChanged() {
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
        dataLoader.loadPreviousWorkout(exercise, date: date, completion: { w in
            self.previousWorkout = w
            DispatchQueue.main.sync {
                self.tableView.reloadData()
                if self.currentNotesTextView.text.isEmpty {
                    self.currentNotesTextView.text = self.previousWorkout?.notes
                }
                self.previousNotesTextView.text = self.previousWorkout?.notes
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
        
        if let exercise = workout?.exercise, let date = workout?.date, let notes = workout?.notes {
            self.exercise = exercise
            self.datePicker.date = date
            self.exerciseLabel.text = self.exercise?.name ?? "None"
            self.currentNotesTextView.text = notes
            self.loadPreviousWorkout(exercise, date: date)
        } else {
            self.datePicker.date = Date()
            self.exerciseLabel.text = "None"
            self.currentNotesTextView.text = nil
            self.previousNotesTextView.text = nil
        }
    }
    
    @objc func saveWorkout() {
        
        if let workout = workout {
            workout.date = datePicker.date
            workout.notes = self.currentNotesTextView.text
            workout.exercise = self.exercise
            saveDataContext()
        } else {
            guard let exercise = self.exercise else {
                present(basicAlertController(title: "Missing Exercise", message: "Workout must have an Exercise"), animated: true)
                return
            }
            let newWorkout = dataLoader.createNewWorkout()
            newWorkout.date = self.datePicker.date
            newWorkout.exercise = exercise
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
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Date"
        case 1:
            return "Exercise"
        case 2:
            return "Notes"
        case 3:
            if let date = previousWorkout?.date, let title = self.workoutDataSource.dateTitleFrom(date){
                return "Previously On \(title)"
            } else {
                return "Previous Notes"
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
