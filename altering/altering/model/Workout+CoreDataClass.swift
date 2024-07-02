//
//  Workout+CoreDataClass.swift
//  altering
//
//  Created by Andrew, Elias on 4/2/24.
//
//

import Foundation
import CoreData

@objc(Workout)
public class Workout: NSManagedObject {

    func toCSVString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let date = dateFormatter.string(from: self.date ?? Date.now as Date)
        
        let exerciseName = "\"\(self.exercise?.name ?? "exercise")\""
        let exerciseGroup = "\"\(self.exercise?.group?.name ?? "group")\""
        
        let notes = "\"\(self.notes ?? "notes")\""
        
        return [date, exerciseName, exerciseGroup, notes].joined(separator: ",")
    }
}
