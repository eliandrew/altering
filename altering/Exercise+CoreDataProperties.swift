//
//  Exercise+CoreDataProperties.swift
//  Altered
//
//  Created by Andrew, Elias on 7/9/24.
//
//

import Foundation
import CoreData


extension Exercise {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Exercise> {
        return NSFetchRequest<Exercise>(entityName: "Exercise")
    }

    @NSManaged public var name: String?
    @NSManaged public var group: ExerciseGroup?
    @NSManaged public var plans: NSSet?
    @NSManaged public var workouts: NSSet?

}

// MARK: Generated accessors for plans
extension Exercise {

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
extension Exercise {

    @objc(addWorkoutsObject:)
    @NSManaged public func addToWorkouts(_ value: Workout)

    @objc(removeWorkoutsObject:)
    @NSManaged public func removeFromWorkouts(_ value: Workout)

    @objc(addWorkouts:)
    @NSManaged public func addToWorkouts(_ values: NSSet)

    @objc(removeWorkouts:)
    @NSManaged public func removeFromWorkouts(_ values: NSSet)

}

extension Exercise : Identifiable {

}
