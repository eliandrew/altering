//
//  WorkoutPlan+CoreDataProperties.swift
//  Altered
//
//  Created by Andrew, Elias on 7/9/24.
//
//

import Foundation
import CoreData


extension WorkoutPlan {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<WorkoutPlan> {
        return NSFetchRequest<WorkoutPlan>(entityName: "WorkoutPlan")
    }

    @NSManaged public var numWorkouts: Int64
    @NSManaged public var exercise: Exercise?
    @NSManaged public var programs: NSSet?

}

// MARK: Generated accessors for programs
extension WorkoutPlan {

    @objc(addProgramsObject:)
    @NSManaged public func addToPrograms(_ value: WorkoutProgram)

    @objc(removeProgramsObject:)
    @NSManaged public func removeFromPrograms(_ value: WorkoutProgram)

    @objc(addPrograms:)
    @NSManaged public func addToPrograms(_ values: NSSet)

    @objc(removePrograms:)
    @NSManaged public func removeFromPrograms(_ values: NSSet)

}

extension WorkoutPlan : Identifiable {

}
