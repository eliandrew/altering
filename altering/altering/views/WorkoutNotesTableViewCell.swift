import UIKit

class WorkoutNotesTableViewCell: UITableViewCell {

    @IBOutlet weak var calendarImageView: UIImageView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var notesTextView: UITextView!
    
    private var hasAppliedModernStyling = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupToolBar()
        setupInitialStyle()
    }
    
    func setupToolBar() {
        // Create a toolbar
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
       
        // Create a flexible space item
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        // Create a done button
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonTapped))
       
        // Add the done button to the toolbar
        toolbar.items = [flexibleSpace, doneButton]
       
        // Set the toolbar as the input accessory view
        self.notesTextView.inputAccessoryView = toolbar
    }
    
    @objc func doneButtonTapped() {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        self.notesTextView.resignFirstResponder()
    }
    
    private func setupInitialStyle() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
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
    
    // MARK: - Modern Styling
    
    func applyModernStyling() {
        guard !hasAppliedModernStyling else { return }
        hasAppliedModernStyling = true
        
        // Standard appearance - no cards
        contentView.backgroundColor = .systemBackground
        
        // Modern typography for date
        dateLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        dateLabel.textColor = .label
        dateLabel.adjustsFontForContentSizeCategory = true
        
        // Modern notes text view
        notesTextView.font = UIFont.systemFont(ofSize: 18, weight: .regular)
        notesTextView.textColor = .secondaryLabel
        notesTextView.backgroundColor = .clear
        notesTextView.textContainerInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        notesTextView.textContainer.lineFragmentPadding = 0
        
        // Style calendar icon
        calendarImageView.tintColor = .systemBlue
        calendarImageView.contentMode = .scaleAspectFit
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        hasAppliedModernStyling = false
    }
}
