import UIKit

class ButtonHeaderView: UITableViewHeaderFooterView {

    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var buttonRight: UIButton!
    @IBOutlet weak var buttonCenter: UIButton!
    @IBOutlet weak var buttonLeft: UIButton!
    
    private var hasAppliedModernStyling = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupInitialStyle()
    }
    
    private func setupInitialStyle() {
        // Clear background for modern look
        backgroundView = UIView()
        backgroundView?.backgroundColor = .clear
        contentView.backgroundColor = .clear
    }
    
    // MARK: - Modern Styling
    
    func applyModernStyling() {
        guard !hasAppliedModernStyling else { return }
        hasAppliedModernStyling = true
        
        // Modern typography for title
        title.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        title.textColor = .label
        title.adjustsFontForContentSizeCategory = true
        
        // Modern button styling
        styleButton(buttonRight, systemImage: "trash", tintColor: .systemRed)
        styleButton(buttonCenter, systemImage: "pencil", tintColor: .systemBlue)
        styleButton(buttonLeft, systemImage: "checkmark.circle.fill", tintColor: .systemGreen)
    }
    
    private func styleButton(_ button: UIButton, systemImage: String, tintColor: UIColor) {
        // Use modern SF Symbols
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
        button.setImage(UIImage(systemName: systemImage, withConfiguration: config), for: .normal)
        button.tintColor = tintColor
        
        // Clear background, modern appearance
        button.backgroundColor = tintColor.withAlphaComponent(0.1)
        button.layer.cornerRadius = 8
        button.layer.cornerCurve = .continuous
        
        // Add padding
        button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        
        // Modern interaction
        button.addTarget(self, action: #selector(buttonTouchDown(_:)), for: .touchDown)
        button.addTarget(self, action: #selector(buttonTouchUp(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
    }
    
    @objc private func buttonTouchDown(_ sender: UIButton) {
        UIView.animate(withDuration: 0.1, delay: 0, options: .curveEaseOut) {
            sender.transform = CGAffineTransform(scaleX: 0.92, y: 0.92)
            sender.alpha = 0.7
        }
    }
    
    @objc private func buttonTouchUp(_ sender: UIButton) {
        UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.8, options: .curveEaseOut) {
            sender.transform = .identity
            sender.alpha = 1.0
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        hasAppliedModernStyling = false
    }

}
