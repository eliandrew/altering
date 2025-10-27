import UIKit

class TextFieldTableViewCell: UITableViewCell {
    
    @IBOutlet weak var textField: UITextField!
    
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
        
        // Modern text field styling
        textField.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        textField.textColor = .label
        textField.adjustsFontForContentSizeCategory = true
        textField.placeholder = "Enter program name"
        textField.clearButtonMode = .whileEditing
        textField.returnKeyType = .done
        textField.autocapitalizationType = .words
        
        // Add subtle border when focused
        textField.borderStyle = .none
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
