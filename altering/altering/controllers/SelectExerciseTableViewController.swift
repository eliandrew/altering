import UIKit

protocol SelectExerciseDelegate {
    func didSelectExercise(_ exercise: Exercise)
}

class SelectExerciseTableViewController: UITableViewController {

    var exerciseDataSource = ExerciseTableViewDataSource()
    var delegate: SelectExerciseDelegate?
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
        title = "Select Exercise"

        // Enable large titles
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        
       
        
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

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.exerciseDataSource.numberOfSections(tableView)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.exerciseDataSource.numberOfRowsInSection(tableView, section: section)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return self.exerciseDataSource.cellForRowAtIndexPath(tableView, indexPath: indexPath)
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.exerciseDataSource.titleForSection(section)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if let exercise = self.exerciseDataSource.exerciseForIndexPath(indexPath) {
            delegate?.didSelectExercise(exercise)
        }
        self.navigationController?.popViewController(animated: true)
    }
}

extension SelectExerciseTableViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        if let searchText = searchController.searchBar.text, !searchText.isEmpty {
            self.exerciseDataSource.setSearchText(searchText)
        } else {
            self.exerciseDataSource.setSearchText(nil)
        }
        self.tableView.reloadData()
    }
}
