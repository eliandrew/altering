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
    
    private var iconBackgroundView: UIView?
    private var gradientLayer: CAGradientLayer?
    private var emitterLayer: CAEmitterLayer?
    
    @IBAction func actionButtonPressed(_ sender: Any) {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Animate dismissal
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0.5, options: .curveEaseOut) {
            self.backgroundView.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            self.backgroundView.alpha = 0.0
        } completion: { _ in
            self.dismiss(animated: true)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupModernUI()
        configureContent()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateEntrance()
        
        if let progress = progress {
            // Animate progress bar with spring effect
            UIView.animate(withDuration: 1.2, delay: 0.3, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.8, options: .curveEaseOut) {
                self.progressView.setProgress(progress, animated: true)
            }
            
            // Add completion celebration if fully complete
            if progress == 1.0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    self.triggerCompletionCelebration()
                }
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Update gradient frame
        gradientLayer?.frame = backgroundView.bounds
    }
    
    // MARK: - Modern UI Setup
    
    private func setupModernUI() {
        // Configure background view with modern card design
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.layer.cornerRadius = 24
        backgroundView.layer.cornerCurve = .continuous
        backgroundView.layer.masksToBounds = false
        
        // Add sophisticated shadow
        backgroundView.layer.shadowColor = UIColor.black.cgColor
        backgroundView.layer.shadowOpacity = 0.2
        backgroundView.layer.shadowOffset = CGSize(width: 0, height: 10)
        backgroundView.layer.shadowRadius = 30
        
        // Add subtle gradient background
        addGradientBackground()
        
        // Configure image view with icon background
        setupIconBackground()
        
        // Configure title label with dynamic type
        progressTitleLabel.font = UIFont.systemFont(ofSize: 31, weight: .bold)
        progressTitleLabel.adjustsFontForContentSizeCategory = true
        progressTitleLabel.textColor = .label
        
        // Configure subtitle label
        progressSubtitleLabel.font = UIFont.systemFont(ofSize: 20, weight: .regular)
        progressSubtitleLabel.adjustsFontForContentSizeCategory = true
        progressSubtitleLabel.textColor = .secondaryLabel
        progressSubtitleLabel.numberOfLines = 0
        
        // Configure progress view with modern style
        progressView.layer.cornerRadius = 4
        progressView.clipsToBounds = true
        progressView.trackTintColor = UIColor.systemGray5
        progressView.transform = CGAffineTransform(scaleX: 1, y: 2) // Make it thicker
        
        // Configure button with modern styling
        var buttonConfig = UIButton.Configuration.filled()
        buttonConfig.title = "Dismiss"
        buttonConfig.cornerStyle = .large
        buttonConfig.baseBackgroundColor = .systemBlue
        buttonConfig.baseForegroundColor = .white
        buttonConfig.buttonSize = .large
        buttonConfig.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 32, bottom: 16, trailing: 32)
        actionButton.configuration = buttonConfig
        
        // Add subtle bounce effect to button
        actionButton.addTarget(self, action: #selector(buttonTouchDown), for: .touchDown)
        actionButton.addTarget(self, action: #selector(buttonTouchUp), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        
        // Set initial transform for animation
        backgroundView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        backgroundView.alpha = 0.0
    }
    
    private func addGradientBackground() {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = backgroundView.bounds
        gradientLayer.colors = [
            UIColor.systemBackground.cgColor,
            UIColor.systemBackground.withAlphaComponent(0.95).cgColor
        ]
        gradientLayer.locations = [0.0, 1.0]
        gradientLayer.cornerRadius = 24
        gradientLayer.cornerCurve = .continuous
        backgroundView.layer.insertSublayer(gradientLayer, at: 0)
        self.gradientLayer = gradientLayer
    }
    
    private func setupIconBackground() {
        // Create a circular background for the icon
        let iconContainer = UIView()
        iconContainer.translatesAutoresizingMaskIntoConstraints = false
        iconContainer.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
        iconContainer.layer.cornerRadius = 40
        
        // Insert behind the image view
        if let imageViewSuperview = progressImageView.superview {
            imageViewSuperview.insertSubview(iconContainer, belowSubview: progressImageView)
            
            NSLayoutConstraint.activate([
                iconContainer.centerXAnchor.constraint(equalTo: progressImageView.centerXAnchor),
                iconContainer.centerYAnchor.constraint(equalTo: progressImageView.centerYAnchor),
                iconContainer.widthAnchor.constraint(equalToConstant: 80),
                iconContainer.heightAnchor.constraint(equalToConstant: 80)
            ])
        }
        
        self.iconBackgroundView = iconContainer
        
        // Style the image view
        progressImageView.tintColor = .systemBlue
        progressImageView.contentMode = .scaleAspectFit
    }
    
    private func configureContent() {
        // Set content
        progressTitleLabel.text = progressTitleText
        progressSubtitleLabel.attributedText = progressSubtitleText
        progressImageView.image = progressImage
        
        // Configure progress view based on progress value
        if let progress = progress {
            progressView.isHidden = false
            
            if progress == 1.0 {
                progressView.progressTintColor = .systemGreen
                iconBackgroundView?.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.1)
                progressImageView.tintColor = .systemGreen
            } else {
                progressView.progressTintColor = .systemBlue
                iconBackgroundView?.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
                progressImageView.tintColor = .systemBlue
            }
        } else {
            progressView.isHidden = true
        }
    }
    
    // MARK: - Animations
    
    private func animateEntrance() {
        // Success haptic
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
        
        // Animate card entrance with spring effect
        UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.8, options: .curveEaseOut) {
            self.backgroundView.transform = .identity
            self.backgroundView.alpha = 1.0
        }
        
        // Animate icon with delay
        iconBackgroundView?.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        iconBackgroundView?.alpha = 0.0
        progressImageView.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        progressImageView.alpha = 0.0
        
        UIView.animate(withDuration: 0.5, delay: 0.2, usingSpringWithDamping: 0.6, initialSpringVelocity: 1.0, options: .curveEaseOut) {
            self.iconBackgroundView?.transform = .identity
            self.iconBackgroundView?.alpha = 1.0
            self.progressImageView.transform = .identity
            self.progressImageView.alpha = 1.0
        }
        
        // Animate text with stagger
        progressTitleLabel.alpha = 0.0
        progressTitleLabel.transform = CGAffineTransform(translationX: 0, y: 20)
        
        UIView.animate(withDuration: 0.5, delay: 0.3, options: .curveEaseOut) {
            self.progressTitleLabel.alpha = 1.0
            self.progressTitleLabel.transform = .identity
        }
        
        progressSubtitleLabel.alpha = 0.0
        progressSubtitleLabel.transform = CGAffineTransform(translationX: 0, y: 20)
        
        UIView.animate(withDuration: 0.5, delay: 0.4, options: .curveEaseOut) {
            self.progressSubtitleLabel.alpha = 1.0
            self.progressSubtitleLabel.transform = .identity
        }
    }
    
    private func triggerCompletionCelebration() {
        // Success haptic
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
        
        // Scale pulse animation on icon
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.8, options: .curveEaseInOut) {
            self.iconBackgroundView?.transform = CGAffineTransform(scaleX: 1.15, y: 1.15)
            self.progressImageView.transform = CGAffineTransform(scaleX: 1.15, y: 1.15)
        } completion: { _ in
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: .curveEaseInOut) {
                self.iconBackgroundView?.transform = .identity
                self.progressImageView.transform = .identity
            }
        }
        
        // Add confetti effect
        addConfettiEffect()
    }
    
    private func addConfettiEffect() {
        let emitter = CAEmitterLayer()
        emitter.emitterPosition = CGPoint(x: backgroundView.bounds.midX, y: -20)
        emitter.emitterShape = .line
        emitter.emitterSize = CGSize(width: backgroundView.bounds.width, height: 1)
        
        let colors: [UIColor] = [.systemRed, .systemBlue, .systemGreen, .systemYellow, .systemPurple, .systemOrange]
        var cells: [CAEmitterCell] = []
        
        for color in colors {
            let cell = CAEmitterCell()
            cell.birthRate = 3
            cell.lifetime = 5.0
            cell.velocity = 150
            cell.velocityRange = 50
            cell.emissionLongitude = .pi
            cell.emissionRange = .pi / 4
            cell.spin = 2
            cell.spinRange = 3
            cell.scaleRange = 0.5
            cell.scale = 0.1
            cell.contents = createConfettiImage(color: color).cgImage
            cells.append(cell)
        }
        
        emitter.emitterCells = cells
        backgroundView.layer.addSublayer(emitter)
        self.emitterLayer = emitter
        
        // Stop emitting after a short time
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            emitter.birthRate = 0
        }
        
        // Remove layer after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) {
            emitter.removeFromSuperlayer()
        }
    }
    
    private func createConfettiImage(color: UIColor) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: 10, height: 10)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0)
        let context = UIGraphicsGetCurrentContext()!
        context.setFillColor(color.cgColor)
        context.fillEllipse(in: rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }
    
    // MARK: - Button Interactions
    
    @objc private func buttonTouchDown() {
        UIView.animate(withDuration: 0.1, delay: 0, options: .curveEaseOut) {
            self.actionButton.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }
    }
    
    @objc private func buttonTouchUp() {
        UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.8, options: .curveEaseOut) {
            self.actionButton.transform = .identity
        }
    }
}
