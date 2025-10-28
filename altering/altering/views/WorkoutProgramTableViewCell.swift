import UIKit

class WorkoutProgramTableViewCell: UITableViewCell {
    
    @IBOutlet weak var exerciseLabel: UILabel!
    @IBOutlet weak var progressBar: UIProgressView!
    @IBOutlet weak var remainingWorkoutCountLabel: UILabel? // Hidden - no longer used
    @IBOutlet weak var remainingSubtitleLabel: UILabel? // Hidden - no longer used
    @IBOutlet weak var dateImageView: UIImageView!
    @IBOutlet weak var dateLabel: UILabel!
    
    private var hasAppliedModernStyling = false

    override func awakeFromNib() {
        super.awakeFromNib()
        setupInitialStyle()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        // Skip selection highlight for cells with tag=1
        if self.tag == 1 {
            // Don't call super or change anything - no visual feedback
            return
        }
        
        super.setSelected(selected, animated: animated)
        
        // Modern selection style
        if selected {
            UIView.animate(withDuration: 0.1) {
                self.contentView.alpha = 0.9
            }
        } else {
            UIView.animate(withDuration: 0.2) {
                self.contentView.alpha = 1.0
            }
        }
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        // Skip highlight for cells with tag=1
        if self.tag == 1 {
            // Don't call super or change anything - no visual feedback
            return
        }
        
        super.setHighlighted(highlighted, animated: animated)
        
        // Modern highlight style
        if animated {
            UIView.animate(withDuration: 0.15, delay: 0, options: .curveEaseOut) {
                self.contentView.alpha = highlighted ? 0.85 : 1.0
            }
        } else {
            self.contentView.alpha = highlighted ? 0.85 : 1.0
        }
    }
    
    private func setupInitialStyle() {
        // Remove default selection style
        selectionStyle = .none
        
        // Set background
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        
        // Hide the remaining labels - we don't use them anymore
        remainingWorkoutCountLabel?.isHidden = true
        remainingSubtitleLabel?.isHidden = true
    }
    
    // MARK: - Modern Styling
    
    func applyModernStyling() {
        guard !hasAppliedModernStyling else { return }
        hasAppliedModernStyling = true
        
        // Standard appearance - no cards
        contentView.backgroundColor = .systemBackground
        backgroundColor = .clear
        
        // Modern typography
        exerciseLabel.font = UIFont.systemFont(ofSize: 21, weight: .semibold)
        exerciseLabel.textColor = .label
        exerciseLabel.adjustsFontForContentSizeCategory = true
        
        dateLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        dateLabel.textColor = .secondaryLabel
        dateLabel.adjustsFontForContentSizeCategory = true
        
        // Modern progress bar
        progressBar.layer.cornerRadius = 3
        progressBar.clipsToBounds = true
        progressBar.trackTintColor = UIColor.systemGray5
        progressBar.transform = CGAffineTransform(scaleX: 1, y: 1.5) // Make it slightly thicker
        
        // Style the date icon
        dateImageView.tintColor = .secondaryLabel
        dateImageView.contentMode = .scaleAspectFit
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        hasAppliedModernStyling = false
        
        // Reset icon to nothing
        dateImageView.image = nil
    }
}
