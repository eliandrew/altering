import Foundation
import UIKit

func streakImage(_ streakLength: Int) -> UIImage? {
    let streakImageName = streakImageNames[streakLength % streakImageNames.count]
    return UIImage(systemName: streakImageName)
}

let streakImageNames = [
    "figure.american.football",
    "figure.archery",
    "figure.australian.football",
    "figure.badminton",
    "figure.barre",
    "figure.baseball",
    "figure.basketball",
    "figure.bowling",
    "figure.boxing",
    "figure.climbing",
    "figure.cooldown",
    "figure.core.training",
    "figure.cricket",
    "figure.skiing.crosscountry",
    "figure.cross.training",
    "figure.curling",
    "figure.dance",
    "figure.disc.sports",
    "figure.skiing.downhill",
    "figure.elliptical",
    "figure.equestrian.sports",
    "figure.fencing",
    "figure.fishing",
    "figure.flexibility",
    "figure.strengthtraining.functional",
    "figure.golf",
    "figure.gymnastics",
    "figure.hand.cycling",
    "figure.handball",
    "figure.highintensity.intervaltraining",
    "figure.hiking",
    "figure.hockey",
    "figure.hunting",
    "figure.indoor.cycle",
    "figure.jumprope",
    "figure.kickboxing",
    "figure.lacrosse",
    "figure.martial.arts",
    "figure.mind.and.body",
    "figure.mixed.cardio",
    "figure.open.water.swim",
    "figure.outdoor.cycle",
    "figure.pickleball",
    "figure.pilates",
    "figure.play",
    "figure.pool.swim",
    "figure.racquetball",
    "figure.rolling",
    "figure.rower",
    "figure.rugby",
    "figure.sailing",
    "figure.skating",
    "figure.snowboarding",
    "figure.soccer",
    "figure.socialdance",
    "figure.softball",
    "figure.squash",
    "figure.stair.stepper",
    "figure.stairs",
    "figure.step.training",
    "figure.surfing",
    "figure.table.tennis",
    "figure.taichi",
    "figure.tennis",
    "figure.track.and.field",
    "figure.strengthtraining.traditional",
    "figure.volleyball",
    "figure.water.fitness",
    "figure.waterpolo",
    "figure.wrestling",
    "figure.yoga",
    "figure.walk"
]

func calculateStreaks(_ dates: Set<DateComponents>) -> [[DateComponents]] {
    let maxGap = 4
    guard !dates.isEmpty else { return [] }
    let sortedDates = dates.sorted(using: DateComponentsComparator(order: .forward))
    var groupedDates: [[DateComponents]] = []
    var currentGroup: [DateComponents] = [sortedDates[0]]
    
    let calendar = Calendar.current
    
    for i in 1..<sortedDates.count {
        let previousDate = sortedDates[i - 1]
        let currentDate = sortedDates[i]
        
        if let difference = calendar.dateComponents([.day], from: previousDate, to: currentDate).day, difference <= maxGap {
            currentGroup.append(currentDate)
        } else {
            groupedDates.append(currentGroup)
            currentGroup = [currentDate]
        }
    }
    
    groupedDates.append(currentGroup)
    return groupedDates
}
