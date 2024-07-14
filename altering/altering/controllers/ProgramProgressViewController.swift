import UIKit

class ProgramProgressViewController: UIViewController {

    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var progressImageView: UIImageView!
    @IBOutlet weak var progressTitleLabel: UILabel!
    @IBOutlet weak var progressSubtitleLabel: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var actionButton: UIButton!
    @IBOutlet weak var backgroundView: UIView!
    
    var progressTitleText: String?
    var progressSubtitleText: NSAttributedString?
    var progressImage: UIImage?
    var progress: Float? = 0.0
    
    @IBAction func actionButtonPressed(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.layer.cornerRadius = 20
        backgroundView.layer.masksToBounds = true
        if let progress {
            self.progressView.isHidden = false
            if progress == 1.0 {
                self.progressView.tintColor = .systemGreen
            } else {
                self.progressView.tintColor = .systemBlue
            }
        } else {
            self.progressView.isHidden = true
        }
        
        self.progressTitleLabel.text = progressTitleText
        self.progressSubtitleLabel.attributedText = progressSubtitleText
        self.progressImageView.image = progressImage
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let progress {
            self.progressView.setProgress(progress, animated: true)
        }
    }
    
    
}
