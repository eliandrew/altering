//
//  ExerciseGroup+CoreDataProperties.swift
//  Altered
//
//  Created by Andrew, Elias on 7/9/24.
//
//

import Foundation
import CoreData


extension ExerciseGroup {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ExerciseGroup> {
        return NSFetchRequest<ExerciseGroup>(entityName: "ExerciseGroup")
    }

    @NSManaged public var name: String?
    @NSManaged public var exercise: NSSet?

}

// MARK: Generated accessors for exercise
extension ExerciseGroup {

    @objc(addExerciseObject:)
    @NSManaged public func addToExercise(_ value: Exercise)

    @objc(removeExerciseObject:)
    @NSManaged public func removeFromExercise(_ value: Exercise)

    @objc(addExercise:)
    @NSManaged public func addToExercise(_ values: NSSet)

    @objc(removeExercise:)
    @NSManaged public func removeFromExercise(_ values: NSSet)

}

extension ExerciseGroup : Identifiable {

}
