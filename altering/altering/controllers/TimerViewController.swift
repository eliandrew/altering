import UIKit

class TimerViewController: UIViewController {
    
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var timerMinutesTensLabel: UILabel!
    @IBOutlet weak var timerMinutesOnesLabel: UILabel!
    @IBOutlet weak var timerSecondsTensLabel: UILabel!
    @IBOutlet weak var timerSecondsOnesLabel: UILabel!
    @IBOutlet weak var colonLabel: UILabel!

    var timer: Timer?
    var elapsedMilliseconds: Int = 0
    var isTimerRunning = false

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
    }
    
    func setLabelColors(_ color: UIColor) {
        let textLabels = [timerMinutesOnesLabel, timerMinutesTensLabel, colonLabel, timerSecondsOnesLabel, timerSecondsTensLabel]
        
        for textLabel in textLabels {
            textLabel?.textColor = color
        }
    }
    
    // Function to start the timer
    func startTimer() {
        if timer == nil {
            timer = Timer.scheduledTimer(timeInterval: 0.001, target: self, selector: #selector(timerDidFire), userInfo: nil, repeats: true)
            isTimerRunning = true
            setLabelColors(.systemGreen)
        }
    }

    @objc func resetTimer(_ sender: UILongPressGestureRecognizer) {
        if sender.state == .began { // Ensure it only triggers once per press
            stopTimer()
            elapsedMilliseconds = 0
            updateLabels()
        }
    }
    
    @objc func toggleTimer(_ sender: UITapGestureRecognizer) {
        if isTimerRunning {
            stopTimer()
        } else {
            startTimer()
        }
    }

    @objc func timerDidFire() {
        elapsedMilliseconds += 1
        updateLabels()
    }
    
    func updateLabels() {
        let minutes = (elapsedMilliseconds % 3600000) / 60000
        let seconds = (elapsedMilliseconds % 60000) / 1000
        colonLabel.text = ":"

        timerMinutesTensLabel.text = "\(minutes / 10)"
        timerMinutesOnesLabel.text = "\(minutes % 10)"
        timerSecondsTensLabel.text = "\(seconds / 10)"
        timerSecondsOnesLabel.text = "\(seconds % 10)"
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
        isTimerRunning = false
        setLabelColors(.systemRed)
    }

    deinit {
        stopTimer()
    }
}
