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
    
    @objc func openBackup() {
        let backupVC = BackupViewController(style: .insetGrouped)
        navigationController?.pushViewController(backupVC, animated: true)
    }
    
    // MARK: View Lifecycle
    
    func setupView() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addExercise))
        
        // Add backup button on the left
        let backupButton = UIBarButtonItem(image: UIImage(systemName: "arrow.up.arrow.down.circle"), style: .plain, target: self, action: #selector(openBackup))
        navigationItem.leftBarButtonItem = backupButton
        
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
                    self.updateBackgroundView()
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
    
    func updateBackgroundView() {
        if self.exerciseDataSource.exerciseNames().count == 0 {
                tableView.backgroundView = createBackgroundView()
            } else {
                tableView.backgroundView = nil
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
           let exercise = self.exerciseDataSource.exerciseForIndexPath(indexPath),
           let exercisesInSection = self.exerciseDataSource.exercisesForSection(indexPath.section) {
            dataLoader.deleteExercise(exercise)
            dataLoader.saveContext()
            self.exerciseDataSource.removeExercise(at: indexPath)
            if exercisesInSection.count == 1 {
                tableView.deleteSections(IndexSet(integer: indexPath.section), with: .automatic)
            } else {
                tableView.deleteRows(at: [indexPath], with: .automatic)
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        self.exerciseDataSource.titleForSection(section)
    }
    
    @objc func backgroundTapped() {
        self.performSegue(withIdentifier: EXERCISE_SEGUE_IDENTIFIER, sender: self)
    }
    
    func createBackgroundView() -> UIView {
        let backgroundView = UIView(frame: UIScreen.main.bounds)

        // Create the image view
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(systemName: "dumbbell.fill")
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true

        // Create and add the tap gesture recognizer
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped))
        backgroundView.addGestureRecognizer(tapGestureRecognizer)

        // Create the label
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Tap for your first Exercise!"
        label.textColor = .systemBlue
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 23, weight: .semibold)

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
    
    // MARK: Segues
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == EXERCISE_SEGUE_IDENTIFIER {
            let vc = segue.destination as? EditExerciseTableViewController
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

