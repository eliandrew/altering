import Foundation
import UIKit

class WorkoutProgramTableViewDataSource {
    
    let PROGRAM_CELL_IDENTIFIER = "programCell"
    
    var programsByKey: [String : [Exercise]] = [:]
    var programKeys = [String]()
    
    // MARK: Helpers
    
    func setPrograms(_ programs: [Exercise]) {
        var newProgramsByKey: [String : [Exercise]] = [:]
        var newProgramKeys = [String]()
        for program in programs {
            let programKey = "All"
            if newProgramsByKey[programKey] == nil {
                newProgramsByKey[programKey] = []
                newProgramKeys.append(programKey)
            }
            newProgramsByKey[programKey]?.append(program)
        }
        self.programsByKey = newProgramsByKey
        self.programKeys = newProgramKeys
    }
    
    func programsForSection(_ section: Int) -> [Exercise]? {
        if section < self.programKeys.count {
            let programKey = self.programKeys[section]
            return self.programsByKey[programKey]
        } else {
            return nil
        }
    }
    
    func programForIndexPath(_ indexPath: IndexPath) -> Exercise? {
        if let programs = self.programsForSection(indexPath.section) {
            if indexPath.row < programs.count {
                return programs[indexPath.row]
            } else {
                return nil
            }
        }
        return nil
    }
    
    func numberOfSections(_ tableView: UITableView) -> Int {
        return self.programKeys.count
    }
    
    func numberOfRowsInSection(_ tableView: UITableView, section: Int) -> Int {
        return self.programsForSection(section)?.count ?? 0
    }
    
    func cellForRowAtIndexPath(_ tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: PROGRAM_CELL_IDENTIFIER, for: indexPath)
        
        guard let exercise = programForIndexPath(indexPath) else {
            return cell
        }
        
        var content = UIListContentConfiguration.cell()
        content.text = exercise.name ?? "Missing Name"
        content.textProperties.font = UIFont.systemFont(ofSize: 20)
        content.secondaryTextProperties.font = UIFont.systemFont(ofSize: 15)
        cell.contentConfiguration = content
        
        return cell
    }
    
    func titleForSection(_ section: Int) -> String? {
        if section < self.programKeys.count {
            return self.programKeys[section]
        } else {
            return nil
        }
    }
}

