import UIKit

protocol SelectGroupDelegate {
    func didSelectGroup(_ exerciseGroup: ExerciseGroup)
}

class SelectGroupTableViewController: UITableViewController {

    let groupDataSource = GroupTableViewDataSource()
    let dataLoader = DataLoader.shared
    
    var delegate: SelectGroupDelegate?
    
    func addGroupViewController() -> UIAlertController? {
        let alertController = UIAlertController(title: "Add New Group", message: nil, preferredStyle: .alert)
        alertController.addTextField()
        let submitAction = UIAlertAction(title: "Add", style: .default) { [unowned alertController] _ in
            let newGroupName = alertController.textFields![0].text
            if self.groupDataSource.exerciseGroupNames().contains(newGroupName!.lowercased()) {
                return
            }
            let newGroup = self.dataLoader.createNewGroup()
            newGroup.name = newGroupName
            self.dataLoader.saveContext()
            self.delegate?.didSelectGroup(newGroup)
            self.dismiss(animated: true)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alertController.addAction(cancelAction)
        alertController.addAction(submitAction)
        return alertController
    }
    
    func setupView() {
        dataLoader.loadAllGroups { result in
            switch result {
            case .success(let fetchedGroups):
                self.groupDataSource.exerciseGroups = fetchedGroups
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            case .failure(let error):
                print("Error fetching exercises: \(error)")
                self.groupDataSource.exerciseGroups = []
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
        return self.groupDataSource.numberOfSections(tableView)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.groupDataSource.numberOfRowsInSection(tableView, section: section)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return self.groupDataSource.cellForRowAtIndexPath(tableView, indexPath: indexPath)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if let exerciseGroup = self.groupDataSource.exerciseGroupForIndexPath(indexPath) {
            self.delegate?.didSelectGroup(exerciseGroup)
            self.dismiss(animated: true)
        } else {
            if let addGroupVC = addGroupViewController() {
                self.present(addGroupVC, animated: true)
            }
        }
    }
}
