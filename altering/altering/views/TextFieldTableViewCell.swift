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
        
        // Standard appearance - no cards
        contentView.backgroundColor = .systemBackground
        
        // Modern text field styling
        textField.font = UIFont.systemFont(ofSize: 20, weight: .regular)
        textField.textColor = .label
        textField.adjustsFontForContentSizeCategory = true
        textField.placeholder = "Enter program name"
        textField.clearButtonMode = .whileEditing
        textField.returnKeyType = .done
        textField.autocapitalizationType = .words
        textField.borderStyle = .none
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        hasAppliedModernStyling = false
    }
}
