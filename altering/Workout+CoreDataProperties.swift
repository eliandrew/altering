//
//  Workout+CoreDataProperties.swift
//  Altered
//
//  Created by Andrew, Elias on 7/9/24.
//
//

import Foundation
import CoreData


extension Workout {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Workout> {
        return NSFetchRequest<Workout>(entityName: "Workout")
    }

    @NSManaged public var date: Date?
    @NSManaged public var notes: String?
    @NSManaged public var exercise: Exercise?
    @NSManaged public var program: WorkoutProgram?

}

extension Workout : Identifiable {

}
