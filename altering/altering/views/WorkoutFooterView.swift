import UIKit

class WorkoutFooterView: UITableViewHeaderFooterView {
    @IBOutlet weak var restDaysLabel: UILabel!
    @IBOutlet weak var restDaysImageView: UIImageView!
    
    private var hasAppliedModernStyling = false
        
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    // MARK: - Modern Styling
    
    func applyModernStyling() {
        guard !hasAppliedModernStyling else { return }
        hasAppliedModernStyling = true
        
        // Clear background for modern look
        backgroundView = UIView()
        backgroundView?.backgroundColor = .clear
        contentView.backgroundColor = .clear
        
        // Modern typography
        restDaysLabel.font = UIFont.systemFont(ofSize: 19, weight: .medium)
        restDaysLabel.textColor = .secondaryLabel
        restDaysLabel.adjustsFontForContentSizeCategory = true
        
        // Style icon
        restDaysImageView.tintColor = .secondaryLabel
        restDaysImageView.contentMode = .scaleAspectFit
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        hasAppliedModernStyling = false
    }
}
