import UIKit

class WorkoutDayViewTableViewController: UITableViewController {

    let WORKOUT_CELL_IDENTIFIER = "workoutCellIdentifier"
    let EXPAND_WORKOUT_CELL_IDENTIFIER = "expandWorkoutCell"
    let WORKOUT_FOOTER_VIEW_IDENTIFIER = "workoutFooterView"
    let WORKOUT_REST_DAY_FOOTER_VIEW_IDENTIFIER = "restDayFooterView"
    
    var workouts: [Workout] = []
    var workoutDataSource = WorkoutTableViewDataSource()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        workoutDataSource.isPreview = true
        
        tableView.register(UINib(nibName: "WorkoutFooterView", bundle: nil), forHeaderFooterViewReuseIdentifier: WORKOUT_FOOTER_VIEW_IDENTIFIER)
        tableView.register(UINib(nibName: "WorkoutRestDayView", bundle: nil), forHeaderFooterViewReuseIdentifier: WORKOUT_REST_DAY_FOOTER_VIEW_IDENTIFIER)
        tableView.register(UINib(nibName: "ExpandWorkoutsTableViewCell", bundle: nil), forCellReuseIdentifier: EXPAND_WORKOUT_CELL_IDENTIFIER)
        self.tableView.register(UINib(nibName: "MultiIconTableViewCell", bundle: nil), forCellReuseIdentifier: WORKOUT_CELL_IDENTIFIER)
        
        setupTableFooterView(with: tableView)
    }
    
    @objc func closeDayView() {
        self.dismiss(animated: true)
    }
    
    func setupTableFooterView(with tableView: UITableView) {
        // Step 1: Create the button and configure it
        let button = UIButton(type: .system)
        
        button.setTitle("Dismiss", for: .normal)
//        button.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        button.addTarget(target, action: #selector(closeDayView), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        
        // Step 2: Create a container view for the footer and add the button to it
        let footerView = UIView()
        footerView.addSubview(button)
        
        // Step 3: Center the button within the container view using Auto Layout
        NSLayoutConstraint.activate([
            button.centerXAnchor.constraint(equalTo: footerView.centerXAnchor),
            button.centerYAnchor.constraint(equalTo: footerView.centerYAnchor),
            button.heightAnchor.constraint(equalToConstant: 40), // Height for the capsule shape
            button.widthAnchor.constraint(equalToConstant: 200)
        ])
        
        // Step 4: Set the container view as the table footer view
        // Adjust the height of the footer view as needed
        footerView.frame.size.height = 120
        tableView.tableFooterView = footerView
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        workoutDataSource.setWorkouts(workouts)
        self.tableView.reloadData()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return workoutDataSource.numberOfSections(tableView)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return workoutDataSource.numberOfRowsInSection(tableView, section: section)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return self.workoutDataSource.cellForRowAtIndexPath(tableView, indexPath: indexPath)
    }
}
