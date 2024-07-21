import UIKit

class StreakViewController: UIViewController {
    
    let WORKOUT_DAY_VIEW_SEGUE = "workoutDayViewSegue"
    
    let calendarView = UICalendarView()
    
    var workoutDates: Set<DateComponents> = []
    var workouts: [String : [Workout]] = [:]
    var streaks: [[DateComponents]] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.largeTitleDisplayMode = .never
        calendarView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(calendarView)
        
        NSLayoutConstraint.activate([
            calendarView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            calendarView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            calendarView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            calendarView.heightAnchor.constraint(equalToConstant: 600)
        ])
        
        calendarView.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setup()
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    func setup() {
        workoutDates = setupWorkoutDates()
        streaks = calculateStreaks(workoutDates)
        configureCalendarView()
    }
    
    func dateFromTitle(_ title: String, includeYear: Bool = true) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = includeYear ? "EE MM/dd/yy" : "EE MM/dd"
        return dateFormatter.date(from: title)
    }
    
    func dateTitleFrom(_ date: Date?, includeYear: Bool = true) -> String? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = includeYear ? "EE MM/dd/yy" : "EE MM/dd"
        
        if let date = date {
            return dateFormatter.string(from: date)
        } else {
            return nil
        }
    }
    
    func titleFromComponents(_ title: String, includeYear: Bool = true) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = includeYear ? "EE MM/dd/yy" : "EE MM/dd"
        return dateFormatter.date(from: title)
    }
    
    func setupWorkoutDates() -> Set<DateComponents> {
        let calendar = Calendar.current
        return Set(workouts.keys.compactMap({dateFromTitle($0)}).map({calendar.dateComponents([.month, .day, .year], from: $0)}))
    }
    
    func configureCalendarView() {
        let calendar = Calendar.current
        let dateSelection = UICalendarSelectionSingleDate(delegate: self)
        calendarView.selectionBehavior = dateSelection
        calendarView.visibleDateComponents = calendar.dateComponents([.month, .day, .year], from: Date())
    }
}

extension StreakViewController: UICalendarViewDelegate {
    
    func dateSelection(_ selection: UICalendarSelectionSingleDate, canSelectDate dateComponents: DateComponents?) -> Bool {
        return true
    }
    
    func calendarView(_ calendarView: UICalendarView, decorationFor dateComponents: DateComponents) -> UICalendarView.Decoration? {
        if let month = dateComponents.month, let year = dateComponents.year, let visibleMonth = calendarView.visibleDateComponents.month, let visibleYear = calendarView.visibleDateComponents.year {
            
            let streak = streaks.first { streak in
                streak.contains { d in
                    d.year == dateComponents.year && d.month == dateComponents.month && d.day == dateComponents.day
                }
            }
            if let streak, month == visibleMonth && year == visibleYear {
                let image = streakImage(streak.count)
                let longestStreakLength = UserDefaults.standard.integer(forKey: "maxStreakLength")
                if streak.count == longestStreakLength {
                    return UICalendarView.Decoration.image(
                        UIImage(systemName: "medal.star.fill"),
                        color: UIColor.systemYellow,
                        size: .large
                    )
                } else {
                    return UICalendarView.Decoration.image(
                        image,
                        color: UIColor.systemBlue,
                        size: .medium
                    )
                }
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == WORKOUT_DAY_VIEW_SEGUE {
            if let vc = segue.destination as? WorkoutDayViewTableViewController, let workouts = sender as? [Workout] {
                vc.workouts = workouts
            }
        }
    }
}

extension StreakViewController: UICalendarSelectionSingleDateDelegate {
    func dateSelection(_ selection: UICalendarSelectionSingleDate, didSelectDate dateComponents: DateComponents?) {
        if let title = dateTitleFrom(dateComponents?.date), let workouts = workouts[title] {
            self.performSegue(withIdentifier: WORKOUT_DAY_VIEW_SEGUE, sender: workouts)
        }
    }
}
