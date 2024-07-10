import UIKit

class WorkoutPlanTableViewCell: UITableViewCell {

    @IBOutlet weak var exerciseLabel: UILabel!
    @IBOutlet weak var workoutCountSlider: UISlider!
    @IBOutlet weak var workoutCountLabel: UILabel!
    
    
    @IBAction func sliderChanged(_ sender: Any) {
        updateWorkoutLabel()
    }
    
    func setWorkoutCount(_ count: Int64) {
        self.workoutCountSlider.value = Float(count)
        self.updateWorkoutLabel()
    }
    
    func updateWorkoutLabel() {
        let value = Int(self.workoutCountSlider.value)
        self.workoutCountLabel.text = "\(value) workout\(value == 1 ? "" : "s")"
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
}
