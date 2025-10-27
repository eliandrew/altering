import UIKit

class MultiIconTableViewCell: UITableViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var subIconImageView: UIImageView!
    
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
        selectionStyle = .none
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
        
        // Modern typography
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = .label
        titleLabel.adjustsFontForContentSizeCategory = true
        
        subtitleLabel.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.adjustsFontForContentSizeCategory = true
        
        // Style icons
        iconImageView.tintColor = .systemBlue
        iconImageView.contentMode = .scaleAspectFit
        
        subIconImageView.tintColor = .systemGreen
        subIconImageView.contentMode = .scaleAspectFit
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
