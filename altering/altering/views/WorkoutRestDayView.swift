import UIKit

class WorkoutRestDayView: UITableViewHeaderFooterView {
    @IBOutlet weak var restingDaysLabel: UILabel!
    @IBOutlet weak var restingDaysImageView: UIImageView!
        
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
}
