import UIKit

class WorkoutFooterView: UITableViewHeaderFooterView {
    @IBOutlet weak var restDaysLabel: UILabel!
        
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
}
