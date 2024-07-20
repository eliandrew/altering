import Foundation

struct DateComponentsComparator: SortComparator {
    typealias Compared = DateComponents
    var order: SortOrder
    
    init(order: SortOrder = .forward) {
        self.order = order
    }
    
    func compare(_ lhs: DateComponents, _ rhs: DateComponents) -> ComparisonResult {
        var result: ComparisonResult
        
        if let lhsYear = lhs.year, let rhsYear = rhs.year {
            if lhsYear < rhsYear {
                result = order == .forward ? .orderedAscending : .orderedDescending
            } else if lhsYear > rhsYear {
                result = order == .forward ? .orderedDescending : .orderedAscending
            } else {
                result = .orderedSame
            }
        } else {
            result = .orderedSame
        }
        
        if result == .orderedSame {
            if let lhsMonth = lhs.month, let rhsMonth = rhs.month {
                if lhsMonth < rhsMonth {
                    result = order == .forward ? .orderedAscending : .orderedDescending
                } else if lhsMonth > rhsMonth {
                    result = order == .forward ? .orderedDescending : .orderedAscending
                } else {
                    result = .orderedSame
                }
            } else {
                result = .orderedSame
            }
        }
        
        if result == .orderedSame {
            if let lhsDay = lhs.day, let rhsDay = rhs.day {
                if lhsDay < rhsDay {
                    result = order == .forward ? .orderedAscending : .orderedDescending
                } else if lhsDay > rhsDay {
                    result = order == .forward ? .orderedDescending : .orderedAscending
                } else {
                    result = .orderedSame
                }
            } else {
                result = .orderedSame
            }
        }
        
        return result

    }
}
