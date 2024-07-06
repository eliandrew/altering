import UIKit

class WorkoutProgramTableViewController: UITableViewController {
    
    var programDataSource = WorkoutProgramTableViewDataSource()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.programDataSource.numberOfSections(tableView)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.programDataSource.numberOfRowsInSection(tableView, section: section)
    }
    
}
