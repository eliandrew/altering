import Foundation
import UIKit

class GroupTableViewDataSource {
    
    let GROUP_CELL_IDENTIFIER = "groupCell"
    var exerciseGroups = [ExerciseGroup]()
    
    // MARK: Helpers
    
    func exerciseGroupForIndexPath(_ indexPath: IndexPath) -> ExerciseGroup? {
        if indexPath.row < self.exerciseGroups.count {
            return self.exerciseGroups[indexPath.row]
        } else {
            return nil
        }
    }
    
    func exerciseGroupNames() -> [String?] {
        return self.exerciseGroups.map { group in
            group.name?.lowercased()
        }
    }
    
    func numberOfSections(_ tableView: UITableView) -> Int {
        return 1
    }
    
    func numberOfRowsInSection(_ tableView: UITableView, section: Int) -> Int {
        return self.exerciseGroups.count + 1
    }
    
    func cellForRowAtIndexPath(_ tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: GROUP_CELL_IDENTIFIER, for: indexPath)
        var content = UIListContentConfiguration.cell()
        if let exerciseGroup = exerciseGroupForIndexPath(indexPath) {
            content.text = exerciseGroup.name ?? "Missing Name"
            content.textProperties.font = UIFont.systemFont(ofSize: 23)
            cell.contentConfiguration = content
        } else {
            content.text = "Add New Group"
            content.textProperties.font = UIFont.systemFont(ofSize: 23)
            cell.contentConfiguration = content
        }
       
        return cell
    }
    
}
