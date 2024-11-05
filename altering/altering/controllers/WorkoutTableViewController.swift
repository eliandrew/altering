import UIKit

struct ProgressInfo {
    var title: String
    var subtitle: NSAttributedString
    var image: UIImage?
    var progress: Float?
}

class WorkoutTableViewController: UITableViewController {

    // MARK: Constants
    
    let STREAK_REST_MAX = 3
    
    let WORKOUT_CELL_IDENTIFIER = "workoutCellIdentifier"
    let EXPAND_WORKOUT_CELL_IDENTIFIER = "expandWorkoutCell"
    let WORKOUT_FOOTER_VIEW_IDENTIFIER = "workoutFooterView"
    let WORKOUT_REST_DAY_FOOTER_VIEW_IDENTIFIER = "restDayFooterView"
    
    let WORKOUT_SEGUE_IDENTIFIER = "workoutSegue"
    let PROGRESS_SEGUE_IDENTIFIER = "progressSegue"
    let STREAK_CALENDAR_SEGUE_IDENTIFIER = "streakCalendarSegue"
    
    // MARK: Properties
    
    let searchController = UISearchController(searchResultsController: nil)
    
    var workoutDataSource = WorkoutTableViewDataSource()
    let dataLoader = DataLoader.shared
    let dataWriter = DataWriter.shared
    
    var updatedWorkout: Workout?
    
    var restPeriods: [RestPeriod]?
    
    // MARK: Actions
    
    @objc func addWorkout() {
        performSegue(withIdentifier: WORKOUT_SEGUE_IDENTIFIER, sender: nil)
    }
    
    @objc func exportWorkouts() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let fileName = "workouts_\(dateFormatter.string(from: Date.now)).csv"
        let dataString = self.dataWriter.createWorkoutCSV(workouts: self.workoutDataSource.allWorkouts)
        let fileURL = self.dataWriter.writeCSV(data: dataString, to: fileName, headers: ["Date", "Name", "Group", "Notes", "Program"])
        
        if let file = fileURL {
            let activityViewController = UIActivityViewController(activityItems: [file], applicationActivities: nil)
           self.present(activityViewController, animated: true, completion: nil)
        }
        
    }
    
    // MARK: View Lifecycle
    
    func currentRestDays() -> Int {
        guard let firstWorkout = self.workoutDataSource.workoutForIndexPath(IndexPath(row: 0, section: 0))?.date, let daysBetween = self.workoutDataSource.daysBetween(start: firstWorkout, end: Date()) else {
            return 0
        }
        return daysBetween - 1
    }
    
    func streakLength() -> Int {
        return self.workoutDataSource.streakLength(maxRestDays: STREAK_REST_MAX)
    }
    
    func setupWorkoutStreakView() -> UIView? {
       
        let longestStreakLength = UserDefaults.standard.integer(forKey: "maxStreakLength")
        let streakLength = self.streakLength()
        let streakView: WorkoutStreakView = WorkoutStreakView.fromNib()
        
        if streakLength > 1 {
            streakView.streakImageView?.image = streakImage(streakLength)
            streakView.streakLabel?.text = "\(streakLength) workout streak!"
    
        } else {
            streakView.streakImageView?.image = UIImage(systemName: "star.circle.fill")
            streakView.streakLabel?.text = "Start a new streak!"
        }
        
        switch STREAK_REST_MAX - self.currentRestDays() {
        case 0:
            streakView.streakImageView.tintColor = .systemRed
            streakView.streakLabel.textColor = .systemRed
            streakView.longestStreakImageView.tintColor = .systemRed
        case 1:
            streakView.streakImageView.tintColor = .systemYellow
            streakView.streakLabel.textColor = .systemYellow
            streakView.longestStreakImageView.tintColor = .systemYellow
        default:
            streakView.streakImageView.tintColor = .systemBlue
            streakView.streakLabel.textColor = .label
            streakView.longestStreakImageView.tintColor = .systemBlue
        }
        
        streakView.longestStreakImageView.isHidden = streakLength <= 1 || streakLength < longestStreakLength
        if streakLength > longestStreakLength {
            UserDefaults.standard.set(streakLength, forKey: "maxStreakLength")
        }
        
        // Create and add the tap gesture recognizer
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(streakViewTapped))
        streakView.addGestureRecognizer(tapGestureRecognizer)
        
        return streakView
    }
    
    func setupView() {
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addWorkout))
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(exportWorkouts))
        
        tableView.register(UINib(nibName: "WorkoutFooterView", bundle: nil), forHeaderFooterViewReuseIdentifier: WORKOUT_FOOTER_VIEW_IDENTIFIER)
        tableView.register(UINib(nibName: "WorkoutRestDayView", bundle: nil), forHeaderFooterViewReuseIdentifier: WORKOUT_REST_DAY_FOOTER_VIEW_IDENTIFIER)
        tableView.register(UINib(nibName: "ExpandWorkoutsTableViewCell", bundle: nil), forCellReuseIdentifier: EXPAND_WORKOUT_CELL_IDENTIFIER)
        self.tableView.register(UINib(nibName: "MultiIconTableViewCell", bundle: nil), forCellReuseIdentifier: WORKOUT_CELL_IDENTIFIER)
        
//        searchController.searchResultsUpdater = self
//        searchController.obscuresBackgroundDuringPresentation = false
//        searchController.searchBar.placeholder = "Search"
//        navigationItem.searchController = searchController
//        definesPresentationContext = true
        
        
        // Set the title for the large title
        title = "Workouts"

        // Enable large titles
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .automatic
        tableView.tableFooterView = nil
        
        
        dataLoader.loadAllWorkouts { result in
            switch result {
            case .success(let fetchedWorkouts):
                self.workoutDataSource.setWorkouts(fetchedWorkouts)
                self.dataLoader.loadAllRestPeriods { result in
                    switch result {
                    case .success(let fetchedRestPeriods):
                        self.restPeriods = fetchedRestPeriods
                        DispatchQueue.main.async {
                            self.longestStreakNotification()
                            self.tableView.tableHeaderView = self.setupWorkoutStreakView()
                            self.updateBackgroundView()
                            self.tableView.reloadData()
                        }
                    case .failure(let error):
                        print("Error fetching rest periods: \(error)")
                        DispatchQueue.main.async {
                            self.longestStreakNotification()
                            self.tableView.tableHeaderView = self.setupWorkoutStreakView()
                            self.updateBackgroundView()
                            self.tableView.reloadData()
                        }
                    }
                }
                
            case .failure(let error):
                print("Error fetching exercises: \(error)")
                self.workoutDataSource.setWorkouts([])
                DispatchQueue.main.async {
                    self.updateBackgroundView()
                    self.tableView.reloadData()
                }
            }
        }
        
        if let workout = updatedWorkout {
            print("HANDLING UPDATED WORKOUT")
            self.handleUpdatedWorkout(workout)
            updatedWorkout = nil
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(workoutUpdated), name: .workoutUpdate, object: nil)
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
    
    func restPeriodForSection(_ section: Int) -> RestPeriod? {
//        if let (startDate, endDate) = self.workoutDataSource.restDaysDatesForSection(self.tableView, section: section) {
//            return self.restPeriods?.first(where: { rp in
//                rp.startDate == startDate && rp.endDate == endDate
//            })
//        } else {
//            return nil
//        }
        return nil
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if let restDays = self.workoutDataSource.restDaysForSection(tableView, section: section) {
            let footerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: WORKOUT_FOOTER_VIEW_IDENTIFIER) as? WorkoutFooterView
            footerView?.restDaysLabel?.font = UIFont.systemFont(ofSize: 20.0)
            
            if let restPeriod = self.restPeriodForSection(section) {
                footerView?.restDaysLabel.text = "\(restPeriod.explanation ?? "") (\(restDays))"
            } else {
                footerView?.restDaysLabel.text = restDays
            }
            
            // Add long press gesture recognizer to the footer view
            let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleFooterLongPress(_:)))
//            footerView?.addGestureRecognizer(longPressGesture)
            footerView?.tag = section
            return footerView
        } else {
            return nil
        }
    }
    
    @objc func handleFooterLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .began {
            if let footerView = gestureRecognizer.view as? WorkoutFooterView, let (startDate, endDate) = self.workoutDataSource.restDaysDatesForSection(self.tableView, section: footerView.tag) {
                if let alertController = addRestPeriodViewController(startDate: startDate, endDate: endDate, restPeriod: self.restPeriodForSection(footerView.tag)) {
                    self.present(alertController, animated: true)
                }
            }
        }
    }
    
    func addRestPeriodViewController(startDate: Date, endDate: Date, restPeriod: RestPeriod?) -> UIAlertController? {
        let alertController = UIAlertController(title: "Rest Period Explanation", message: nil, preferredStyle: .alert)
        alertController.addTextField()
        alertController.textFields![0].text = restPeriod?.explanation
        let submitAction = UIAlertAction(title: "Add", style: .default) { [unowned alertController] _ in
            let newExplanation = alertController.textFields![0].text
            if let restPeriod {
                restPeriod.explanation = newExplanation
            } else {
                let newRestPeriod = self.dataLoader.createNewRestPeriod()
                newRestPeriod.explanation = newExplanation
                newRestPeriod.startDate = startDate
                newRestPeriod.endDate = endDate
            }
            self.dataLoader.saveContext()
            self.dismiss(animated: true)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alertController.addAction(cancelAction)
        alertController.addAction(submitAction)
        return alertController
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
            let workout = self.workoutDataSource.workoutForIndexPath(indexPath),
            let workoutsInSection = self.workoutDataSource.workoutsForSection(indexPath.section) {
            dataLoader.deleteWorkout(workout)
            dataLoader.saveContext()
            self.workoutDataSource.removeWorkout(at: indexPath)
            
            if workoutsInSection.count == 1 {
                tableView.deleteSections(IndexSet(integer: indexPath.section), with: .automatic)
            } else {
                tableView.deleteRows(at: [indexPath], with: .automatic)
            }
        }
    }
    
    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return self.workoutDataSource.sectionIndexTitles()
    }
    
    override func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        return self.workoutDataSource.sectionForSectionIndexTitle(title, at: index)
    }
    
    @objc func streakViewTapped() {
        self.performSegue(withIdentifier: STREAK_CALENDAR_SEGUE_IDENTIFIER, sender: nil)
    }
    
    @objc func backgroundTapped() {
        self.performSegue(withIdentifier: WORKOUT_SEGUE_IDENTIFIER, sender: nil)
    }
    
    func createBackgroundView() -> UIView {
        let backgroundView = UIView(frame: UIScreen.main.bounds)

        // Create the image view
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(systemName: "figure.strengthtraining.traditional")
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true

        // Create and add the tap gesture recognizer
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped))
        backgroundView.addGestureRecognizer(tapGestureRecognizer)

        // Create the label
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Tap for your first Workout!"
        label.textColor = .systemBlue
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 20, weight: .semibold)

        // Add the image view and label to the background view
        backgroundView.addSubview(imageView)
        backgroundView.addSubview(label)

        // Center the image view and set its size
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: backgroundView.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: backgroundView.centerYAnchor, constant: -20),
            imageView.widthAnchor.constraint(equalToConstant: 100), // Adjust the width
            imageView.heightAnchor.constraint(equalToConstant: 100) // Adjust the height
        ])

        // Center the label below the image view
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: backgroundView.centerXAnchor),
            label.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 10)
        ])

        return backgroundView
    }
    
    func updateBackgroundView() {
        if self.workoutDataSource.allWorkouts.count == 0 {
                tableView.backgroundView = createBackgroundView()
            } else {
                tableView.backgroundView = nil
            }
        }
    
    // MARK: Segues
    
   
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == WORKOUT_SEGUE_IDENTIFIER {
            let vc = segue.destination as? EditWorkoutTableViewController
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
        } else if segue.identifier == STREAK_CALENDAR_SEGUE_IDENTIFIER {
            let vc = segue.destination as? StreakViewController
            vc?.workouts = workoutDataSource.workoutsByDate.mapValues({$0.workouts})
        }
    }
    
    func basicAlertController(title: String, message: String) -> UIAlertController {
        let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .cancel))
        return ac
    }
    
    func attributedProgressSubtitle(_ fullText: String, boldTexts: [String]) -> NSAttributedString {
        let attributedString = NSMutableAttributedString(string: fullText)
        let boldRanges = boldTexts.map { text in
            (fullText as NSString).range(of: text)
        }
        let boldFont = UIFont.boldSystemFont(ofSize: 20.0)
        for boldRange in boldRanges {
            attributedString.addAttribute(.font, value: boldFont, range: boldRange)
        }
        return attributedString
    }
    
    func longestStreakNotification() {
        let longestStreakLength = UserDefaults.standard.integer(forKey: "maxStreakLength")
        let streakLength = self.streakLength()
        if streakLength > longestStreakLength {
            let attributedSubtitle = self.attributedProgressSubtitle("You just set a new streak record of \(streakLength) workout\(streakLength == 1 ? "" : "s")!", boldTexts: ["\(streakLength)"])
            let streakInfo = ProgressInfo(title: "Streak Record!", subtitle: attributedSubtitle, image: UIImage(systemName: "medal.star.fill"), progress: nil)
            self.performSegue(withIdentifier: PROGRESS_SEGUE_IDENTIFIER, sender: streakInfo)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .workoutUpdate, object: nil)
    }
    
}

extension WorkoutTableViewController {
    
    @objc func workoutUpdated(notification: Notification) {
        if let userInfo = notification.userInfo, let workout = userInfo["workout"] as? Workout {
            updatedWorkout = workout
        }
    }
    
    func handleUpdatedWorkout(_ workout: Workout) {
        if let progress = workout.progress(), let progressPointHit = workout.progressPointHit() {
            print("UPDATING INSIDE")
            let isOver = progress > progressPointHit
            var attributedMessage = self.attributedProgressSubtitle("You're\(isOver ? " over" : "") \(Int(progressPointHit * 100))% done with \(workout.exercise?.name ?? "Exercise") in \(workout.program?.name ?? "Workout Program")", boldTexts: ["\(Int(progressPointHit * 100))%", "\(workout.exercise?.name ?? "Exercise")", "\(workout.program?.name ?? "Workout Program")"])
            var (title, message) = ("Congrats!", attributedMessage)
            var image = UIImage(systemName: streakImageNames.randomElement() ?? "figure.wave")
            if (progressPointHit == 0.0) {
                attributedMessage = self.attributedProgressSubtitle("That was your first workout for \(workout.exercise?.name ?? "Exercise") in \(workout.program?.name ?? "Workout Program")", boldTexts: ["\(workout.exercise?.name ?? "Exercise")", "\(workout.program?.name ?? "Workout Program")"])
                (title, message) = ("Woohoo!", attributedMessage)
            } else if (progressPointHit == 1.0) {
                attributedMessage = self.attributedProgressSubtitle("You just finished \(workout.exercise?.name ?? "Exercise") in \(workout.program?.name ?? "Workout Program")", boldTexts: ["\(workout.exercise?.name ?? "Exercise")", "\(workout.program?.name ?? "Workout Program")"])
                (title, message) = ("Boom!", attributedMessage)
                image = UIImage(systemName: "star.circle.fill")
            }
            
            if let program = workout.program, let programCompleted = program.isComplete(), programCompleted {
                attributedMessage = self.attributedProgressSubtitle("You just completed \(program.name ?? "Workout Program")", boldTexts: ["\(program.name ?? "Workout Program")"])
                let progressInfo = ProgressInfo(title: "Program Complete!", subtitle: attributedMessage, image: UIImage(systemName: "trophy.circle.fill"), progress: progress)
                self.performSegue(withIdentifier: PROGRESS_SEGUE_IDENTIFIER, sender: progressInfo)
            } else {
                let progressInfo = ProgressInfo(title: title, subtitle: message, image: image, progress: progress)
                self.performSegue(withIdentifier: PROGRESS_SEGUE_IDENTIFIER, sender: progressInfo)
            }
        }
    }
}

extension WorkoutTableViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        if let searchText = searchController.searchBar.text, !searchText.isEmpty {
            self.workoutDataSource.setSearchText(searchText)
        } else {
            self.workoutDataSource.setSearchText(nil)
        }
        self.tableView.reloadData()
    }
}
