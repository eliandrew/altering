import UIKit

class WorkoutTableViewController: UITableViewController {

    // MARK: Constants
    
    let WORKOUT_CELL_IDENTIFIER = "workoutCell"
    let WORKOUT_FOOTER_VIEW_IDENTIFIER = "workoutFooterView"
    let WORKOUT_REST_DAY_FOOTER_VIEW_IDENTIFIER = "restDayFooterView"
    
    let WORKOUT_SEGUE_IDENTIFIER = "workoutSegue"
    
    // MARK: Properties
    
    var workoutDataSource = WorkoutTableViewDataSource()
    let dataLoader = DataLoader.shared
    
    // MARK: Actions
    
    @objc func addWorkout() {
        performSegue(withIdentifier: WORKOUT_SEGUE_IDENTIFIER, sender: nil)
    }
    
    // MARK: View Lifecycle
    
    func streakImage(_ streakLength: Int) -> UIImage? {
        let images = [
            "figure.core.training",
            "figure.mixed.cardio",
            "figure.pilates",
            "figure.cross.training",
            "figure.indoor.cycle",
            "figure.outdoor.cycle",
            "figure.yoga",
            "figure.jumprope",
            "figure.mind.and.body",
            "dumbbell",
            "figure.stair.stepper",
            "figure.play",
            "figure.step.training",
            "figure.flexibility",
            "figure.rower"
        ]
        
        let streakImageName = streakLength < images.count + 2 ? images[streakLength - 2] : "star.circle.fill"
        
        return UIImage(systemName: streakImageName)
    }
    
    func streakLength() -> Int {
        let streakRestMax = 3
        var streakLength = 1
        let nSections = self.workoutDataSource.numberOfSections(self.tableView)
        for i in 1..<nSections {
            guard let restDays = self.workoutDataSource.restDaysNumberForSection(self.tableView, section: i) else {
                return streakLength
            }
            if restDays <= streakRestMax {
                streakLength += 1
            } else {
                return streakLength
            }
        }
        return streakLength
    }
    
    func setupWorkoutStreakView() -> WorkoutStreakView? {
       
        let streakLength = self.streakLength()
        if streakLength > 1 {
            let streakView: WorkoutStreakView = WorkoutStreakView.fromNib()
            streakView.streakLabel?.text = "\(streakLength) workout streak!"
            streakView.streakImageView?.image = streakImage(streakLength)
            return streakView
        } else {
            return nil
        }
    }
    
    func setupView() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addWorkout))
        
        tableView.register(UINib(nibName: "WorkoutFooterView", bundle: nil), forHeaderFooterViewReuseIdentifier: WORKOUT_FOOTER_VIEW_IDENTIFIER)
        tableView.register(UINib(nibName: "WorkoutRestDayView", bundle: nil), forHeaderFooterViewReuseIdentifier: WORKOUT_REST_DAY_FOOTER_VIEW_IDENTIFIER)

        tableView.tableFooterView = nil
        
        
        dataLoader.loadAllWorkouts { fetchedWorkouts in
            if let fetchedWorkouts = fetchedWorkouts {
                self.workoutDataSource.setWorkouts(fetchedWorkouts)
                DispatchQueue.main.sync {
                    self.tableView.tableHeaderView = self.setupWorkoutStreakView()
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupView()
    }

    // MARK: Table View

    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.workoutDataSource.numberOfSections(tableView)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.workoutDataSource.numberOfRowsInSection(tableView, section: section)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return self.workoutDataSource.cellForRowAtIndexPath(tableView, indexPath: indexPath)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let workout = self.workoutDataSource.workoutForIndexPath(indexPath)
        performSegue(withIdentifier: WORKOUT_SEGUE_IDENTIFIER, sender: workout)
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.workoutDataSource.titleForSection(section)
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if let restDays = self.workoutDataSource.restDaysForSection(tableView, section: section) {
            if section == 0 {
                let footerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: WORKOUT_REST_DAY_FOOTER_VIEW_IDENTIFIER) as? WorkoutRestDayView
                footerView?.restingDaysLabel.text = restDays
                footerView?.restingDaysLabel?.font = UIFont.systemFont(ofSize: 25.0, weight: .semibold)
                return footerView
            } else {
                let footerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: WORKOUT_FOOTER_VIEW_IDENTIFIER) as? WorkoutFooterView
                footerView?.restDaysLabel?.font = UIFont.systemFont(ofSize: 25.0)
                footerView?.restDaysLabel.text = restDays
                return footerView
            }
        } else {
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if let _ = self.workoutDataSource.restDaysForSection(tableView, section: section) {
            return section == 0 ? 110.0 : 75.0
        } else {
            return 0.0
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if let _ = self.workoutDataSource.titleForSection(section) {
            return 40.0
        } else {
            return 0.0
        }
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete, 
            let workout = self.workoutDataSource.workoutForIndexPath(indexPath) {
            dataLoader.deleteWorkout(workout)
            dataLoader.saveContext()
            self.workoutDataSource.removeWorkout(at: indexPath)
            self.tableView.tableHeaderView = nil
            self.tableView.reloadData()
        }
    }
    
    // MARK: Segues
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == WORKOUT_SEGUE_IDENTIFIER {
            let vc = segue.destination as? EditWorkoutTableViewController
            if let workout = sender as? Workout {
                vc?.workout = workout
            }
        }
    }
}
