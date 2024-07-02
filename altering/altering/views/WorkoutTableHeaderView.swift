import UIKit

class WorkoutTableHeaderView: UIView {

    @IBOutlet weak var streakView: WorkoutStreakView?
    @IBOutlet weak var restDayView: WorkoutRestDayView?
    
    @IBOutlet weak var streakViewHeightConstraint: NSLayoutConstraint?
    @IBOutlet weak var restDayViewHeightConstraint: NSLayoutConstraint?
    
}
