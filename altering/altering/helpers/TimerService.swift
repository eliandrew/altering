import UIKit

/// Singleton service that manages the timer state globally
class TimerService {
    
    static let shared = TimerService()
    
    // MARK: - Properties
    
    private var timer: Timer?
    private(set) var elapsedMilliseconds: Int = 0
    private(set) var isTimerRunning = false
    
    // Background timing properties
    private var startTimestamp: Date?
    private var backgroundTimestamp: Date?
    
    // MARK: - Notifications
    
    static let timerDidUpdateNotification = Notification.Name("TimerDidUpdate")
    static let timerStateDidChangeNotification = Notification.Name("TimerStateDidChange")
    
    // MARK: - Init
    
    private init() {
        setupAppLifecycleNotifications()
    }
    
    // MARK: - Lifecycle
    
    private func setupAppLifecycleNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    @objc private func appWillResignActive() {
        if isTimerRunning {
            // Store the timestamp when going to background
            backgroundTimestamp = Date()
        }
    }
    
    @objc private func appDidBecomeActive() {
        // If timer was running in background, calculate elapsed time
        if isTimerRunning, let backgroundTime = backgroundTimestamp, let startTime = startTimestamp {
            let now = Date()
            let backgroundDuration = now.timeIntervalSince(backgroundTime)
            
            // Add the background time to elapsed milliseconds
            elapsedMilliseconds += Int(backgroundDuration * 1000)
            
            // Reset the start timestamp to account for the elapsed time
            startTimestamp = now
            backgroundTimestamp = nil
            
            // Update UI
            postUpdateNotification()
        }
    }
    
    // MARK: - Public Methods
    
    func startTimer() {
        guard timer == nil else { return }
        
        // Store the start timestamp for background tracking
        startTimestamp = Date()
        backgroundTimestamp = nil
        
        timer = Timer.scheduledTimer(timeInterval: 0.001, target: self, selector: #selector(timerDidFire), userInfo: nil, repeats: true)
        isTimerRunning = true
        postStateChangeNotification()
    }
    
    func stopTimer() {
        timer?.invalidate()
        timer = nil
        isTimerRunning = false
        
        // Clear timestamps when stopped
        startTimestamp = nil
        backgroundTimestamp = nil
        
        postStateChangeNotification()
    }
    
    func resetTimer() {
        stopTimer()
        elapsedMilliseconds = 0
        postUpdateNotification()
    }
    
    func toggleTimer() {
        if isTimerRunning {
            stopTimer()
        } else {
            startTimer()
        }
    }
    
    // MARK: - Timer Formatting
    
    func getFormattedTime() -> (minutes: Int, seconds: Int) {
        let minutes = (elapsedMilliseconds % 3600000) / 60000
        let seconds = (elapsedMilliseconds % 60000) / 1000
        return (minutes, seconds)
    }
    
    func getFormattedTimeString() -> String {
        let (minutes, seconds) = getFormattedTime()
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // MARK: - Private Methods
    
    @objc private func timerDidFire() {
        elapsedMilliseconds += 1
        postUpdateNotification()
    }
    
    private func postUpdateNotification() {
        NotificationCenter.default.post(
            name: TimerService.timerDidUpdateNotification,
            object: self,
            userInfo: [
                "elapsedMilliseconds": elapsedMilliseconds,
                "formattedTime": getFormattedTimeString()
            ]
        )
    }
    
    private func postStateChangeNotification() {
        NotificationCenter.default.post(
            name: TimerService.timerStateDidChangeNotification,
            object: self,
            userInfo: [
                "isRunning": isTimerRunning,
                "elapsedMilliseconds": elapsedMilliseconds
            ]
        )
    }
}

