import Foundation

enum DateTitleReference: String {
    case before = "before";
    case ago = "ago";
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

func daysBetween(start: Date, end: Date) -> Int? {
    let calendar = Calendar.current
    // Remove the time component by extracting only the year, month, and day components
    let startDate = calendar.startOfDay(for: start)
    let endDate = calendar.startOfDay(for: end)
    
    let components = calendar.dateComponents([.day], from: startDate, to: endDate)
    if let days = components.day {
        return days
    } else {
        return nil
    }
}

func standardDateTitle(_ date: Date?, referenceDate: Date, reference: DateTitleReference) -> String {
    let dateTitle = dateTitleFrom(date, includeYear: true)
    let referenceDays = daysBetween(start: date ?? Date.now, end: referenceDate) ?? 0
    var referenceDaysTitle = "\(referenceDays) days \(reference.rawValue)"
    if referenceDays == 0 {
        referenceDaysTitle = "Today"
    } else if referenceDays == 1 {
        referenceDaysTitle = "Yesterday"
    } else if referenceDays > 365 {
        referenceDaysTitle = "Over a year ago"
    }
    return "\(dateTitle ?? "No Date") (\(referenceDaysTitle))"
}

func areYearsSame(date1: Date, date2: Date) -> Bool {
    let calendar = Calendar.current
    let year1 = calendar.component(.year, from: date1)
    let year2 = calendar.component(.year, from: date2)
    return year1 == year2
}

func areDatesSame(date1: Date, date2: Date) -> Bool {
    let calendar = Calendar.current
    let year1 = calendar.component(.year, from: date1)
    let year2 = calendar.component(.year, from: date2)
    let month1 = calendar.component(.month, from: date1)
    let month2 = calendar.component(.month, from: date2)
    let day1 = calendar.component(.day, from: date1)
    let day2 = calendar.component(.day, from: date2)
    return year1 == year2 && month1 == month2 && day1 == day2
}

func formatSectionTitle(_ date: Date) -> String {
    let dateFormatter = DateFormatter()
    if areYearsSame(date1: date, date2: Date.now) {
        dateFormatter.dateFormat = "MMM"
    } else {
        dateFormatter.dateFormat = "MMM yy"
    }
    
    return dateFormatter.string(from: date)
}

func convertDateStringToTitle(_ dateString: String) -> String? {
    // Create a date formatter for the input string
    let inputDateFormatter = DateFormatter()
    inputDateFormatter.dateFormat = "EEE MM/dd/yy"
    
    // Parse the input date string into a Date object
    guard let date = inputDateFormatter.date(from: dateString) else {
        return nil
    }
    
    return formatSectionTitle(date)
}
