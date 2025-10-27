import UIKit

class TimerViewController: UIViewController {
    
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var timerMinutesTensLabel: UILabel!
    @IBOutlet weak var timerMinutesOnesLabel: UILabel!
    @IBOutlet weak var timerSecondsTensLabel: UILabel!
    @IBOutlet weak var timerSecondsOnesLabel: UILabel!
    @IBOutlet weak var colonLabel: UILabel!

    let timerService = TimerService.shared

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let textLabels = [timerMinutesOnesLabel, timerMinutesTensLabel, colonLabel, timerSecondsOnesLabel, timerSecondsTensLabel]
        
        for textLabel in textLabels {
            textLabel?.font = UIFont(name: "digital-7", size: 150.0)
            textLabel?.textColor = .systemRed
            textLabel?.transform = CGAffineTransformMakeRotation(3.14/2);
        }
        stackView.isUserInteractionEnabled = true
        stackView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(toggleTimer)))
        stackView.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(resetTimer)))
        
        // Setup notifications to listen to timer updates
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
        
        // Update UI with current timer state
        updateLabels()
        updateLabelColors()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Prevent screen from dimming or sleeping
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Allow screen to sleep again when leaving this view
        UIApplication.shared.isIdleTimerDisabled = false
    }
    
    func setLabelColors(_ color: UIColor) {
        let textLabels = [timerMinutesOnesLabel, timerMinutesTensLabel, colonLabel, timerSecondsOnesLabel, timerSecondsTensLabel]
        
        for textLabel in textLabels {
            textLabel?.textColor = color
        }
    }

    @objc func resetTimer(_ sender: UILongPressGestureRecognizer) {
        if sender.state == .began { // Ensure it only triggers once per press
            timerService.resetTimer()
            updateLabels()
        }
    }
    
    @objc func toggleTimer(_ sender: UITapGestureRecognizer) {
        timerService.toggleTimer()
    }
    
    @objc func timerDidUpdate(_ notification: Notification) {
        DispatchQueue.main.async {
            self.updateLabels()
        }
    }
    
    @objc func timerStateDidChange(_ notification: Notification) {
        DispatchQueue.main.async {
            self.updateLabelColors()
        }
    }
    
    func updateLabels() {
        let (minutes, seconds) = timerService.getFormattedTime()
        colonLabel.text = ":"

        timerMinutesTensLabel.text = "\(minutes / 10)"
        timerMinutesOnesLabel.text = "\(minutes % 10)"
        timerSecondsTensLabel.text = "\(seconds / 10)"
        timerSecondsOnesLabel.text = "\(seconds % 10)"
    }
    
    func updateLabelColors() {
        let color: UIColor = timerService.isTimerRunning ? .systemGreen : .systemRed
        setLabelColors(color)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
