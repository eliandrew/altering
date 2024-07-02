import UIKit

class ExpandWorkoutsTableViewCell: UITableViewCell {
    
    @IBOutlet weak var expandLabel: UILabel!
    @IBOutlet weak var expandImageView: UIImageView!
        
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
