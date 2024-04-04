import UIKit

class EditExerciseViewController: UIViewController {
    
    // MARK: Constants
    let WORKOUT_CELL_IDENTIFIER = "workoutNotesCell"
    
    let SELECT_GROUP_SEGUE_IDENTIFIER = "selectGroupSegue"
    
    // MARK: Outlets
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var workoutLabel: UILabel!
    @IBOutlet weak var groupButton: UIButton!
    @IBOutlet weak var workoutTableView: UITableView!
    
    
    // MARK: Properties
    var exercise: Exercise?
    var existingExerciseNames: [String?]?
    
    var exerciseGroup: ExerciseGroup?
    
    let dataLoader = DataLoader.shared
    let workoutDataSource = WorkoutTableViewDataSource()
    
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
        if isExistingName(name: nameTextField.text) {
            present(basicAlertController(title: "Duplicate Exercise Name", message: "Exercise must have unique name"), animated: true)
            return
        }
        if let exercise = exercise {
            guard let name = nameTextField.text else {
                present(basicAlertController(title: "Missing Exercise Name", message: "Exercise must have a name"), animated: true)
                return
            }
            exercise.name = name
            exercise.group = self.exerciseGroup
            saveDataContext()
        } else {
            guard let name = nameTextField.text else {
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
    
    func setGroupTitle(_ title: String?) {
        self.groupButton.setTitle(title, for: .normal)
        self.groupButton.setTitle(title, for: .highlighted)
        self.groupButton.setTitle(title, for: .selected)
        self.groupButton.setTitle(title, for: .focused)
    }
    
    func randomBackgroundImage() -> UIImage? {
        let images = [
            "figure.core.training",
            "figure.mixed.cardio",
            "figure.pilates",
            "figure.rolling",
            "figure.cross.training",
            "figure.indoor.cycle",
            "figure.outdoor.cycle",
            "figure.yoga",
            "figure.jumprope",
            "figure.mind.and.body",
            "dumbbell",
            "figure.stair.stepper",
            "figure.play",
            "figure.step.training",
            "figure.flexibility"
        ]
        
        return UIImage(systemName: images.randomElement() ?? "dumbbell")
    }

    func tableViewBackgroundView() -> UIView {
        let backgroundView = UIView(frame: self.workoutTableView.bounds)
        let backgroundImage = self.randomBackgroundImage()
        let backgroundImageView = UIImageView(image: backgroundImage)
        let scaleFactor: CGFloat = 0.2 // Adjust the scale factor as needed
        backgroundImageView.frame = CGRect(x: 0, y: 0, width: backgroundView.bounds.width * scaleFactor, height: backgroundView.bounds.height * scaleFactor)
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.center = backgroundView.center
        backgroundView.addSubview(backgroundImageView)
        return backgroundView
    }
    
    func setupView() {
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveExercise))
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(exit))
        
        self.workoutTableView.dataSource = self
        self.workoutTableView.register(UINib(nibName: "WorkoutNotesTableViewCell", bundle: nil), forCellReuseIdentifier: WORKOUT_CELL_IDENTIFIER)
        
        if let exercise = self.exercise {
            dataLoader.loadWorkoutsFor(exercise) { fetchedWorkouts in
                if let fetchedWorkouts = fetchedWorkouts {
                    let workoutCount = fetchedWorkouts.count
                    self.workoutDataSource.setWorkouts(fetchedWorkouts)
                    DispatchQueue.main.sync {
                        if workoutCount == 0 {
                            self.workoutTableView.backgroundView = self.tableViewBackgroundView()
                        }
                        self.workoutLabel.text = "\(workoutCount == 0 ? "No" : "\(fetchedWorkouts.count)") Workout\(workoutCount == 1 ? "" : "s")"
                        self.workoutTableView.reloadData()
                    }
                }
            }
        } else {
            self.workoutDataSource.setWorkouts([Workout]())
            self.workoutTableView.backgroundView = self.tableViewBackgroundView()
            self.workoutTableView.reloadData()
        }
        
        self.nameTextField.text = self.exercise?.name
        self.exerciseGroup = self.exercise?.group
        self.setGroupTitle(self.exercise?.group?.name ?? "None")
        
        self.nameTextField.delegate = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    // MARK: Segues
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == SELECT_GROUP_SEGUE_IDENTIFIER {
            let vc = segue.destination as? SelectGroupTableViewController
            vc?.delegate = self
        }
    }
}

extension EditExerciseViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

extension EditExerciseViewController: SelectGroupDelegate {
    func didSelectGroup(_ exerciseGroup: ExerciseGroup) {
        self.exerciseGroup = exerciseGroup
        self.setGroupTitle(self.exerciseGroup?.name ?? "None")
    }
}

extension EditExerciseViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.workoutDataSource.numberOfSections(tableView)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.workoutDataSource.numberOfRowsInSection(tableView, section: section)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: WORKOUT_CELL_IDENTIFIER, for: indexPath)
        if let notesViewCell = cell as? WorkoutNotesTableViewCell, let workout = self.workoutDataSource.workoutForIndexPath(indexPath) {
            notesViewCell.notesTextView.text = workout.notes
            return notesViewCell
        } else {
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.workoutDataSource.titleForSection(section)
    }
}
