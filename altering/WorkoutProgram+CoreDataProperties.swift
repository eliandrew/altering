//
//  WorkoutProgram+CoreDataProperties.swift
//  Altered
//
//  Created by Andrew, Elias on 7/9/24.
//
//

import Foundation
import CoreData


extension WorkoutProgram {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<WorkoutProgram> {
        return NSFetchRequest<WorkoutProgram>(entityName: "WorkoutProgram")
    }

    @NSManaged public var end: Date?
    @NSManaged public var name: String?
    @NSManaged public var start: Date?
    @NSManaged public var plans: NSSet?
    @NSManaged public var workouts: NSSet?

}

// MARK: Generated accessors for plans
extension WorkoutProgram {

    @objc(addPlansObject:)
    @NSManaged public func addToPlans(_ value: WorkoutPlan)

    @objc(removePlansObject:)
    @NSManaged public func removeFromPlans(_ value: WorkoutPlan)

    @objc(addPlans:)
    @NSManaged public func addToPlans(_ values: NSSet)

    @objc(removePlans:)
    @NSManaged public func removeFromPlans(_ values: NSSet)

}

// MARK: Generated accessors for workouts
extension WorkoutProgram {

    @objc(addWorkoutsObject:)
    @NSManaged public func addToWorkouts(_ value: Workout)

    @objc(removeWorkoutsObject:)
    @NSManaged public func removeFromWorkouts(_ value: Workout)

    @objc(addWorkouts:)
    @NSManaged public func addToWorkouts(_ values: NSSet)

    @objc(removeWorkouts:)
    @NSManaged public func removeFromWorkouts(_ values: NSSet)

}

extension WorkoutProgram : Identifiable {

}
