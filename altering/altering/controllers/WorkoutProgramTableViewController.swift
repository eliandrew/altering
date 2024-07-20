import UIKit

class WorkoutProgramTableViewController: UITableViewController {
    
    let EDIT_WORKOUT_PROGRAM_SEGUE_IDENTIFIER = "editWorkoutProgramSegue"
    let WORKOUT_PROGRAM_CELL_IDENTIFIER = "workoutProgramCellIdentifier"
    let WORKOUT_PROGRAM_HEADER_VIEW_IDENTIFIER = "workoutProgramHeaderViewIdentifier"
    
    let WORKOUT_PLAN_SEGUE = "workoutPlanSegue"
    
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
                    self.updateBackgroundView()
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
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        self.performSegue(withIdentifier: WORKOUT_PLAN_SEGUE, sender: indexPath)
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: WORKOUT_PROGRAM_HEADER_VIEW_IDENTIFIER) as? ButtonHeaderView
        headerView?.title.text = self.programDataSource.titleForSection(section)
        headerView?.buttonRight.tag = section
        headerView?.buttonRight.addTarget(self, action: #selector(removeProgramPressed), for: .touchUpInside)
        headerView?.buttonCenter.tag = section
        headerView?.buttonCenter.addTarget(self, action: #selector(editProgramPressed), for: .touchUpInside)
        headerView?.buttonLeft.isHidden = !(self.programDataSource.programForIndexPath(IndexPath(row: 0, section: section))?.isComplete() ?? false)
        return headerView
    }
    
    @objc func backgroundTapped() {
        self.performSegue(withIdentifier: EDIT_WORKOUT_PROGRAM_SEGUE_IDENTIFIER, sender: self)
    }
    
    func createBackgroundView() -> UIView {
        let backgroundView = UIView(frame: UIScreen.main.bounds)

        // Create the image view
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(systemName: "doc.text.fill")
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true

        // Create and add the tap gesture recognizer
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped))
        backgroundView.addGestureRecognizer(tapGestureRecognizer)

        // Create the label
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Tap for your first Program!"
        label.textColor = .systemBlue
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 20, weight: .semibold)

        // Add the image view and label to the background view
        backgroundView.addSubview(imageView)
        backgroundView.addSubview(label)

        // Center the image view and set its size
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: backgroundView.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: backgroundView.centerYAnchor, constant: -20),
            imageView.widthAnchor.constraint(equalToConstant: 100), // Adjust the width
            imageView.heightAnchor.constraint(equalToConstant: 100) // Adjust the height
        ])

        // Center the label below the image view
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: backgroundView.centerXAnchor),
            label.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 10)
        ])

        return backgroundView
    }
    
    func updateBackgroundView() {
        if self.programDataSource.programs.count == 0 {
                tableView.backgroundView = createBackgroundView()
            } else {
                tableView.backgroundView = nil
            }
        }
    
    // MARK - Actions
    @objc func editProgramPressed(_ sender: Any?) {
        if let sender = sender as? UIButton {
            let index = sender.tag
            let program = self.programDataSource.programs[index]
            self.performSegue(withIdentifier: EDIT_WORKOUT_PROGRAM_SEGUE_IDENTIFIER, sender: program)
        }
    }
    
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == WORKOUT_PLAN_SEGUE {
            let vc = segue.destination as? WorkoutPlanTableViewController
            if let indexPath = sender as? IndexPath, let plan = self.programDataSource.planForIndexPath(indexPath), let program = self.programDataSource.programForIndexPath(indexPath), let workouts = program.workoutsForPlan(plan) {
                vc?.workoutPlan = plan
                vc?.program = program
                vc?.workouts = workouts
            }
        } else if segue.identifier == EDIT_WORKOUT_PROGRAM_SEGUE_IDENTIFIER {
            let vc = segue.destination as? EditWorkoutProgramTableViewController
            if let program = sender as? WorkoutProgram {
                vc?.workoutProgram = program
            }
        }
    }

    
}
