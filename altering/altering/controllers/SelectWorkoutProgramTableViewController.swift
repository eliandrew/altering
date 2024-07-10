import UIKit

protocol SelectWorkoutProgramDelegate {
    func didSelectWorkoutProgram(_ program: WorkoutProgram)
}

class SelectWorkoutProgramTableViewController: UITableViewController {
    
    var exercise: Exercise?
    
    let SEARCH_WORKOUT_PROGRAM_CELL_IDENTIFIER = "searchWorkoutProgramCell"
    
    var workoutProgramDataSource = WorkoutProgramTableViewDataSource()
    var delegate: SelectWorkoutProgramDelegate?
    let dataLoader = DataLoader.shared
    
    let searchController = UISearchController(searchResultsController: nil)
    
    @objc func exit() {
        navigationController?.popViewController(animated: true)
    }
    
    func setupView() {
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(exit))
        
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search"
        navigationItem.searchController = searchController
        definesPresentationContext = true
        
        // Set the title for the large title
        title = "Select Program"

        // Enable large titles
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        
        if let exercise = exercise {
            dataLoader.loadAllWorkoutPrograms { result in
                switch result {
                case .success(let fetchedPrograms):
                    let displayPrograms = fetchedPrograms.filter { program in
                        
                        // program has to (1) have plan with same exercise as our exercise AND that same plan needs to not be completed
                        let plans = program.plans?.allObjects as? [WorkoutPlan]
                        let availablePlans = plans?.filter({ p in
                            return p.exercise == exercise
                        })
                        let nonCompletedPlans = availablePlans?.filter({ p in
                            let workoutsForPlan = program.workouts?.filter({ w in
                                let workout = w as? Workout
                                return workout?.exercise == exercise
                            })
                            return p.numWorkouts > (workoutsForPlan?.count ?? 0)
                        })
                        
                        return nonCompletedPlans?.count ?? 0 > 0
                    }
                    self.workoutProgramDataSource.setPrograms(displayPrograms)
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                case .failure(let error):
                    print("Error fetching programs: \(error)")
                    self.workoutProgramDataSource.setPrograms([])
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
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

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.workoutProgramDataSource.programs.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return self.workoutProgramDataSource.searchCellForRowAtIndexPath(tableView, indexPath: indexPath)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let program = self.workoutProgramDataSource.searchPrograms[indexPath.row]
        delegate?.didSelectWorkoutProgram(program)
        self.navigationController?.popViewController(animated: true)
    }
}

extension SelectWorkoutProgramTableViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        if let searchText = searchController.searchBar.text, !searchText.isEmpty {
            self.workoutProgramDataSource.setSearchText(searchText)
        } else {
            self.workoutProgramDataSource.setSearchText(nil)
        }
        self.tableView.reloadData()
    }
}
