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
    
    private var hasAppliedModernStyling = false
    private var iconBackgroundView: UIView?
    
    func setPlanProgress() {
        // Animate progress bar with spring effect
        UIView.animate(withDuration: 0.8, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.8, options: .curveEaseOut) {
            self.progressBar.setProgress(self.progress ?? 0, animated: true)
        }
    }
    
    func setupView(workoutPlan: WorkoutPlan, workouts: [Workout]) {
        self.exerciseLabel.text = workoutPlan.exercise?.name ?? "Exercise Missing"
        let progress = Float(workouts.count) / Float(workoutPlan.numWorkouts)
        self.progress = progress
        
        if progress == 1.0 {
            self.progressBar.progressTintColor = .systemGreen
            self.remainingWorkoutCountLabel.text = "0"
            self.remainingSubtitleLabel.text = "remaining"
            self.completedWorkoutCountLabel.text = "\(workouts.count)"
            self.completedSubtitleLabel.text = "completed"
            self.detailImageView?.image = UIImage(systemName: "checkmark.circle.fill")
            self.detailImageView?.tintColor = .systemGreen
            iconBackgroundView?.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.1)
        } else {
            self.progressBar.progressTintColor = .systemBlue
            self.remainingWorkoutCountLabel.text = "\(workoutPlan.numWorkouts - Int64(workouts.count))"
            self.remainingSubtitleLabel.text = "remaining"
            self.completedWorkoutCountLabel.text = "\(workouts.count)"
            self.completedSubtitleLabel.text = "completed"
            self.detailImageView?.tintColor = .systemBlue
            iconBackgroundView?.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
        }
    }
    
    // MARK: - Modern Styling
    
    func applyModernStyling() {
        guard !hasAppliedModernStyling else { return }
        hasAppliedModernStyling = true
        
        // Modern card appearance
        backgroundColor = .systemBackground
        layer.cornerRadius = 16
        layer.cornerCurve = .continuous
        
        // Subtle shadow
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.1
        layer.shadowOffset = CGSize(width: 0, height: 4)
        layer.shadowRadius = 12
        layer.masksToBounds = false
        
        // Add subtle background for icon
        if let detailImageView = detailImageView {
            let iconContainer = UIView()
            iconContainer.translatesAutoresizingMaskIntoConstraints = false
            iconContainer.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
            iconContainer.layer.cornerRadius = 30
            
            insertSubview(iconContainer, belowSubview: detailImageView)
            
            NSLayoutConstraint.activate([
                iconContainer.centerXAnchor.constraint(equalTo: detailImageView.centerXAnchor),
                iconContainer.centerYAnchor.constraint(equalTo: detailImageView.centerYAnchor),
                iconContainer.widthAnchor.constraint(equalToConstant: 60),
                iconContainer.heightAnchor.constraint(equalToConstant: 60)
            ])
            
            self.iconBackgroundView = iconContainer
        }
        
        // Modern typography
        exerciseLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        exerciseLabel.textColor = .label
        exerciseLabel.adjustsFontForContentSizeCategory = true
        
        remainingWorkoutCountLabel.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        remainingWorkoutCountLabel.textColor = .label
        remainingWorkoutCountLabel.adjustsFontForContentSizeCategory = true
        
        remainingSubtitleLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        remainingSubtitleLabel.textColor = .secondaryLabel
        remainingSubtitleLabel.adjustsFontForContentSizeCategory = true
        
        completedWorkoutCountLabel.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        completedWorkoutCountLabel.textColor = .label
        completedWorkoutCountLabel.adjustsFontForContentSizeCategory = true
        
        completedSubtitleLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        completedSubtitleLabel.textColor = .secondaryLabel
        completedSubtitleLabel.adjustsFontForContentSizeCategory = true
        
        // Modern progress bar
        progressBar.layer.cornerRadius = 4
        progressBar.clipsToBounds = true
        progressBar.trackTintColor = UIColor.systemGray5
        progressBar.transform = CGAffineTransform(scaleX: 1, y: 2) // Make it thicker
        
        // Add padding
        layoutMargins = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
    }
}
