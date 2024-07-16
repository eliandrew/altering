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
    }
    return "\(dateTitle ?? "No Date") (\(referenceDaysTitle))"
}
