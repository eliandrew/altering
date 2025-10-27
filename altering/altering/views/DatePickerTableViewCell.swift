import UIKit

class DatePickerTableViewCell: UITableViewCell {

    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var dateSwitch: UISwitch!
    
    private var hasAppliedModernStyling = false
    
    @IBAction func dateSwitchChanged(_ sender: Any) {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        let isOn = dateSwitch.isOn
        
        // Animate date picker visibility
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: .curveEaseOut) {
            self.datePicker.alpha = isOn ? 1.0 : 0.3
            self.datePicker.isHidden = !isOn
        }
    }
    
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
        
        // Modern date picker styling
        datePicker.preferredDatePickerStyle = .compact
        datePicker.tintColor = .systemBlue
        
        // Modern switch styling
        dateSwitch.onTintColor = .systemBlue
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
