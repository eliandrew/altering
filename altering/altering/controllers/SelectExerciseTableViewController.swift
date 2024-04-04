import UIKit

protocol SelectExerciseDelegate {
    func didSelectExercise(_ exercise: Exercise)
}

class SelectExerciseTableViewController: UITableViewController {

    var exerciseDataSource = ExerciseTableViewDataSource()
    var delegate: SelectExerciseDelegate?
    let dataLoader = DataLoader.shared
    
    func setupView() {
        dataLoader.loadAllExercises { fetchedExercises in
            if let fetchedExercises = fetchedExercises {
                self.exerciseDataSource.setExercises(fetchedExercises)
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
        if let exercise = self.exerciseDataSource.exerciseForIndexPath(indexPath) {
            delegate?.didSelectExercise(exercise)
        }
        self.dismiss(animated: true)
    }
}
