import UIKit

class WorkoutPlanTableViewCell: UITableViewCell {

    @IBOutlet weak var exerciseLabel: UILabel!
    @IBOutlet weak var workoutCountSlider: UISlider!
    @IBOutlet weak var workoutCountLabel: UILabel!
    
    private var hasAppliedModernStyling = false
    
    @IBAction func sliderChanged(_ sender: Any) {
        // Haptic feedback
        let selectionFeedback = UISelectionFeedbackGenerator()
        selectionFeedback.selectionChanged()
        
        updateWorkoutLabel()
    }
    
    func setWorkoutCount(_ count: Int64) {
        self.workoutCountSlider.value = Float(count)
        self.updateWorkoutLabel()
    }
    
    func updateWorkoutLabel() {
        let value = Int(self.workoutCountSlider.value)
        self.workoutCountLabel.text = "\(value) workout\(value == 1 ? "" : "s")"
    }
    
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
        
        // Modern typography
        exerciseLabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        exerciseLabel.textColor = .label
        exerciseLabel.adjustsFontForContentSizeCategory = true
        
        workoutCountLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        workoutCountLabel.textColor = .secondaryLabel
        workoutCountLabel.adjustsFontForContentSizeCategory = true
        
        // Modern slider styling
        workoutCountSlider.tintColor = .systemBlue
        workoutCountSlider.minimumTrackTintColor = .systemBlue
        workoutCountSlider.maximumTrackTintColor = .systemGray4
        
        // Add rounded thumb
        if let thumbImage = createThumbImage() {
            workoutCountSlider.setThumbImage(thumbImage, for: .normal)
            workoutCountSlider.setThumbImage(thumbImage, for: .highlighted)
        }
    }
    
    private func createThumbImage() -> UIImage? {
        let size = CGSize(width: 28, height: 28)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        defer { UIGraphicsEndImageContext() }
        
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        // Draw shadow
        context.setShadow(offset: CGSize(width: 0, height: 2), blur: 4, color: UIColor.black.withAlphaComponent(0.2).cgColor)
        
        // Draw circle
        context.setFillColor(UIColor.systemBlue.cgColor)
        context.fillEllipse(in: CGRect(origin: .zero, size: size))
        
        return UIGraphicsGetImageFromCurrentImageContext()
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
