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
    private var justCompletedWorkout: Workout?
    private var justAddedWorkout: Workout?
    
    // Store all fetched workouts before filtering
    private var allFetchedWorkouts: [Workout] = []
    
    // Future workouts toggle
    private var showFutureWorkouts: Bool = true {
        didSet {
            UserDefaults.standard.set(showFutureWorkouts, forKey: "showFutureWorkouts")
            filterAndReloadWorkouts()
            updateFilterButton()
        }
    }
    
    // MARK: - Actions
    
    @objc func addWorkout() {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        performSegue(withIdentifier: WORKOUT_SEGUE_IDENTIFIER, sender: nil)
    }
    
    @objc func toggleFutureWorkouts() {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        showFutureWorkouts.toggle()
    }
    
    @objc func scrollToToday() {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Find the section for today
        for section in 0..<workoutDataSource.numberOfSections(tableView) {
            if workoutDataSource.isSectionToday(section) {
                tableView.scrollToRow(at: IndexPath(row: 0, section: section), at: .top, animated: true)
                
                // Add a subtle highlight animation to the section header
                if let headerView = tableView.headerView(forSection: section) {
                    let originalBackgroundColor = headerView.backgroundColor
                    UIView.animate(withDuration: 0.3, animations: {
                        headerView.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
                    }) { _ in
                        UIView.animate(withDuration: 0.5, delay: 0.3, options: .curveEaseOut) {
                            headerView.backgroundColor = originalBackgroundColor
                        }
                    }
                }
                return
            }
        }
        
        // If today not found, show a brief message
        let alert = UIAlertController(title: nil, message: "No workouts found for today", preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            alert.dismiss(animated: true)
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
        
        // Load saved preference
        showFutureWorkouts = UserDefaults.standard.object(forKey: "showFutureWorkouts") as? Bool ?? true
    }
    
    private func filterAndReloadWorkouts() {
        guard !allFetchedWorkouts.isEmpty else { return }
        
        let filteredWorkouts: [Workout]
        if showFutureWorkouts {
            filteredWorkouts = allFetchedWorkouts
        } else {
            // Filter out future workouts (workouts with dates after today)
            let today = Calendar.current.startOfDay(for: Date())
            filteredWorkouts = allFetchedWorkouts.filter { workout in
                guard let workoutDate = workout.date else { return true }
                let workoutDay = Calendar.current.startOfDay(for: workoutDate)
                return workoutDay <= today
            }
        }
        
        workoutDataSource.setWorkouts(filteredWorkouts)
        
        // Animate the reload
        UIView.transition(with: tableView,
                        duration: 0.3,
                        options: .transitionCrossDissolve,
                        animations: {
            self.tableView.reloadData()
        })
    }
    
    private func updateFilterButton() {
        let futureIcon = showFutureWorkouts ? "eye.fill" : "eye.slash.fill"
        let filterButton = UIBarButtonItem(
            image: UIImage(systemName: futureIcon),
            style: .plain,
            target: self,
            action: #selector(toggleFutureWorkouts)
        )
        filterButton.tintColor = showFutureWorkouts ? .systemBlue : .systemGray
        
        navigationItem.leftBarButtonItem = filterButton
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
        
        // Create filter button
        let futureIcon = showFutureWorkouts ? "eye.fill" : "eye.slash.fill"
        let filterButton = UIBarButtonItem(
            image: UIImage(systemName: futureIcon),
            style: .plain,
            target: self,
            action: #selector(toggleFutureWorkouts)
        )
        filterButton.tintColor = showFutureWorkouts ? .systemBlue : .systemGray
        
        navigationItem.leftBarButtonItem = filterButton
        
        // Set title - we'll use the standard title for large title mode
        title = "Workouts"
        
        // Create a tappable title button for the regular (collapsed) navigation bar
        let titleButton = UIButton(type: .system)
        titleButton.setTitle("Workouts", for: .normal)
        titleButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 17)
        titleButton.setTitleColor(.label, for: .normal)
        titleButton.addTarget(self, action: #selector(titleTapped), for: .touchUpInside)
        titleButton.sizeToFit()
        navigationItem.titleView = titleButton
        
        // Enable large titles
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .automatic
        
        // Hide toolbar if it was previously shown
        navigationController?.setToolbarHidden(true, animated: false)
    }
    
    @objc private func titleTapped() {
        scrollToToday()
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
                // Store all workouts in our property for filtering
                self.allFetchedWorkouts = fetchedWorkouts
                
                // Apply filtering based on showFutureWorkouts setting
                let filteredWorkouts: [Workout]
                if self.showFutureWorkouts {
                    filteredWorkouts = fetchedWorkouts
                } else {
                    let today = Calendar.current.startOfDay(for: Date())
                    filteredWorkouts = fetchedWorkouts.filter { workout in
                        guard let workoutDate = workout.date else { return true }
                        let workoutDay = Calendar.current.startOfDay(for: workoutDate)
                        return workoutDay <= today
                    }
                }
                
                self.workoutDataSource.setWorkouts(filteredWorkouts)
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
                self.allFetchedWorkouts = []
                self.workoutDataSource.setWorkouts([])
                DispatchQueue.main.async {
                    self.updateBackgroundView()
                    self.tableView.reloadData()
                }
            }
        }
        
        if let workout = updatedWorkout {
            // Only show progress screen if there's an actual milestone
            if shouldShowProgressScreen(for: workout) {
                self.handleUpdatedWorkout(workout)
            }
            updatedWorkout = nil
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(workoutUpdated), name: .workoutUpdate, object: nil)
        setupView()
        
        // Add tap gesture to table view header to scroll to today
        // This works when the large title is visible
        let headerTapGesture = UITapGestureRecognizer(target: self, action: #selector(titleTapped))
        headerTapGesture.delegate = self
        tableView.addGestureRecognizer(headerTapGesture)
        
        // Set up tab bar behavior
        tabBarController?.delegate = self
    }
    
    // Override scroll to top behavior to scroll to today instead
    override func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        scrollToToday()
        return false // Prevent default scroll to top
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
        
        // Play addition animation if a workout was just added
        if let addedWorkout = justAddedWorkout {
            animateWorkoutAddition(addedWorkout)
            justAddedWorkout = nil
        }
        
        // Play completion animation if a workout was just completed
        if let completedWorkout = justCompletedWorkout {
            animateWorkoutCompletion(completedWorkout)
            justCompletedWorkout = nil
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
            
            // Set background color after styling - gray for uncompleted program workouts
            // tag=1 means it's an uncompleted program workout (set in data source)
            if multiIconCell.tag == 1 {
                multiIconCell.contentView.backgroundColor = .systemGray6
                multiIconCell.contentView.layer.cornerRadius = 12
                multiIconCell.contentView.layer.masksToBounds = true
            } else {
                // Reset corner radius for reused cells
                multiIconCell.contentView.layer.cornerRadius = 0
            }
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
        titleLabel.font = UIFont.systemFont(ofSize: 21, weight: .bold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Add today icon if this section is today
        var todayIcon: UIImageView?
        if self.workoutDataSource.isSectionToday(section) {
            // Set text color to match icon for Today section
            titleLabel.textColor = .systemBlue
            
            let iconView = UIImageView()
            let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .bold)
            iconView.image = UIImage(systemName: "calendar.badge.clock", withConfiguration: config)
            iconView.tintColor = .systemBlue
            iconView.translatesAutoresizingMaskIntoConstraints = false
            iconView.contentMode = .scaleAspectFit
            headerView.addSubview(iconView)
            todayIcon = iconView
        } else {
            titleLabel.textColor = .label
        }
        
        // Add the label
        headerView.addSubview(titleLabel)
        
        // Create add workout button for this section
        let addButton = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
        addButton.setImage(UIImage(systemName: "plus.circle.fill", withConfiguration: config), for: .normal)
        addButton.tag = section
        addButton.addTarget(self, action: #selector(addWorkoutForSection(_:)), for: .touchUpInside)
        addButton.translatesAutoresizingMaskIntoConstraints = false
        addButton.tintColor = .systemGreen
        
        // Add touch animations
        addButton.addTarget(self, action: #selector(buttonTouchDown(_:)), for: .touchDown)
        addButton.addTarget(self, action: #selector(buttonTouchUp(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        
        headerView.addSubview(addButton)
        
        // Check if there are any uncompleted workouts in this section
        let hasUncompletedWorkouts = self.workoutDataSource.workoutsForSection(section)?.contains { !$0.completed } ?? false
        
        // Only create and add the move button if there are uncompleted workouts
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
            
            // Setup constraints with both buttons
            if let todayIcon = todayIcon {
                NSLayoutConstraint.activate([
                    titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
                    titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
                    
                    todayIcon.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 8),
                    todayIcon.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
                    todayIcon.widthAnchor.constraint(equalToConstant: 20),
                    todayIcon.heightAnchor.constraint(equalToConstant: 20),
                    
                    addButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -50),
                    addButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
                    addButton.widthAnchor.constraint(equalToConstant: 24),
                    addButton.heightAnchor.constraint(equalToConstant: 24),
                    
                    moveButton.trailingAnchor.constraint(equalTo: addButton.leadingAnchor, constant: -12),
                    moveButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
                    moveButton.widthAnchor.constraint(equalToConstant: 28),
                    moveButton.heightAnchor.constraint(equalToConstant: 28),
                    moveButton.leadingAnchor.constraint(greaterThanOrEqualTo: todayIcon.trailingAnchor, constant: 8)
                ])
            } else {
                NSLayoutConstraint.activate([
                    titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
                    titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
                    
                    addButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -50),
                    addButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
                    addButton.widthAnchor.constraint(equalToConstant: 24),
                    addButton.heightAnchor.constraint(equalToConstant: 24),
                    
                    moveButton.trailingAnchor.constraint(equalTo: addButton.leadingAnchor, constant: -12),
                    moveButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
                    moveButton.widthAnchor.constraint(equalToConstant: 28),
                    moveButton.heightAnchor.constraint(equalToConstant: 28),
                    moveButton.leadingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor, constant: 8)
                ])
            }
        } else {
            // Setup constraints with just add button
            if let todayIcon = todayIcon {
                NSLayoutConstraint.activate([
                    titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
                    titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
                    
                    todayIcon.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 8),
                    todayIcon.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
                    todayIcon.widthAnchor.constraint(equalToConstant: 20),
                    todayIcon.heightAnchor.constraint(equalToConstant: 20),
                    
                    addButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -50),
                    addButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
                    addButton.widthAnchor.constraint(equalToConstant: 24),
                    addButton.heightAnchor.constraint(equalToConstant: 24),
                    addButton.leadingAnchor.constraint(greaterThanOrEqualTo: todayIcon.trailingAnchor, constant: 8)
                ])
            } else {
                NSLayoutConstraint.activate([
                    titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
                    titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
                    
                    addButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -50),
                    addButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
                    addButton.widthAnchor.constraint(equalToConstant: 24),
                    addButton.heightAnchor.constraint(equalToConstant: 24),
                    addButton.leadingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor, constant: 8)
                ])
            }
        }
        
        return headerView
    }
    
    @objc func addWorkoutForSection(_ sender: UIButton) {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        let section = sender.tag
        
        // Get the date for this section
        guard let workouts = self.workoutDataSource.workoutsForSection(section),
              let sectionDate = workouts.first?.date else {
            return
        }
        
        // Trigger the segue with the date
        performSegue(withIdentifier: WORKOUT_SEGUE_IDENTIFIER, sender: sectionDate)
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
        
        // Animate the section before moving
        animateMoveWorkouts(section: section)
        
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
                            // Animate the reload
                            UIView.transition(with: self.tableView,
                                            duration: 0.3,
                                            options: .transitionCrossDissolve,
                                            animations: {
                                self.tableView.reloadData()
                            })
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
            footerView?.restDaysLabel?.font = UIFont.systemFont(ofSize: 19, weight: .medium)
            
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
    
    private func animateWorkoutAddition(_ workout: Workout) {
        // Light haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Find the cell for this workout
        guard let indexPath = findIndexPath(for: workout),
              let cell = tableView.cellForRow(at: indexPath) else {
            return
        }
        
        // Scroll to the cell if needed
        tableView.scrollToRow(at: indexPath, at: .middle, animated: true)
        
        // Wait a moment for scroll to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.performAdditionAnimation(at: cell)
        }
    }
    
    private func animateWorkoutCompletion(_ workout: Workout) {
        // Success haptic feedback
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
        
        // Find the cell for this workout
        guard let indexPath = findIndexPath(for: workout),
              let cell = tableView.cellForRow(at: indexPath) else {
            return
        }
        
        // Scroll to the cell if needed
        tableView.scrollToRow(at: indexPath, at: .middle, animated: true)
        
        // Wait a moment for scroll to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.performCelebrationAnimation(at: cell)
        }
    }
    
    private func findIndexPath(for workout: Workout) -> IndexPath? {
        for section in 0..<workoutDataSource.numberOfSections(tableView) {
            if let workouts = workoutDataSource.workoutsForSection(section) {
                if let row = workouts.firstIndex(where: { $0 == workout }) {
                    let rowsInSection = workoutDataSource.numberOfRowsInSection(tableView, section: section)
                    // Check if this row is actually displayed (not hidden by collapse)
                    if row < rowsInSection {
                        return IndexPath(row: row, section: section)
                    }
                }
            }
        }
        return nil
    }
    
    private func performAdditionAnimation(at cell: UITableViewCell) {
        // Create overlay container
        let overlayView = UIView(frame: tableView.bounds)
        overlayView.backgroundColor = .clear
        overlayView.isUserInteractionEnabled = false
        tableView.addSubview(overlayView)
        
        // Get cell position in table view
        let cellFrame = tableView.convert(cell.frame, to: tableView)
        
        // Create plus icon
        let iconContainer = UIView()
        iconContainer.frame = CGRect(x: cellFrame.midX - 35, y: cellFrame.midY - 35, width: 70, height: 70)
        iconContainer.backgroundColor = UIColor.systemBlue
        iconContainer.layer.cornerRadius = 35
        iconContainer.alpha = 0
        iconContainer.transform = CGAffineTransform(scaleX: 0.3, y: 0.3)
        
        let iconView = UIImageView()
        iconView.frame = CGRect(x: 12, y: 12, width: 46, height: 46)
        let config = UIImage.SymbolConfiguration(pointSize: 30, weight: .bold)
        iconView.image = UIImage(systemName: "plus", withConfiguration: config)
        iconView.tintColor = .white
        iconView.contentMode = .scaleAspectFit
        iconContainer.addSubview(iconView)
        
        overlayView.addSubview(iconContainer)
        
        // Create sparkle particles
        let particleColors: [UIColor] = [.systemBlue, .systemCyan, .systemTeal, .systemIndigo]
        let particleSymbols = ["star.fill", "sparkle", "plus.circle.fill"]
        
        var particleViews: [UIView] = []
        for _ in 0..<12 {
            let particle = UIImageView()
            let symbolConfig = UIImage.SymbolConfiguration(pointSize: CGFloat.random(in: 14...20), weight: .bold)
            particle.image = UIImage(systemName: particleSymbols.randomElement()!, withConfiguration: symbolConfig)
            particle.tintColor = particleColors.randomElement()!
            particle.frame = CGRect(x: cellFrame.midX - 8, y: cellFrame.midY - 8, width: 16, height: 16)
            particle.alpha = 0
            overlayView.addSubview(particle)
            particleViews.append(particle)
        }
        
        // Animate plus icon
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.55, initialSpringVelocity: 0.9, options: .curveEaseOut) {
            iconContainer.alpha = 1.0
            iconContainer.transform = CGAffineTransform(scaleX: 1.15, y: 1.15)
        } completion: { _ in
            UIView.animate(withDuration: 0.25) {
                iconContainer.transform = .identity
            }
        }
        
        // Animate sparkle particles
        for (index, particle) in particleViews.enumerated() {
            let angle = (CGFloat(index) / CGFloat(particleViews.count)) * 2.0 * .pi
            let distance = CGFloat.random(in: 70...120)
            let tx = cos(angle) * distance
            let ty = sin(angle) * distance
            
            UIView.animate(withDuration: 0.7, delay: 0.15, options: .curveEaseOut) {
                particle.alpha = 1.0
                particle.transform = CGAffineTransform(translationX: tx, y: ty).rotated(by: CGFloat.random(in: -1.5...1.5))
            } completion: { _ in
                UIView.animate(withDuration: 0.25) {
                    particle.alpha = 0
                    particle.transform = particle.transform.translatedBy(x: tx * 0.2, y: ty * 0.2)
                }
            }
        }
        
        // Cell bounce animation with highlight
        let originalBackground = cell.backgroundColor
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut) {
            cell.transform = CGAffineTransform(scaleX: 1.04, y: 1.04)
            cell.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
        } completion: { _ in
            UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.8, options: .curveEaseOut) {
                cell.transform = .identity
            }
            UIView.animate(withDuration: 0.3, delay: 0.1, options: .curveEaseOut) {
                cell.backgroundColor = originalBackground
            }
        }
        
        // Clean up after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
            UIView.animate(withDuration: 0.25, animations: {
                iconContainer.alpha = 0
                iconContainer.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
            }) { _ in
                overlayView.removeFromSuperview()
            }
        }
    }
    
    private func performCelebrationAnimation(at cell: UITableViewCell) {
        // Create overlay container
        let overlayView = UIView(frame: tableView.bounds)
        overlayView.backgroundColor = .clear
        overlayView.isUserInteractionEnabled = false
        tableView.addSubview(overlayView)
        
        // Get cell position in table view
        let cellFrame = tableView.convert(cell.frame, to: tableView)
        
        // Create checkmark icon
        let iconContainer = UIView()
        iconContainer.frame = CGRect(x: cellFrame.midX - 40, y: cellFrame.midY - 40, width: 80, height: 80)
        iconContainer.backgroundColor = UIColor.systemGreen
        iconContainer.layer.cornerRadius = 40
        iconContainer.alpha = 0
        iconContainer.transform = CGAffineTransform(scaleX: 0.3, y: 0.3)
        
        let iconView = UIImageView()
        iconView.frame = CGRect(x: 15, y: 15, width: 50, height: 50)
        let config = UIImage.SymbolConfiguration(pointSize: 35, weight: .bold)
        iconView.image = UIImage(systemName: "checkmark", withConfiguration: config)
        iconView.tintColor = .white
        iconView.contentMode = .scaleAspectFit
        iconContainer.addSubview(iconView)
        
        overlayView.addSubview(iconContainer)
        
        // Create particles
        let particleColors: [UIColor] = [.systemGreen, .systemBlue, .systemYellow, .systemOrange, .systemPink]
        let particleSymbols = ["star.fill", "sparkle", "heart.fill", "flame.fill"]
        
        var particleViews: [UIView] = []
        for i in 0..<15 {
            let particle = UIImageView()
            let symbolConfig = UIImage.SymbolConfiguration(pointSize: CGFloat.random(in: 12...24), weight: .bold)
            particle.image = UIImage(systemName: particleSymbols.randomElement()!, withConfiguration: symbolConfig)
            particle.tintColor = particleColors.randomElement()!
            particle.frame = CGRect(x: cellFrame.midX - 10, y: cellFrame.midY - 10, width: 20, height: 20)
            particle.alpha = 0
            overlayView.addSubview(particle)
            particleViews.append(particle)
        }
        
        // Animate checkmark
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.8, options: .curveEaseOut) {
            iconContainer.alpha = 1.0
            iconContainer.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
        } completion: { _ in
            UIView.animate(withDuration: 0.2) {
                iconContainer.transform = .identity
            }
        }
        
        // Animate particles
        for (index, particle) in particleViews.enumerated() {
            let angle = (CGFloat(index) / CGFloat(particleViews.count)) * 2.0 * .pi
            let distance = CGFloat.random(in: 80...150)
            let tx = cos(angle) * distance
            let ty = sin(angle) * distance
            
            UIView.animate(withDuration: 0.8, delay: 0.1, options: .curveEaseOut) {
                particle.alpha = 1.0
                particle.transform = CGAffineTransform(translationX: tx, y: ty).rotated(by: CGFloat.random(in: -2...2))
            } completion: { _ in
                UIView.animate(withDuration: 0.3) {
                    particle.alpha = 0
                    particle.transform = particle.transform.translatedBy(x: tx * 0.3, y: ty * 0.3)
                }
            }
        }
        
        // Cell pulse animation
        UIView.animate(withDuration: 0.15, delay: 0, options: .curveEaseOut) {
            cell.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
        } completion: { _ in
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.8, options: .curveEaseOut) {
                cell.transform = .identity
            }
        }
        
        // Clean up after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            UIView.animate(withDuration: 0.3, animations: {
                iconContainer.alpha = 0
                iconContainer.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
            }) { _ in
                overlayView.removeFromSuperview()
            }
        }
    }
    
    private func animateMoveWorkouts(section: Int) {
        // Create overlay container
        let overlayView = UIView(frame: tableView.bounds)
        overlayView.backgroundColor = .clear
        overlayView.isUserInteractionEnabled = false
        tableView.addSubview(overlayView)
        
        // Get all visible cells in this section
        var cellsInSection: [UITableViewCell] = []
        let rowCount = tableView.numberOfRows(inSection: section)
        for row in 0..<rowCount {
            let indexPath = IndexPath(row: row, section: section)
            if let cell = tableView.cellForRow(at: indexPath) {
                cellsInSection.append(cell)
            }
        }
        
        // Get section header position
        if let headerView = tableView.headerView(forSection: section) {
            let headerFrame = tableView.convert(headerView.frame, to: tableView)
            
            // Create forward arrow particles
            let particleColors: [UIColor] = [.systemBlue, .systemCyan, .systemTeal]
            let arrowSymbols = ["arrow.forward.fill", "arrow.right", "chevron.forward"]
            
            var particleViews: [UIView] = []
            for i in 0..<8 {
                let particle = UIImageView()
                let symbolConfig = UIImage.SymbolConfiguration(pointSize: CGFloat.random(in: 16...24), weight: .bold)
                particle.image = UIImage(systemName: arrowSymbols.randomElement()!, withConfiguration: symbolConfig)
                particle.tintColor = particleColors.randomElement()!
                particle.frame = CGRect(x: headerFrame.maxX - 50, y: headerFrame.midY - 10, width: 20, height: 20)
                particle.alpha = 0
                overlayView.addSubview(particle)
                particleViews.append(particle)
            }
            
            // Animate arrow particles moving right
            for (index, particle) in particleViews.enumerated() {
                let delay = Double(index) * 0.05
                let distance = CGFloat.random(in: 100...200)
                
                UIView.animate(withDuration: 0.5, delay: delay, options: .curveEaseOut) {
                    particle.alpha = 1.0
                    particle.transform = CGAffineTransform(translationX: distance, y: CGFloat.random(in: -30...30))
                } completion: { _ in
                    UIView.animate(withDuration: 0.2) {
                        particle.alpha = 0
                    }
                }
            }
        }
        
        // Animate cells sliding right
        for (index, cell) in cellsInSection.enumerated() {
            let originalCenter = cell.center
            let originalBackground = cell.backgroundColor
            
            UIView.animate(withDuration: 0.3, delay: Double(index) * 0.05, options: .curveEaseOut) {
                cell.transform = CGAffineTransform(translationX: 30, y: 0)
                cell.alpha = 0.7
                cell.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.05)
            } completion: { _ in
                UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut) {
                    cell.transform = .identity
                    cell.alpha = 1.0
                    cell.backgroundColor = originalBackground
                }
            }
        }
        
        // Clean up overlay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            overlayView.removeFromSuperview()
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
        titleLabel.font = UIFont.systemFont(ofSize: 27, weight: .bold)
        containerView.addSubview(titleLabel)

        // Create the subtitle
        let subtitleLabel = UILabel()
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.text = "Track your first workout\nto start your fitness journey"
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0
        subtitleLabel.font = UIFont.systemFont(ofSize: 20, weight: .regular)
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
            } else if let date = sender as? Date {
                // When sender is a Date, set it as the selected date for a new workout
                vc?.selectedDate = date
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
            
            // Check if this is a new workout
            if let isNewWorkout = userInfo["isNewWorkout"] as? Bool, isNewWorkout {
                justAddedWorkout = workout
            }
            
            // Check if workout just got completed
            if let originalCompletion = userInfo["originalCompletion"] as? Bool,
               !originalCompletion && workout.completed {
                justCompletedWorkout = workout
            }
        }
    }
    
    func shouldShowProgressScreen(for workout: Workout) -> Bool {
        // Check if there's a meaningful progress milestone to show
        guard workout.program != nil,
              let _ = workout.progress(),
              let progressPointHit = workout.progressPointHit() else {
            return false
        }
        
        // Show progress screen for actual milestones or program completion
        if let program = workout.program, let programCompleted = program.isComplete(), programCompleted {
            return true
        }
        
        // Show for specific milestone percentages (0%, 25%, 50%, 75%, 100%)
        return progressPointHit != nil
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

extension WorkoutTableViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // Only recognize taps in the navigation bar area (approximately top 100 points)
        let location = touch.location(in: tableView)
        return location.y < 100
    }
}

extension WorkoutTableViewController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        // If tapping on the already selected tab (this view controller)
        if viewController == navigationController || viewController == self {
            if tabBarController.selectedViewController == navigationController || tabBarController.selectedViewController == self {
                scrollToToday()
            }
        }
        return true
    }
}
