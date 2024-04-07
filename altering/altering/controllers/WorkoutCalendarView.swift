import UIKit

class WorkoutCalendarView: UICalendarView {


    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        // Create an instance of the Gregorian calendar.
        let gregorianCalendar = Calendar(identifier: .gregorian)
        // Set the calendar displayed by the view.
        calendar = gregorianCalendar
        // Set the calendar view's locale.
        locale = Locale(identifier: "en_US")
        // Set the font design to the rounded system font.
        fontDesign = .rounded
        
        visibleDateComponents = DateComponents(
            calendar: gregorianCalendar,
            year: 2024,
            month: 2,
            day: 1
        )
    }
}
