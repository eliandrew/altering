import UIKit

class StreakViewController: UIViewController {
    
    let calendarView = UICalendarView()
    
    var workoutDates: Set<DateComponents> = []
    
    var workouts: [Workout] = []
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
    
    func setupWorkoutDates() -> Set<DateComponents> {
        let calendar = Calendar.current
        var uniqueDates = Set<DateComponents>()
        let workoutDates = workouts.compactMap{$0.date}
        for date in workoutDates {
            let components = calendar.dateComponents([.month, .day, .year], from: date)
            uniqueDates.insert(components)
        }
        
        return uniqueDates
    }
    
    func configureCalendarView() {
        let calendar = Calendar.current
        calendarView.visibleDateComponents = calendar.dateComponents([.month, .day, .year], from: Date())
    }
}

extension StreakViewController: UICalendarViewDelegate {
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
                        size: .large
                    )
                }
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
}
