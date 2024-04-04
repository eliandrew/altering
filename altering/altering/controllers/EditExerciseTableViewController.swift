import UIKit

class EditExerciseTableViewController: UITableViewController {
    
    // MARK: Constants
    
    let SELECT_GROUP_SEGUE_IDENTIFIER = "selectGroupSegue"
    
    // MARK: Outlets
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var groupLabel: UILabel!
    
    // MARK: Properties
    var exercise: Exercise?
    var existingExerciseNames: [String?]?
    
    var exerciseGroup: ExerciseGroup?
    
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

    func setupView() {
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveExercise))
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(exit))
        
        
        self.nameTextField.text = self.exercise?.name
        self.groupLabel.text = self.exercise?.group?.name ?? "None"
        self.exerciseGroup = self.exercise?.group
        
        self.nameTextField.delegate = self
        
        self.tableView.delaysContentTouches = false
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
    
    // MARK: Table View
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension EditExerciseTableViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

extension EditExerciseTableViewController: SelectGroupDelegate {
    func didSelectGroup(_ exerciseGroup: ExerciseGroup) {
        self.exerciseGroup = exerciseGroup
        self.groupLabel.text = self.exerciseGroup?.name ?? "None"
    }
}
