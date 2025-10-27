import UIKit

/// Manages the floating timer overlay window and its lifecycle
class TimerOverlayManager {
    
    static let shared = TimerOverlayManager()
    
    // Notification to inform the overlay manager about timer view controller visibility
    static let timerViewControllerVisibilityDidChange = Notification.Name("TimerViewControllerVisibilityDidChange")
    
    // MARK: - Properties
    
    private var overlayWindow: UIWindow?
    private var overlayView: TimerOverlayView?
    private var isVisible = false
    private var shouldSuppressOverlay = false
    
    // MARK: - Init
    
    private init() {
        setupNotifications()
    }
    
    // MARK: - Setup
    
    func setup(with windowScene: UIWindowScene) {
        // Create the overlay window with pass-through capability
        let window = PassThroughWindow(windowScene: windowScene)
        window.windowLevel = .statusBar + 1
        window.backgroundColor = .clear
        window.isHidden = true
        window.isUserInteractionEnabled = true
        
        // Create a root view controller (required for the window)
        let rootViewController = PassThroughViewController()
        window.rootViewController = rootViewController
        
        self.overlayWindow = window
        
        // Create the overlay view
        let overlay = TimerOverlayView()
        // Use frame-based layout for draggable view (not AutoLayout)
        overlay.translatesAutoresizingMaskIntoConstraints = true
        overlay.onTap = { [weak self] in
            self?.toggleTimer()
        }
        
        rootViewController.view.addSubview(overlay)
        
        // Position the overlay at the top-right initially using frame
        let overlayWidth: CGFloat = 110
        let overlayHeight: CGFloat = 44
        let padding: CGFloat = 16
        
        // Position will be set in showOverlay when we have the actual window bounds
        overlay.frame = CGRect(x: 0, y: 0, width: overlayWidth, height: overlayHeight)
        
        self.overlayView = overlay
        
        // Update initial state
        updateOverlayVisibility()
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(timerDidUpdate(_:)),
            name: TimerService.timerDidUpdateNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(timerStateDidChange(_:)),
            name: TimerService.timerStateDidChangeNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(timerViewControllerVisibilityDidChange(_:)),
            name: TimerOverlayManager.timerViewControllerVisibilityDidChange,
            object: nil
        )
    }
    
    // MARK: - Notification Handlers
    
    @objc private func timerDidUpdate(_ notification: Notification) {
        guard let formattedTime = notification.userInfo?["formattedTime"] as? String else { return }
        
        DispatchQueue.main.async {
            self.overlayView?.updateTime(formattedTime)
            // Update visibility in case timer was reset to 0
            self.updateOverlayVisibility()
        }
    }
    
    @objc private func timerStateDidChange(_ notification: Notification) {
        guard let isRunning = notification.userInfo?["isRunning"] as? Bool else { return }
        
        DispatchQueue.main.async {
            self.overlayView?.setTimerRunning(isRunning)
            self.updateOverlayVisibility()
        }
    }
    
    @objc private func timerViewControllerVisibilityDidChange(_ notification: Notification) {
        guard let isVisible = notification.userInfo?["isVisible"] as? Bool else { return }
        
        DispatchQueue.main.async {
            self.shouldSuppressOverlay = isVisible
            self.updateOverlayVisibility()
        }
    }
    
    // MARK: - Visibility
    
    private func updateOverlayVisibility() {
        // Show overlay if timer is running OR if there's time on the timer
        // BUT hide it if we're on the timer view controller
        let shouldShow = (TimerService.shared.isTimerRunning || TimerService.shared.elapsedMilliseconds > 0) && !shouldSuppressOverlay
        
        if shouldShow && !isVisible {
            showOverlay()
        } else if !shouldShow && isVisible {
            hideOverlay()
        }
    }
    
    private func showOverlay() {
        guard let window = overlayWindow, let overlay = overlayView else { return }
        
        // Position the overlay at top-right if this is the first time showing
        if overlay.frame.origin.x == 0 && overlay.frame.origin.y == 0 {
            let padding: CGFloat = 16
            let safeAreaTop = window.safeAreaInsets.top
            overlay.frame.origin = CGPoint(
                x: window.bounds.width - overlay.frame.width - padding,
                y: safeAreaTop + padding
            )
        }
        
        // Update the time and state before showing
        overlay.updateTime(TimerService.shared.getFormattedTimeString())
        overlay.setTimerRunning(TimerService.shared.isTimerRunning)
        
        // Animate in
        overlay.alpha = 0
        overlay.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        
        window.isHidden = false
        isVisible = true
        
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: .curveEaseOut) {
            overlay.alpha = 1
            overlay.transform = .identity
        }
    }
    
    private func hideOverlay() {
        guard let window = overlayWindow, let overlay = overlayView else { return }
        
        UIView.animate(withDuration: 0.25, animations: {
            overlay.alpha = 0
            overlay.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        }) { _ in
            window.isHidden = true
            self.isVisible = false
            overlay.transform = .identity
        }
    }
    
    // MARK: - Timer Control
    
    private func toggleTimer() {
        TimerService.shared.toggleTimer()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - PassThroughWindow

/// A window that only captures touches on the TimerOverlayView and passes through all other touches
private class PassThroughWindow: UIWindow {
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // Get the hit view from the normal hit test
        guard let hitView = super.hitTest(point, with: event) else {
            return nil
        }
        
        // Check if the hit view is or is within a TimerOverlayView
        var currentView: UIView? = hitView
        while let view = currentView {
            if view is TimerOverlayView {
                // This touch is on the timer overlay, capture it
                return hitView
            }
            currentView = view.superview
        }
        
        // Touch is not on the timer overlay, pass it through
        return nil
    }
}

// MARK: - PassThroughViewController

/// A view controller that allows touches to pass through
private class PassThroughViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
    }
}

