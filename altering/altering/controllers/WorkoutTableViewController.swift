import UIKit

class WorkoutTableViewController: UITableViewController {

    // MARK: Constants
    
    let WORKOUT_CELL_IDENTIFIER = "workoutCell"
    
    let WORKOUT_SEGUE_IDENTIFIER = "workoutSegue"
    
    // MARK: Properties
    
    var workoutDataSource = WorkoutTableViewDataSource()
    let dataLoader = DataLoader.shared
    
    // MARK: Helpers
    
    func daysBetween(start: Date, end: Date) -> Int? {
        let calendar = Calendar.current
        // Remove the time component by extracting only the year, month, and day components
        let startDate = calendar.startOfDay(for: start)
        let endDate = calendar.startOfDay(for: end)
        
        let components = calendar.dateComponents([.day], from: startDate, to: endDate)
        if let days = components.day {
            return days - 1
        } else {
            return nil
        }
    }
    
    // MARK: Actions
    
    @objc func addWorkout() {
        performSegue(withIdentifier: WORKOUT_SEGUE_IDENTIFIER, sender: nil)
    }
    
    // MARK: View Lifecycle
    
    func setupView() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addWorkout))
        
        dataLoader.loadAllWorkouts { fetchedWorkouts in
            if let fetchedWorkouts = fetchedWorkouts {
                self.workoutDataSource.setWorkouts(fetchedWorkouts)
                DispatchQueue.main.sync {
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
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if self.workoutDataSource.numberOfSections(tableView) > section + 1 {
            if let nextWorkoutDate = self.workoutDataSource.workoutsForSection(section + 1)?.first?.date,
               let currentWorkoutDate = self.workoutDataSource.workoutsForSection(section)?.first?.date {
                if let restDays = daysBetween(start: nextWorkoutDate, end: currentWorkoutDate) {
                    if restDays == 0 {
                        return nil
                    } else {
                        return "\(restDays) rest day\(restDays == 1 ? "" : "s")"
                    }
                } else {
                    return nil
                }
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete, 
            let workout = self.workoutDataSource.workoutForIndexPath(indexPath) {
            dataLoader.deleteWorkout(workout)
            dataLoader.saveContext()
            self.workoutDataSource.removeWorkout(at: indexPath)
            self.tableView.deleteRows(at: [indexPath], with: .automatic)
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
