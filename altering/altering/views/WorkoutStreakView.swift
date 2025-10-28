import UIKit

class WorkoutStreakView: UIView {
    @IBOutlet weak var streakLabel: UILabel!
    @IBOutlet weak var streakImageView: UIImageView!
    @IBOutlet weak var longestStreakImageView: UIImageView!
    
    private var hasAppliedModernStyling = false
    private var iconBackgroundView: UIView?
    
    // MARK: - Modern Styling
    
    func applyModernStyling() {
        guard !hasAppliedModernStyling else { return }
        hasAppliedModernStyling = true
        
        // Modern card appearance
        backgroundColor = .systemBackground
        layer.cornerRadius = 16
        layer.cornerCurve = .continuous
        
        // Subtle shadow
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.1
        layer.shadowOffset = CGSize(width: 0, height: 4)
        layer.shadowRadius = 12
        layer.masksToBounds = false
        
        // Add circular background for icon
        if let streakImageView = streakImageView {
            let iconContainer = UIView()
            iconContainer.translatesAutoresizingMaskIntoConstraints = false
            iconContainer.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
            iconContainer.layer.cornerRadius = 35
            
            insertSubview(iconContainer, belowSubview: streakImageView)
            
            NSLayoutConstraint.activate([
                iconContainer.centerXAnchor.constraint(equalTo: streakImageView.centerXAnchor),
                iconContainer.centerYAnchor.constraint(equalTo: streakImageView.centerYAnchor),
                iconContainer.widthAnchor.constraint(equalToConstant: 70),
                iconContainer.heightAnchor.constraint(equalToConstant: 70)
            ])
            
            self.iconBackgroundView = iconContainer
        }
        
        // Modern typography
        streakLabel.font = UIFont.systemFont(ofSize: 23, weight: .bold)
        streakLabel.adjustsFontForContentSizeCategory = true
        
        // Style icons
        streakImageView.contentMode = .scaleAspectFit
        longestStreakImageView.contentMode = .scaleAspectFit
        
        // Add padding
        layoutMargins = UIEdgeInsets(top: 16, left: 20, bottom: 16, right: 20)
    }
}
