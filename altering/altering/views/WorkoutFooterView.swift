import UIKit

class WorkoutFooterView: UITableViewHeaderFooterView {
    @IBOutlet weak var restDaysLabel: UILabel!
    @IBOutlet weak var restDaysImageView: UIImageView!
        
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
}
