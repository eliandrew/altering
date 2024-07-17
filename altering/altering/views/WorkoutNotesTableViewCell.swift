import UIKit

class WorkoutNotesTableViewCell: UITableViewCell {

    @IBOutlet weak var calendarImageView: UIImageView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var notesTextView: UITextView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupToolBar()
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
        self.notesTextView.resignFirstResponder()
    }
}
