import UIKit

/// Singleton service that manages the timer state globally
class TimerService {
    
    static let shared = TimerService()
    
    // MARK: - Properties
    
    private var timer: Timer?
    private(set) var elapsedMilliseconds: Int = 0
    private(set) var isTimerRunning = false
    
    // MARK: - Notifications
    
    static let timerDidUpdateNotification = Notification.Name("TimerDidUpdate")
    static let timerStateDidChangeNotification = Notification.Name("TimerStateDidChange")
    
    // MARK: - Init
    
    private init() {}
    
    // MARK: - Public Methods
    
    func startTimer() {
        guard timer == nil else { return }
        
        timer = Timer.scheduledTimer(timeInterval: 0.001, target: self, selector: #selector(timerDidFire), userInfo: nil, repeats: true)
        isTimerRunning = true
        postStateChangeNotification()
    }
    
    func stopTimer() {
        timer?.invalidate()
        timer = nil
        isTimerRunning = false
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

