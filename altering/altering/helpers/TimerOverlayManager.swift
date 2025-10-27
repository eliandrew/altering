import UIKit

/// Manages the floating timer overlay window and its lifecycle
class TimerOverlayManager {
    
    static let shared = TimerOverlayManager()
    
    // MARK: - Properties
    
    private var overlayWindow: UIWindow?
    private var overlayView: TimerOverlayView?
    private var isVisible = false
    
    // MARK: - Init
    
    private init() {
        setupNotifications()
    }
    
    // MARK: - Setup
    
    func setup(with windowScene: UIWindowScene) {
        // Create the overlay window
        let window = UIWindow(windowScene: windowScene)
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
        overlay.translatesAutoresizingMaskIntoConstraints = false
        overlay.onTap = { [weak self] in
            self?.navigateToTimerTab()
        }
        
        rootViewController.view.addSubview(overlay)
        
        // Position the overlay at the top-right initially
        let overlayWidth: CGFloat = 110
        let overlayHeight: CGFloat = 44
        let padding: CGFloat = 16
        
        NSLayoutConstraint.activate([
            overlay.widthAnchor.constraint(equalToConstant: overlayWidth),
            overlay.heightAnchor.constraint(equalToConstant: overlayHeight),
            overlay.trailingAnchor.constraint(equalTo: rootViewController.view.trailingAnchor, constant: -padding),
            overlay.topAnchor.constraint(equalTo: rootViewController.view.safeAreaLayoutGuide.topAnchor, constant: padding)
        ])
        
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
    }
    
    // MARK: - Notification Handlers
    
    @objc private func timerDidUpdate(_ notification: Notification) {
        guard let formattedTime = notification.userInfo?["formattedTime"] as? String else { return }
        
        DispatchQueue.main.async {
            self.overlayView?.updateTime(formattedTime)
        }
    }
    
    @objc private func timerStateDidChange(_ notification: Notification) {
        guard let isRunning = notification.userInfo?["isRunning"] as? Bool else { return }
        
        DispatchQueue.main.async {
            self.overlayView?.setTimerRunning(isRunning)
            self.updateOverlayVisibility()
        }
    }
    
    // MARK: - Visibility
    
    private func updateOverlayVisibility() {
        let shouldShow = TimerService.shared.isTimerRunning
        
        if shouldShow && !isVisible {
            showOverlay()
        } else if !shouldShow && isVisible {
            hideOverlay()
        }
    }
    
    private func showOverlay() {
        guard let window = overlayWindow, let overlay = overlayView else { return }
        
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
    
    // MARK: - Navigation
    
    private func navigateToTimerTab() {
        // Find the tab bar controller and switch to the timer tab
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let sceneDelegate = windowScene.delegate as? SceneDelegate,
              let window = sceneDelegate.window,
              let tabBarController = window.rootViewController as? UITabBarController else {
            return
        }
        
        // Find the timer tab (it's the 4th tab - index 3)
        if let viewControllers = tabBarController.viewControllers,
           viewControllers.count > 3 {
            tabBarController.selectedIndex = 3
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - PassThroughViewController

/// A view controller that allows touches to pass through to views behind it
private class PassThroughViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Don't call super - this allows touches to pass through
    }
    
    // Allow the overlay view to receive touches, but pass through everything else
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        for subview in view.subviews {
            if subview.frame.contains(point) {
                return true
            }
        }
        return false
    }
}

