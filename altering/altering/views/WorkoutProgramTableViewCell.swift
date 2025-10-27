import UIKit

class WorkoutProgramTableViewCell: UITableViewCell {
    
    @IBOutlet weak var exerciseLabel: UILabel!
    @IBOutlet weak var progressBar: UIProgressView!
    @IBOutlet weak var remainingWorkoutCountLabel: UILabel!
    @IBOutlet weak var remainingSubtitleLabel: UILabel!
    @IBOutlet weak var dateImageView: UIImageView!
    @IBOutlet weak var dateLabel: UILabel!
    
    private var hasAppliedModernStyling = false

    override func awakeFromNib() {
        super.awakeFromNib()
        setupInitialStyle()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
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
    }
    
    // MARK: - Modern Styling
    
    func applyModernStyling() {
        guard !hasAppliedModernStyling else { return }
        hasAppliedModernStyling = true
        
        // Card-like appearance - apply to contentView for proper clipping
        contentView.layer.cornerRadius = 12
        contentView.layer.cornerCurve = .continuous
        contentView.layer.masksToBounds = true
        contentView.backgroundColor = .systemBackground
        
        // Shadow on cell layer (not contentView to avoid clipping)
        backgroundColor = .clear
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.08
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 6
        layer.masksToBounds = false
        
        // Create shadow path for better performance
        DispatchQueue.main.async {
            self.layer.shadowPath = UIBezierPath(
                roundedRect: self.bounds.insetBy(dx: 4, dy: 2),
                cornerRadius: 12
            ).cgPath
        }
        
        // Add padding by adjusting content insets
        contentView.layoutMargins = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        
        // Modern typography
        exerciseLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        exerciseLabel.textColor = .label
        exerciseLabel.adjustsFontForContentSizeCategory = true
        
        remainingWorkoutCountLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        remainingWorkoutCountLabel.textColor = .label
        remainingWorkoutCountLabel.adjustsFontForContentSizeCategory = true
        
        remainingSubtitleLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        remainingSubtitleLabel.textColor = .secondaryLabel
        remainingSubtitleLabel.adjustsFontForContentSizeCategory = true
        
        dateLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
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
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Add padding around cell
        contentView.frame = contentView.frame.inset(by: UIEdgeInsets(top: 6, left: 16, bottom: 6, right: 16))
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        hasAppliedModernStyling = false
    }
}
