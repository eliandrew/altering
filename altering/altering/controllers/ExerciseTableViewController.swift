import UIKit

class ExerciseTableViewController: UITableViewController {
    
    // MARK: Constants
    
    let EXERCISE_SEGUE_IDENTIFIER = "exerciseSegue"
    
    // MARK: Properties
    
    let searchController = UISearchController(searchResultsController: nil)
    var exerciseDataSource = ExerciseTableViewDataSource()
    let dataLoader = DataLoader.shared
    
    // MARK: Actions
    
    @objc func addExercise() {
        performSegue(withIdentifier: EXERCISE_SEGUE_IDENTIFIER, sender: nil)
    }
    
    // MARK: View Lifecycle
    
    func setupView() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addExercise))
        
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search"
        navigationItem.searchController = searchController
        definesPresentationContext = true
        
        // Set the title for the large title
        title = "Exercises"

        // Enable large titles
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        tableView.tableFooterView = nil
        
        dataLoader.loadAllExercises { result in
            switch result {
            case .success(let fetchedExercises):
                self.exerciseDataSource.setExercises(fetchedExercises)
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            case .failure(let error):
                print("Error fetching exercises: \(error)")
                self.exerciseDataSource.setExercises([])
                DispatchQueue.main.async {
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
        return self.exerciseDataSource.numberOfSections(tableView)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.exerciseDataSource.numberOfRowsInSection(tableView, section: section)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        self.exerciseDataSource.cellForRowAtIndexPath(tableView, indexPath: indexPath)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let exercise = self.exerciseDataSource.exerciseForIndexPath(indexPath)
        performSegue(withIdentifier: EXERCISE_SEGUE_IDENTIFIER, sender: exercise)
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete, 
            let exercise = self.exerciseDataSource.exerciseForIndexPath(indexPath) {
            dataLoader.deleteExercise(exercise)
            dataLoader.saveContext()
            self.exerciseDataSource.removeExercise(at: indexPath)
            self.tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        self.exerciseDataSource.titleForSection(section)
    }
    
    // MARK: Segues
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == EXERCISE_SEGUE_IDENTIFIER {
            let vc = segue.destination as? EditExerciseViewController
            vc?.existingExerciseNames = self.exerciseDataSource.exerciseNames()
            if let exercise = sender as? Exercise {
                vc?.exercise = exercise
            }
        }
    }
}

extension ExerciseTableViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        if let searchText = searchController.searchBar.text, !searchText.isEmpty {
            self.exerciseDataSource.setSearchText(searchText)
        } else {
            self.exerciseDataSource.setSearchText(nil)
        }
        self.tableView.reloadData()
    }
}

