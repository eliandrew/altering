import UIKit

struct ProgressInfo {
    var title: String
    var subtitle: String
    var image: UIImage?
    var progress: Float
}

class WorkoutTableViewController: UITableViewController {

    // MARK: Constants
    
    let WORKOUT_CELL_IDENTIFIER = "workoutCellIdentifier"
    let EXPAND_WORKOUT_CELL_IDENTIFIER = "expandWorkoutCell"
    let WORKOUT_FOOTER_VIEW_IDENTIFIER = "workoutFooterView"
    let WORKOUT_REST_DAY_FOOTER_VIEW_IDENTIFIER = "restDayFooterView"
    
    let WORKOUT_SEGUE_IDENTIFIER = "workoutSegue"
    let PROGRESS_SEGUE_IDENTIFIER = "progressSegue"
    
    let imageNames = [
        "figure.american.football",
        "figure.archery",
        "figure.australian.football",
        "figure.badminton",
        "figure.barre",
        "figure.baseball",
        "figure.basketball",
        "figure.bowling",
        "figure.boxing",
        "figure.climbing",
        "figure.cooldown",
        "figure.core.training",
        "figure.cricket",
        "figure.skiing.crosscountry",
        "figure.cross.training",
        "figure.curling",
        "figure.dance",
        "figure.disc.sports",
        "figure.skiing.downhill",
        "figure.elliptical",
        "figure.equestrian.sports",
        "figure.fencing",
        "figure.fishing",
        "figure.flexibility",
        "figure.strengthtraining.functional",
        "figure.golf",
        "figure.gymnastics",
        "figure.hand.cycling",
        "figure.handball",
        "figure.highintensity.intervaltraining",
        "figure.hiking",
        "figure.hockey",
        "figure.hunting",
        "figure.indoor.cycle",
        "figure.jumprope",
        "figure.kickboxing",
        "figure.lacrosse",
        "figure.martial.arts",
        "figure.mind.and.body",
        "figure.mixed.cardio",
        "figure.open.water.swim",
        "figure.outdoor.cycle",
        "figure.pickleball",
        "figure.pilates",
        "figure.play",
        "figure.pool.swim",
        "figure.racquetball",
        "figure.rolling",
        "figure.rower",
        "figure.rugby",
        "figure.sailing",
        "figure.skating",
        "figure.snowboarding",
        "figure.soccer",
        "figure.socialdance",
        "figure.softball",
        "figure.squash",
        "figure.stair.stepper",
        "figure.stairs",
        "figure.step.training",
        "figure.surfing",
        "figure.table.tennis",
        "figure.taichi",
        "figure.tennis",
        "figure.track.and.field",
        "figure.strengthtraining.traditional",
        "figure.volleyball",
        "figure.water.fitness",
        "figure.waterpolo",
        "figure.wrestling",
        "figure.yoga",
        "figure.walk"
    ]
    
    // MARK: Properties
    
    var workoutDataSource = WorkoutTableViewDataSource()
    let dataLoader = DataLoader.shared
    let dataWriter = DataWriter.shared
    
    // MARK: Actions
    
    @objc func addWorkout() {
        performSegue(withIdentifier: WORKOUT_SEGUE_IDENTIFIER, sender: nil)
//        performSegue(withIdentifier: PROGRESS_SEGUE_IDENTIFIER, sender: ProgressInfo(title: "test", subtitle: "test", image: UIImage(systemName: "figure.wave"), progress: 1.0))
    }
    
    @objc func exportWorkouts() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let fileName = "workouts_\(dateFormatter.string(from: Date.now)).csv"
        let dataString = self.dataWriter.createWorkoutCSV(workouts: self.workoutDataSource.allWorkouts)
        let fileURL = self.dataWriter.writeCSV(data: dataString, to: fileName, headers: ["Date", "Name", "Group", "Notes"])
         
        if let file = fileURL {
            let activityViewController = UIActivityViewController(activityItems: [file], applicationActivities: nil)
           self.present(activityViewController, animated: true, completion: nil)
        }
    }
    
    // MARK: View Lifecycle
    
    func streakImage(_ streakLength: Int) -> UIImage? {
        let streakImageName = imageNames[streakLength % imageNames.count]
        return UIImage(systemName: streakImageName)
    }
    
    func currentRestDays() -> Int {
        guard let firstWorkout = self.workoutDataSource.workoutForIndexPath(IndexPath(row: 0, section: 0))?.date, let daysBetween = self.workoutDataSource.daysBetween(start: firstWorkout, end: Date()) else {
            return 0
        }
        return daysBetween - 1
    }
    
    func streakLength() -> Int {
        let streakRestMax = 3
        if self.currentRestDays() > streakRestMax {
            return 0
        }
        var streakLength = 1
        let nSections = self.workoutDataSource.numberOfSections(self.tableView)
        for i in 0..<nSections {
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
    
    func setupWorkoutStreakView() -> UIView? {
       
        let streakLength = self.streakLength()
        let streakView: WorkoutStreakView = WorkoutStreakView.fromNib()
        
        if streakLength > 1 {
            streakView.streakImageView?.image = streakImage(streakLength)
            streakView.streakLabel?.text = "\(streakLength) workout streak!"
    
        } else {
            streakView.streakImageView?.image = UIImage(systemName: "star.circle.fill")
            streakView.streakLabel?.text = "Start a new streak!"
        }
        
        return streakView
    }
    
    func setupView() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addWorkout))
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(exportWorkouts))
        
        tableView.register(UINib(nibName: "WorkoutFooterView", bundle: nil), forHeaderFooterViewReuseIdentifier: WORKOUT_FOOTER_VIEW_IDENTIFIER)
        tableView.register(UINib(nibName: "WorkoutRestDayView", bundle: nil), forHeaderFooterViewReuseIdentifier: WORKOUT_REST_DAY_FOOTER_VIEW_IDENTIFIER)
        tableView.register(UINib(nibName: "ExpandWorkoutsTableViewCell", bundle: nil), forCellReuseIdentifier: EXPAND_WORKOUT_CELL_IDENTIFIER)
        self.tableView.register(UINib(nibName: "MultiIconTableViewCell", bundle: nil), forCellReuseIdentifier: WORKOUT_CELL_IDENTIFIER)
        
        
        // Set the title for the large title
        title = "Workouts"

        // Enable large titles
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        tableView.tableFooterView = nil
        
        
        dataLoader.loadAllWorkouts { result in
            switch result {
            case .success(let fetchedWorkouts):
                self.workoutDataSource.setWorkouts(fetchedWorkouts)
                DispatchQueue.main.async {
                    self.tableView.tableHeaderView = self.setupWorkoutStreakView()
                    self.tableView.reloadData()
                }
            case .failure(let error):
                print("Error fetching exercises: \(error)")
                self.workoutDataSource.setWorkouts([])
                DispatchQueue.main.async {
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
        if let workout = self.workoutDataSource.workoutForIndexPath(indexPath) {
            performSegue(withIdentifier: WORKOUT_SEGUE_IDENTIFIER, sender: workout)
        } else {
            self.workoutDataSource.toggleExpandSection(indexPath.section)
            self.tableView.reloadSections(IndexSet(integer: indexPath.section), with: .automatic)
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.workoutDataSource.titleForSection(section)
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if let restDays = self.workoutDataSource.restDaysForSection(tableView, section: section) {
            let footerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: WORKOUT_FOOTER_VIEW_IDENTIFIER) as? WorkoutFooterView
            footerView?.restDaysLabel?.font = UIFont.systemFont(ofSize: 25.0)
            footerView?.restDaysLabel.text = restDays
            return footerView
        } else {
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if let _ = self.workoutDataSource.restDaysForSection(tableView, section: section) {
            return 75.0
        } else {
            return 0.0
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40.0
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
            vc?.delegate = self
            if let workout = sender as? Workout {
                vc?.workout = workout
                vc?.originalWorkoutProgram = workout.program
            }
        } else if segue.identifier == PROGRESS_SEGUE_IDENTIFIER , let progressInfo = sender as? ProgressInfo {
            let vc = segue.destination as? ProgramProgressViewController
            vc?.progressTitleText = progressInfo.title
            vc?.progressSubtitleText = progressInfo.subtitle
            vc?.progressImage = progressInfo.image
            vc?.progress = progressInfo.progress
        }
    }
    
    func basicAlertController(title: String, message: String) -> UIAlertController {
        let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .cancel))
        return ac
    }
}

extension WorkoutTableViewController: EditWorkoutDelegate {
    func didUpdateWorkoutProgram(_ workout: Workout) {
        if let progress = workout.progress(), let progressPointHit = workout.progressPointHit() {
            let isOver = progress > progressPointHit
            var (title, message) = ("Congrats!", "You're\(isOver ? " over" : "") \(Int(progressPointHit * 100))% done with \(workout.exercise?.name ?? "Exercise") in \(workout.program?.name ?? "Workout Program")")
            var image = UIImage(systemName: imageNames.randomElement() ?? "figure.wave")
            if (progressPointHit == 0.0) {
                (title, message) = ("Woohoo!", "That was your first workout for \(workout.exercise?.name ?? "Exercise") in \(workout.program?.name ?? "Workout Program")")
            } else if (progressPointHit == 1.0) {
                (title, message) = ("Boom!", "You just finished \(workout.exercise?.name ?? "Exercise") in \(workout.program?.name ?? "Workout Program")")
                image = UIImage(systemName: "star.circle.fill")
            }
            
            if let program = workout.program, let programCompleted = program.isComplete(), programCompleted {
                let progressInfo = ProgressInfo(title: "Program Complete!", subtitle: "You just completed \(program.name ?? "Workout Program")", image: UIImage(systemName: "trophy.circle.fill"), progress: progress)
                self.performSegue(withIdentifier: PROGRESS_SEGUE_IDENTIFIER, sender: progressInfo)
            } else {
                let progressInfo = ProgressInfo(title: title, subtitle: message, image: image, progress: progress)
                self.performSegue(withIdentifier: PROGRESS_SEGUE_IDENTIFIER, sender: progressInfo)
            }
                        
            
        }
    }
}
