import UIKit

class WorkoutProgramTableViewController: UITableViewController {
    
    let EDIT_WORKOUT_PROGRAM_SEGUE_IDENTIFIER = "editWorkoutProgramSegue"
    let WORKOUT_PROGRAM_CELL_IDENTIFIER = "workoutProgramCellIdentifier"
    let WORKOUT_PROGRAM_HEADER_VIEW_IDENTIFIER = "workoutProgramHeaderViewIdentifier"
    
    let WORKOUT_PLAN_SEGUE = "workoutPlanSegue"
    
    var programDataSource = WorkoutProgramTableViewDataSource()
    
    let dataLoader = DataLoader.shared
    
    private var hasAnimatedCells = false
    
    // MARK: - View Lifecycle
    
    @objc func addProgram() {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        self.performSegue(withIdentifier: EDIT_WORKOUT_PROGRAM_SEGUE_IDENTIFIER, sender: nil)
    }
    
    func setupView() {
        // Modern navigation bar setup
        setupNavigationBar()
        
        // Register cells
        self.tableView.register(UINib(nibName: "WorkoutProgramTableViewCell", bundle: nil), forCellReuseIdentifier: WORKOUT_PROGRAM_CELL_IDENTIFIER)
        tableView.register(UINib(nibName: "ButtonHeaderView", bundle: nil), forHeaderFooterViewReuseIdentifier: WORKOUT_PROGRAM_HEADER_VIEW_IDENTIFIER)
        
        // Modern table view styling
        setupTableViewStyle()
        
        // Load data
        loadPrograms()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.setupView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Animate cells on first appearance
        if !hasAnimatedCells && programDataSource.programs.count > 0 {
            animateCellsEntrance()
            hasAnimatedCells = true
        }
    }
    
    // MARK: - Modern UI Setup
    
    private func setupNavigationBar() {
        // Set title
        title = "Programs"
        
        // Enable large titles
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        
        // Modern add button with SF Symbol
        let addButton = UIBarButtonItem(
            image: UIImage(systemName: "plus.circle.fill"),
            style: .plain,
            target: self,
            action: #selector(addProgram)
        )
        addButton.tintColor = .systemBlue
        navigationItem.rightBarButtonItem = addButton
    }
    
    private func setupTableViewStyle() {
        // Use modern inset grouped style for card-like appearance
        if #available(iOS 13.0, *) {
            tableView.backgroundColor = .systemGroupedBackground
        }
        
        // Remove separators - we'll add custom ones in cells
        tableView.separatorStyle = .none
        
        // Add spacing between sections
        tableView.sectionHeaderTopPadding = 10
        
        // Smooth scrolling
        tableView.contentInsetAdjustmentBehavior = .automatic
        
        // Remove footer
        tableView.tableFooterView = UIView()
    }
    
    private func loadPrograms() {
        dataLoader.loadAllWorkoutPrograms(completion: { result in
            switch result {
            case .success(let fetchedPrograms):
                self.programDataSource.setPrograms(fetchedPrograms)
                DispatchQueue.main.async {
                    self.updateBackgroundView()
                    self.tableView.reloadData()
                }
            case .failure(let error):
                print("Error fetching programs: \(error)")
                self.programDataSource.setPrograms([])
                DispatchQueue.main.async {
                    self.updateBackgroundView()
                    self.tableView.reloadData()
                }
            }
        })
    }
    
    // MARK: - Table View Data Source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.programDataSource.numberOfSections(tableView)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.programDataSource.numberOfRowsInSection(tableView, section: section)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.programDataSource.cellForRowAtIndexPath(tableView, indexPath: indexPath)
        
        // Apply modern styling to cell
        if let programCell = cell as? WorkoutProgramTableViewCell {
            programCell.applyModernStyling()
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50.0 // Increased for modern spacing
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: WORKOUT_PROGRAM_HEADER_VIEW_IDENTIFIER) as? ButtonHeaderView else {
            return nil
        }
        
        // Configure header
        headerView.title.text = self.programDataSource.titleForSection(section)
        headerView.buttonRight.tag = section
        headerView.buttonRight.addTarget(self, action: #selector(removeProgramPressed), for: .touchUpInside)
        headerView.buttonCenter.tag = section
        headerView.buttonCenter.addTarget(self, action: #selector(editProgramPressed), for: .touchUpInside)
        headerView.buttonLeft.isHidden = !(self.programDataSource.programForIndexPath(IndexPath(row: 0, section: section))?.isComplete() ?? false)
        
        // Apply modern styling
        headerView.applyModernStyling()
        
        return headerView
    }
    
    // MARK: - Table View Delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
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
        
        tableView.deselectRow(at: indexPath, animated: true)
        self.performSegue(withIdentifier: WORKOUT_PLAN_SEGUE, sender: indexPath)
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // Add subtle entrance animation for cells
        if !hasAnimatedCells {
            cell.alpha = 0
            cell.transform = CGAffineTransform(translationX: 0, y: 20)
        }
    }
    
    override func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            let editAction = UIAction(title: "Edit", image: UIImage(systemName: "pencil")) { [weak self] _ in
                self?.editProgramAtIndexPath(indexPath)
            }
            
            let deleteAction = UIAction(title: "Delete", image: UIImage(systemName: "trash"), attributes: .destructive) { [weak self] _ in
                self?.deleteProgramAtIndexPath(indexPath)
            }
            
            return UIMenu(title: "", children: [editAction, deleteAction])
        }
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
    
    // MARK: - Empty State
    
    @objc func backgroundTapped() {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        self.performSegue(withIdentifier: EDIT_WORKOUT_PROGRAM_SEGUE_IDENTIFIER, sender: self)
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
        imageView.image = UIImage(systemName: "doc.text.fill")
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .systemBlue
        iconContainer.addSubview(imageView)

        // Create the main label
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "No Programs Yet"
        titleLabel.textColor = .label
        titleLabel.textAlignment = .center
        titleLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        containerView.addSubview(titleLabel)

        // Create the subtitle
        let subtitleLabel = UILabel()
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.text = "Create your first workout program\nto start training"
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0
        subtitleLabel.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        containerView.addSubview(subtitleLabel)

        // Create action button
        let actionButton = UIButton(type: .system)
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        var buttonConfig = UIButton.Configuration.filled()
        buttonConfig.title = "Create Program"
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
        if self.programDataSource.programs.count == 0 {
            tableView.backgroundView = createBackgroundView()
        } else {
            tableView.backgroundView = nil
        }
    }
    
    // MARK: - Actions
    
    @objc func editProgramPressed(_ sender: Any?) {
        guard let sender = sender as? UIButton else { return }
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        let index = sender.tag
        let program = self.programDataSource.programs[index]
        self.performSegue(withIdentifier: EDIT_WORKOUT_PROGRAM_SEGUE_IDENTIFIER, sender: program)
    }
    
    @objc func removeProgramPressed(_ sender: Any?) {
        guard let sender = sender as? UIButton else { return }
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        let index = sender.tag
        showDeleteConfirmation(for: index)
    }
    
    private func editProgramAtIndexPath(_ indexPath: IndexPath) {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        let program = self.programDataSource.programs[indexPath.section]
        self.performSegue(withIdentifier: EDIT_WORKOUT_PROGRAM_SEGUE_IDENTIFIER, sender: program)
    }
    
    private func deleteProgramAtIndexPath(_ indexPath: IndexPath) {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        showDeleteConfirmation(for: indexPath.section)
    }
    
    private func showDeleteConfirmation(for index: Int) {
        let program = self.programDataSource.programs[index]
        let programName = program.name ?? "this program"
        
        let alertController = UIAlertController(
            title: "Delete Program",
            message: "Are you sure you want to delete \"\(programName)\"? This action cannot be undone.",
            preferredStyle: .actionSheet
        )
        
        // Delete action
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            self?.deleteProgram(at: index)
        }
        
        // Cancel action
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alertController.addAction(deleteAction)
        alertController.addAction(cancelAction)
        
        // For iPad - set source view
        if let popoverController = alertController.popoverPresentationController {
            if let headerView = tableView.headerView(forSection: index) {
                popoverController.sourceView = headerView
                popoverController.sourceRect = headerView.bounds
            }
        }
        
        present(alertController, animated: true)
    }
    
    private func deleteProgram(at index: Int) {
        // Haptic feedback for deletion
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
        
        let program = self.programDataSource.programs[index]
        
        // Delete from Core Data
        self.dataLoader.deleteWorkoutProgram(program)
        self.dataLoader.saveContext()
        
        // Remove from data source
        self.programDataSource.removeProgram(at: index)
        
        // Animate deletion
        self.tableView.performBatchUpdates({
            self.tableView.deleteSections(IndexSet(integer: index), with: .fade)
        }) { _ in
            // Update background view after deletion
            self.updateBackgroundView()
            
            // Reload remaining sections with animation
            if self.programDataSource.programs.count > 0 {
                UIView.animate(withDuration: 0.3) {
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    func showAlert(title: String, message: String, okActionCompletion: @escaping () -> Void) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "Delete", style: .destructive) { _ in
            okActionCompletion()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alertController.addAction(okAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == WORKOUT_PLAN_SEGUE {
            let vc = segue.destination as? WorkoutPlanTableViewController
            if let indexPath = sender as? IndexPath, let plan = self.programDataSource.planForIndexPath(indexPath), let program = self.programDataSource.programForIndexPath(indexPath), let workouts = program.workoutsForPlan(plan) {
                vc?.workoutPlan = plan
                vc?.program = program
                vc?.workouts = workouts
            }
        } else if segue.identifier == EDIT_WORKOUT_PROGRAM_SEGUE_IDENTIFIER {
            let vc = segue.destination as? EditWorkoutProgramTableViewController
            if let program = sender as? WorkoutProgram {
                vc?.workoutProgram = program
            }
        }
    }

    
}
