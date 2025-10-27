import UIKit

struct ProgressInfo {
    var title: String
    var subtitle: NSAttributedString
    var image: UIImage?
    var progress: Float?
}

class WorkoutTableViewController: UITableViewController {

    // MARK: - Constants
    
    let STREAK_REST_MAX = 3
    
    let WORKOUT_CELL_IDENTIFIER = "workoutCellIdentifier"
    let EXPAND_WORKOUT_CELL_IDENTIFIER = "expandWorkoutCell"
    let WORKOUT_FOOTER_VIEW_IDENTIFIER = "workoutFooterView"
    let WORKOUT_REST_DAY_FOOTER_VIEW_IDENTIFIER = "restDayFooterView"
    
    let WORKOUT_SEGUE_IDENTIFIER = "workoutSegue"
    let PROGRESS_SEGUE_IDENTIFIER = "progressSegue"
    let STREAK_CALENDAR_SEGUE_IDENTIFIER = "streakCalendarSegue"
    
    // MARK: - Properties
    
    let searchController = UISearchController(searchResultsController: nil)
    
    var workoutDataSource = WorkoutTableViewDataSource()
    let dataLoader = DataLoader.shared
    let dataWriter = DataWriter.shared
    
    var updatedWorkout: Workout?
    var restPeriods: [RestPeriod]?
    
    private var hasAnimatedCells = false
    
    // MARK: - Actions
    
    @objc func addWorkout() {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        performSegue(withIdentifier: WORKOUT_SEGUE_IDENTIFIER, sender: nil)
    }
    
    @objc func exportWorkouts() {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let fileName = "workouts_\(dateFormatter.string(from: Date.now)).csv"
        let dataString = self.dataWriter.createWorkoutCSV(workouts: self.workoutDataSource.allWorkouts)
        let fileURL = self.dataWriter.writeCSV(data: dataString, to: fileName, headers: ["Date", "Name", "Group", "Notes", "Program"])
        
        if let file = fileURL {
            let activityViewController = UIActivityViewController(activityItems: [file], applicationActivities: nil)
            // For iPad
            if let popoverController = activityViewController.popoverPresentationController {
                popoverController.barButtonItem = navigationItem.leftBarButtonItem
            }
            self.present(activityViewController, animated: true, completion: nil)
        }
    }
    
    // MARK: - View Lifecycle
    
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
        
        // Modern color states based on rest days
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
        
        // Modern styling
        streakView.applyModernStyling()
        
        // Create and add the tap gesture recognizer
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(streakViewTapped))
        streakView.addGestureRecognizer(tapGestureRecognizer)
        
        return streakView
    }
    
    func setupView() {
        setupNavigationBar()
        setupTableViewStyle()
        registerCells()
        loadData()
    }
    
    private func setupNavigationBar() {
        // Modern navigation buttons
        let addButton = UIBarButtonItem(
            image: UIImage(systemName: "plus.circle.fill"),
            style: .plain,
            target: self,
            action: #selector(addWorkout)
        )
        addButton.tintColor = .systemBlue
        navigationItem.rightBarButtonItem = addButton
        
        let exportButton = UIBarButtonItem(
            image: UIImage(systemName: "square.and.arrow.up.circle.fill"),
            style: .plain,
            target: self,
            action: #selector(exportWorkouts)
        )
        exportButton.tintColor = .systemBlue
        navigationItem.leftBarButtonItem = exportButton
        
        // Set title
        title = "Workouts"
        
        // Enable large titles
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .automatic
    }
    
    private func setupTableViewStyle() {
        // Modern grouped style
        if #available(iOS 13.0, *) {
            tableView.backgroundColor = .systemGroupedBackground
        }
        
        // Remove separators for modern card look
        tableView.separatorStyle = .none
        
        // Better spacing
        tableView.sectionHeaderTopPadding = 10
        
        tableView.tableFooterView = nil
    }
    
    private func registerCells() {
        tableView.register(UINib(nibName: "WorkoutFooterView", bundle: nil), forHeaderFooterViewReuseIdentifier: WORKOUT_FOOTER_VIEW_IDENTIFIER)
        tableView.register(UINib(nibName: "WorkoutRestDayView", bundle: nil), forHeaderFooterViewReuseIdentifier: WORKOUT_REST_DAY_FOOTER_VIEW_IDENTIFIER)
        tableView.register(UINib(nibName: "ExpandWorkoutsTableViewCell", bundle: nil), forCellReuseIdentifier: EXPAND_WORKOUT_CELL_IDENTIFIER)
        tableView.register(UINib(nibName: "MultiIconTableViewCell", bundle: nil), forCellReuseIdentifier: WORKOUT_CELL_IDENTIFIER)
    }
    
    private func loadData() {
        
        
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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Animate cells on first appearance
        if !hasAnimatedCells && workoutDataSource.allWorkouts.count > 0 {
            animateCellsEntrance()
            hasAnimatedCells = true
        }
    }

    // MARK: - Table View Data Source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.workoutDataSource.numberOfSections(tableView)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.workoutDataSource.numberOfRowsInSection(tableView, section: section)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) ->UITableViewCell {
        let cell = self.workoutDataSource.cellForRowAtIndexPath(tableView, indexPath: indexPath)
        
        // Apply modern styling to custom cells
        if let multiIconCell = cell as? MultiIconTableViewCell {
            multiIconCell.applyModernStyling()
        }
        
        return cell
    }
    
    // MARK: - Table View Delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if let workout = self.workoutDataSource.workoutForIndexPath(indexPath) {
            // Haptic feedback
            let selectionFeedback = UISelectionFeedbackGenerator()
            selectionFeedback.selectionChanged()
            
            // Animate cell selection
            if let cell = tableView.cellForRow(at: indexPath) {
                UIView.animate(withDuration: 0.1, delay: 0, options: .curveEaseOut, animations: {
                    cell.transform = CGAffineTransform(scaleX: 0.97, y: 0.97)
                }) { _ in
                    UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.8, options: .curveEaseOut) {
                        cell.transform = .identity
                    }
                }
            }
            
            performSegue(withIdentifier: WORKOUT_SEGUE_IDENTIFIER, sender: workout)
        } else {
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            
            self.workoutDataSource.toggleExpandSection(indexPath.section)
            self.tableView.reloadSections(IndexSet(integer: indexPath.section), with: .automatic)
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // Add subtle entrance animation for cells
        if !hasAnimatedCells {
            cell.alpha = 0
            cell.transform = CGAffineTransform(translationX: 0, y: 20)
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return nil // We're using viewForHeaderInSection instead
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        // Create a container view for the header
        let headerView = UIView()
        headerView.backgroundColor = .clear
        
        // Create the date label with modern styling
        let titleLabel = UILabel()
        titleLabel.text = self.workoutDataSource.titleForSection(section)
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        titleLabel.textColor = .label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Add the label
        headerView.addSubview(titleLabel)
        
        // Check if there are any uncompleted workouts in this section
        let hasUncompletedWorkouts = self.workoutDataSource.workoutsForSection(section)?.contains { !$0.completed } ?? false
        
        // Only create and add the button if there are uncompleted workouts
        if hasUncompletedWorkouts {
            // Create modern button
            let moveButton = UIButton(type: .system)
            let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)
            moveButton.setImage(UIImage(systemName: "arrow.forward.circle.fill", withConfiguration: config), for: .normal)
            moveButton.tag = section
            moveButton.addTarget(self, action: #selector(moveWorkoutsOneDayLater(_:)), for: .touchUpInside)
            moveButton.translatesAutoresizingMaskIntoConstraints = false
            moveButton.tintColor = .systemBlue
            
            // Add touch animations
            moveButton.addTarget(self, action: #selector(buttonTouchDown(_:)), for: .touchDown)
            moveButton.addTarget(self, action: #selector(buttonTouchUp(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
            
            // Add the button
            headerView.addSubview(moveButton)
            
            // Setup constraints with button
            NSLayoutConstraint.activate([
                titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
                titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
                
                moveButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -45),
                moveButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
                moveButton.widthAnchor.constraint(equalToConstant: 28),
                moveButton.heightAnchor.constraint(equalToConstant: 28),
                moveButton.leadingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor, constant: 8)
            ])
        } else {
            // Setup constraints without button
            NSLayoutConstraint.activate([
                titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
                titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
                titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: headerView.trailingAnchor, constant: -16)
            ])
        }
        
        return headerView
    }
    
    @objc func moveWorkoutsOneDayLater(_ sender: UIButton) {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        let section = sender.tag
        
        // Get all workouts in this section
        guard let workouts = self.workoutDataSource.workoutsForSection(section) else {
            return
        }
        
        // Move only workouts that have a program (workout plan) one day later
        for workout in workouts {
            // Only move workouts that are part of a program
            if workout.program != nil, let currentDate = workout.date {
                workout.date = Calendar.current.date(byAdding: .day, value: 1, to: currentDate)
            }
        }
        
        // Save the context
        dataLoader.saveContext { result in
            switch result {
            case .success:
                // Reload all workouts to refresh the data source
                self.dataLoader.loadAllWorkouts { result in
                    switch result {
                    case .success(let fetchedWorkouts):
                        self.workoutDataSource.setWorkouts(fetchedWorkouts)
                        DispatchQueue.main.async {
                            self.tableView.reloadData()
                        }
                    case .failure(let error):
                        print("Error reloading workouts: \(error)")
                    }
                }
            case .failure(let error):
                print("Error saving workouts: \(error)")
            }
        }
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
            footerView?.restDaysLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
            
            if let restPeriod = self.restPeriodForSection(section) {
                footerView?.restDaysLabel.text = "\(restPeriod.explanation ?? "") (\(restDays))"
            } else {
                footerView?.restDaysLabel.text = restDays
            }
            
            footerView?.tag = section
            footerView?.applyModernStyling()
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
            } else if workoutsInSection.count < self.workoutDataSource.MAX_WORKOUTS ||  self.workoutDataSource.workoutSection(indexPath.section)?.isExpanded ?? false {
                tableView.deleteRows(at: [indexPath], with: .automatic)
            } else {
                tableView.reloadSections(IndexSet(integer: indexPath.section), with: .automatic)
            }
        }
    }
    
    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return self.workoutDataSource.sectionIndexTitles()
    }
    
    override func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        return self.workoutDataSource.sectionForSectionIndexTitle(title, at: index)
    }
    
    // MARK: - Animations
    
    private func animateCellsEntrance() {
        let cells = tableView.visibleCells
        
        for (index, cell) in cells.enumerated() {
            cell.alpha = 0
            cell.transform = CGAffineTransform(translationX: 0, y: 30)
            
            UIView.animate(
                withDuration: 0.5,
                delay: Double(index) * 0.05,
                usingSpringWithDamping: 0.8,
                initialSpringVelocity: 0.5,
                options: .curveEaseOut
            ) {
                cell.alpha = 1.0
                cell.transform = .identity
            }
        }
    }
    
    @objc private func buttonTouchDown(_ sender: UIButton) {
        UIView.animate(withDuration: 0.1, delay: 0, options: .curveEaseOut) {
            sender.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }
    }
    
    @objc private func buttonTouchUp(_ sender: UIButton) {
        UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.8, options: .curveEaseOut) {
            sender.transform = .identity
        }
    }
    
    // MARK: - Empty State
    
    @objc func streakViewTapped() {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        self.performSegue(withIdentifier: STREAK_CALENDAR_SEGUE_IDENTIFIER, sender: nil)
    }
    
    @objc func backgroundTapped() {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        self.performSegue(withIdentifier: WORKOUT_SEGUE_IDENTIFIER, sender: nil)
    }
    
    func createBackgroundView() -> UIView {
        let backgroundView = UIView(frame: UIScreen.main.bounds)
        backgroundView.backgroundColor = .clear

        // Container for better layout
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.addSubview(containerView)

        // Icon container with circular background
        let iconContainer = UIView()
        iconContainer.translatesAutoresizingMaskIntoConstraints = false
        iconContainer.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
        iconContainer.layer.cornerRadius = 60
        containerView.addSubview(iconContainer)

        // Create the image view
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(systemName: "figure.strengthtraining.traditional")
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .systemBlue
        iconContainer.addSubview(imageView)

        // Create the main label
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "No Workouts Yet"
        titleLabel.textColor = .label
        titleLabel.textAlignment = .center
        titleLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        containerView.addSubview(titleLabel)

        // Create the subtitle
        let subtitleLabel = UILabel()
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.text = "Track your first workout\nto start your fitness journey"
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0
        subtitleLabel.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        containerView.addSubview(subtitleLabel)

        // Create action button
        let actionButton = UIButton(type: .system)
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        var buttonConfig = UIButton.Configuration.filled()
        buttonConfig.title = "Add Workout"
        buttonConfig.image = UIImage(systemName: "plus.circle.fill")
        buttonConfig.imagePlacement = .leading
        buttonConfig.imagePadding = 8
        buttonConfig.cornerStyle = .large
        buttonConfig.baseBackgroundColor = .systemBlue
        buttonConfig.baseForegroundColor = .white
        buttonConfig.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 24, bottom: 14, trailing: 24)
        actionButton.configuration = buttonConfig
        actionButton.addTarget(self, action: #selector(backgroundTapped), for: .touchUpInside)
        containerView.addSubview(actionButton)

        // Layout constraints
        NSLayoutConstraint.activate([
            // Container
            containerView.centerXAnchor.constraint(equalTo: backgroundView.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: backgroundView.centerYAnchor, constant: -50),
            containerView.leadingAnchor.constraint(greaterThanOrEqualTo: backgroundView.leadingAnchor, constant: 40),
            containerView.trailingAnchor.constraint(lessThanOrEqualTo: backgroundView.trailingAnchor, constant: -40),
            
            // Icon container
            iconContainer.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            iconContainer.topAnchor.constraint(equalTo: containerView.topAnchor),
            iconContainer.widthAnchor.constraint(equalToConstant: 120),
            iconContainer.heightAnchor.constraint(equalToConstant: 120),
            
            // Image view
            imageView.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 60),
            imageView.heightAnchor.constraint(equalToConstant: 60),
            
            // Title
            titleLabel.topAnchor.constraint(equalTo: iconContainer.bottomAnchor, constant: 24),
            titleLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            
            // Subtitle
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            subtitleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            
            // Action button
            actionButton.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 28),
            actionButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            actionButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])

        // Add subtle entrance animation
        containerView.alpha = 0
        containerView.transform = CGAffineTransform(translationX: 0, y: 30)
        
        UIView.animate(withDuration: 0.8, delay: 0.1, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: .curveEaseOut) {
            containerView.alpha = 1.0
            containerView.transform = .identity
        }

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
                vc?.originalCompletion = workout.completed
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
            vc?.workouts = workoutDataSource.workoutsByDate.mapValues({$0.workouts.filter { w in
                w.completed
            }})
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
