import UIKit

class ButtonTableViewCell: UITableViewCell {
    
    @IBOutlet weak var button: UIButton!
    
    private var hasAppliedModernStyling = false

    override func awakeFromNib() {
        super.awakeFromNib()
        setupInitialStyle()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
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
        
        // Card-like appearance
        contentView.backgroundColor = .systemBackground
        contentView.layer.cornerRadius = 12
        contentView.layer.cornerCurve = .continuous
        
        // Subtle shadow
        contentView.layer.shadowColor = UIColor.black.cgColor
        contentView.layer.shadowOpacity = 0.08
        contentView.layer.shadowOffset = CGSize(width: 0, height: 2)
        contentView.layer.shadowRadius = 6
        contentView.layer.masksToBounds = false
        
        // Modern button styling
        var buttonConfig = UIButton.Configuration.filled()
        buttonConfig.cornerStyle = .large
        buttonConfig.baseBackgroundColor = .systemBlue
        buttonConfig.baseForegroundColor = .white
        buttonConfig.buttonSize = .large
        buttonConfig.title = "Add Exercise"
        buttonConfig.imagePlacement = .leading
        buttonConfig.imagePadding = 8
        buttonConfig.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20)
        button.configuration = buttonConfig
        
        // Add bounce animation
        button.addTarget(self, action: #selector(buttonTouchDown), for: .touchDown)
        button.addTarget(self, action: #selector(buttonTouchUp), for: [.touchUpInside, .touchUpOutside, .touchCancel])
    }
    
    @objc private func buttonTouchDown() {
        UIView.animate(withDuration: 0.1, delay: 0, options: .curveEaseOut) {
            self.button.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }
    }
    
    @objc private func buttonTouchUp() {
        UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.8, options: .curveEaseOut) {
            self.button.transform = .identity
        }
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
