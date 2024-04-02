import UIKit

class ExerciseTableViewController: UITableViewController {
    
    // MARK: Constants
    
    let EXERCISE_CELL_IDENTIFIER = "exerciseCell"
    
    let EDIT_EXERCISE_SEGUE_IDENTIFIER = "editExerciseSegue"
    let ADD_EXERCISE_SEGUE_IDENTIFIER = "addExerciseSegue"
    
    // MARK: Actions
    
    @objc func addExercise() {
        performSegue(withIdentifier: ADD_EXERCISE_SEGUE_IDENTIFIER, sender: nil)
    }
    
    // MARK: Properties
    
    var exercises = [Exercise]()
    let dataLoader = DataLoader.shared
    
    // MARK: Helpers
    
    func exerciseForIndexPath(_ indexPath: IndexPath) -> Exercise {
        return self.exercises[indexPath.row]
    }
    
    // MARK: View Lifecycle
    
    func setupView() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addExercise))
        
        dataLoader.loadAllExercises { fetchedExercises in
            if let fetchedExercises = fetchedExercises {
                self.exercises = fetchedExercises
                DispatchQueue.main.sync {
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupView()
    }
    
    // MARK: UITableViewDelegate
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.exercises.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let exercise = exerciseForIndexPath(indexPath)
        
        let cell = tableView.dequeueReusableCell(withIdentifier: EXERCISE_CELL_IDENTIFIER, for: indexPath)
        var content = UIListContentConfiguration.cell()
        content.text = exercise.name ?? "Missing Name"
        content.textProperties.font = UIFont.systemFont(ofSize: 20)
        content.secondaryText = "Exercise Group"
        content.secondaryTextProperties.font = UIFont.systemFont(ofSize: 15)
        cell.contentConfiguration = content
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let exercise = exerciseForIndexPath(indexPath)
        performSegue(withIdentifier: EDIT_EXERCISE_SEGUE_IDENTIFIER, sender: exercise)
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let exercise = exerciseForIndexPath(indexPath)
            dataLoader.deleteExercise(exercise)
            if dataLoader.saveContext() {
                self.exercises.remove(at: indexPath.row)
                self.tableView.deleteRows(at: [indexPath], with: .automatic)
            }
        }
    }
    
    // MARK: Segues
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == EDIT_EXERCISE_SEGUE_IDENTIFIER {
            if let exercise = sender as? Exercise {
                let vc = segue.destination as? EditExerciseTableViewController
                vc?.exercise = exercise
                vc?.existingExerciseNames = self.exercises.map({ exercise in
                    exercise.name
                })
            }
        } else if segue.identifier == ADD_EXERCISE_SEGUE_IDENTIFIER {
            let vc = segue.destination as? EditExerciseTableViewController
            vc?.existingExerciseNames = self.exercises.map({ exercise in
                exercise.name
            })
        }
    }
    
}

