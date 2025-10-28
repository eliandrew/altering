import UIKit

/// Floating pill-shaped overlay that displays the current timer value
class TimerOverlayView: UIView {
    
    // MARK: - UI Elements
    
    private let containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 22
        view.clipsToBounds = true
        return view
    }()
    
    private let blurEffectView: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: .systemMaterial)
        let view = UIVisualEffectView(effect: blurEffect)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 22
        view.clipsToBounds = true
        return view
    }()
    
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(systemName: "timer")
        imageView.tintColor = .systemGreen
        return imageView
    }()
    
    private let timeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.monospacedDigitSystemFont(ofSize: 19, weight: .semibold)
        label.textColor = .label
        label.text = "00:00"
        return label
    }()
    
    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 8
        stack.distribution = .fill
        return stack
    }()
    
    // MARK: - Properties
    
    private var panGestureRecognizer: UIPanGestureRecognizer!
    private var tapGestureRecognizer: UITapGestureRecognizer!
    var onTap: (() -> Void)?
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        setupGestures()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
        setupGestures()
    }
    
    // MARK: - Setup
    
    private func setupView() {
        // Add shadow to the main view
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.15
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 8
        
        // Add blur effect as background
        addSubview(blurEffectView)
        addSubview(containerView)
        
        // Setup stack view with icon and label
        stackView.addArrangedSubview(iconImageView)
        stackView.addArrangedSubview(timeLabel)
        
        containerView.addSubview(stackView)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            // Blur effect fills the entire view
            blurEffectView.topAnchor.constraint(equalTo: topAnchor),
            blurEffectView.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurEffectView.trailingAnchor.constraint(equalTo: trailingAnchor),
            blurEffectView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // Container fills the entire view
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // Stack view with padding
            stackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 10),
            stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            stackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -10),
            
            // Icon size
            iconImageView.widthAnchor.constraint(equalToConstant: 20),
            iconImageView.heightAnchor.constraint(equalToConstant: 20)
        ])
    }
    
    private func setupGestures() {
        // Pan gesture for dragging
        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        addGestureRecognizer(panGestureRecognizer)
        
        // Tap gesture for navigation
        tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tapGestureRecognizer)
    }
    
    // MARK: - Public Methods
    
    func updateTime(_ timeString: String) {
        timeLabel.text = timeString
    }
    
    func setTimerRunning(_ isRunning: Bool) {
        UIView.animate(withDuration: 0.3) {
            self.iconImageView.tintColor = isRunning ? .systemGreen : .systemRed
        }
    }
    
    // MARK: - Gesture Handlers
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let superview = superview else { return }
        
        let translation = gesture.translation(in: superview)
        
        switch gesture.state {
        case .changed:
            // Move the view with the pan gesture
            var newCenter = center
            newCenter.x += translation.x
            newCenter.y += translation.y
            
            // Keep within bounds
            let halfWidth = bounds.width / 2
            let halfHeight = bounds.height / 2
            newCenter.x = max(halfWidth, min(superview.bounds.width - halfWidth, newCenter.x))
            newCenter.y = max(halfHeight, min(superview.bounds.height - halfHeight, newCenter.y))
            
            center = newCenter
            gesture.setTranslation(.zero, in: superview)
            
        case .ended:
            // Snap to nearest edge (left or right)
            snapToEdge()
            
        default:
            break
        }
    }
    
    @objc private func handleTap() {
        // Provide haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        // Trigger the tap callback
        onTap?()
    }
    
    private func snapToEdge() {
        guard let superview = superview else { return }
        
        let centerX = center.x
        let halfWidth = bounds.width / 2
        let padding: CGFloat = 16
        
        // Determine which edge is closer
        let snapToLeft = centerX < superview.bounds.width / 2
        let targetX = snapToLeft ? (halfWidth + padding) : (superview.bounds.width - halfWidth - padding)
        
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: .curveEaseOut) {
            self.center.x = targetX
        }
    }
    
    // MARK: - Layout
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Update corner radius based on size
        let cornerRadius = bounds.height / 2
        containerView.layer.cornerRadius = cornerRadius
        blurEffectView.layer.cornerRadius = cornerRadius
    }
}

