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
    var progressSubtitleText: String?
    var progressImage: UIImage?
    var progress: Float = 0.0
    
    @IBAction func actionButtonPressed(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.layer.cornerRadius = 20
        backgroundView.layer.masksToBounds = true
        if self.progress == 1.0 {
            self.progressView.tintColor = .systemGreen
        } else {
            self.progressView.tintColor = .systemBlue
        }
        self.progressTitleLabel.text = progressTitleText
        self.progressSubtitleLabel.text = progressSubtitleText
        self.progressImageView.image = progressImage
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.progressView.setProgress(self.progress, animated: true)
    }
    
    
}
