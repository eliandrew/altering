import UIKit

class WorkoutProgramTableViewController: UITableViewController {
    
    let EDIT_WORKOUT_PROGRAM_SEGUE_IDENTIFIER = "editWorkoutProgramSegue"
    let WORKOUT_PROGRAM_CELL_IDENTIFIER = "workoutProgramCellIdentifier"
    let WORKOUT_PROGRAM_HEADER_VIEW_IDENTIFIER = "workoutProgramHeaderViewIdentifier"
    
    var programDataSource = WorkoutProgramTableViewDataSource()
    
    let dataLoader = DataLoader.shared
    
    // MARK: View Lifecycle
    
    @objc func addProgram() {
        self.performSegue(withIdentifier: EDIT_WORKOUT_PROGRAM_SEGUE_IDENTIFIER, sender: nil)
    }
    
    func setupView() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addProgram))
        
        self.tableView.register(UINib(nibName: "WorkoutProgramTableViewCell", bundle: nil), forCellReuseIdentifier: WORKOUT_PROGRAM_CELL_IDENTIFIER)
        
        tableView.register(UINib(nibName: "ButtonHeaderView", bundle: nil), forHeaderFooterViewReuseIdentifier: WORKOUT_PROGRAM_HEADER_VIEW_IDENTIFIER)
        
        // Set the title for the large title
        title = "Programs"

        // Enable large titles
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        tableView.tableFooterView = nil
        
        dataLoader.loadAllWorkoutPrograms(completion: { result in
            switch result {
            case .success(let fetchedPrograms):
                self.programDataSource.setPrograms(fetchedPrograms)
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            case .failure(let error):
                print("Error fetching programs: \(error)")
                self.programDataSource.setPrograms([])
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
        })
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.setupView()
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.programDataSource.numberOfSections(tableView)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.programDataSource.numberOfRowsInSection(tableView, section: section)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return self.programDataSource.cellForRowAtIndexPath(tableView, indexPath: indexPath)
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40.0
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: WORKOUT_PROGRAM_HEADER_VIEW_IDENTIFIER) as? ButtonHeaderView
        headerView?.title.text = self.programDataSource.titleForSection(section)
        headerView?.button.tag = section
        headerView?.button.addTarget(self, action: #selector(removeProgramPressed), for: .touchUpInside)
        return headerView
    }
    
    // MARK - Actions
    @objc func removeProgramPressed(_ sender: Any?) {
        if let sender = sender as? UIButton {
            showAlert(title: "Delete Program", message: "Are you sure you want to delete this program?") {
                let index = sender.tag
                let program = self.programDataSource.programs[index]
                self.dataLoader.deleteWorkoutProgram(program)
                self.dataLoader.saveContext()
                self.programDataSource.removeProgram(at: index)
                self.tableView.deleteSections(IndexSet(integer: index), with: .automatic)
                self.tableView.reloadData()
            }
        }
    }
    
    func showAlert(title: String, message: String, okActionCompletion: @escaping () -> Void) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        // OK button
        let okAction = UIAlertAction(title: "Delete", style: .destructive) { (action) in
            okActionCompletion()
        }
        
        // Cancel button
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
            // Handle the Cancel action here if needed
        }
        
        // Add the actions to the alert controller
        alertController.addAction(okAction)
        alertController.addAction(cancelAction)
        
        // Present the alert controller
        present(alertController, animated: true, completion: nil)
    }

    
}
