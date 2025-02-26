import UIKit

class WorkoutPlanHeaderView: UIView {
    
    var progress: Float?

    @IBOutlet weak var exerciseLabel: UILabel!
    @IBOutlet weak var progressBar: UIProgressView!
    @IBOutlet weak var remainingWorkoutCountLabel: UILabel!
    @IBOutlet weak var remainingSubtitleLabel: UILabel!
    @IBOutlet weak var completedWorkoutCountLabel: UILabel!
    @IBOutlet weak var completedSubtitleLabel: UILabel!
    @IBOutlet weak var detailImageView: UIImageView?
    
    func setPlanProgress() {
        self.progressBar.setProgress(self.progress ?? 0, animated: false)
    }
    
    func setupView(workoutPlan: WorkoutPlan, workouts: [Workout]) {
        self.exerciseLabel.text = workoutPlan.exercise?.name ?? "Exercise Missing"
        let progress = Float(workouts.count) / Float(workoutPlan.numWorkouts)
        self.progress = progress
        if progress == 1.0 {
            self.progressBar.tintColor = .systemGreen
            self.remainingWorkoutCountLabel.text = "0"
            self.remainingSubtitleLabel.text = "remaining"
            self.completedWorkoutCountLabel.text = "\(workouts.count)"
            self.completedSubtitleLabel.text = "completed"
            self.detailImageView?.image = UIImage(systemName: "checkmark.circle.fill")
            self.detailImageView?.tintColor = .systemGreen
        } else {
            self.progressBar.tintColor = .systemBlue
            self.remainingWorkoutCountLabel.text = "\(workoutPlan.numWorkouts - Int64(workouts.count))"
            self.remainingSubtitleLabel.text = "remaining"
            self.completedWorkoutCountLabel.text = "\(workouts.count)"
            self.completedSubtitleLabel.text = "completed"
        }
    }
}
