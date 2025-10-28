//
//  DataImporter.swift
//  altering
//
//  Import JSON backup into CoreData
//

import Foundation
import CoreData
import UIKit

class DataImporter {
    
    // MARK: - Import Result
    
    struct ImportResult {
        let success: Bool
        let error: Error?
        let recordCount: Int
        let message: String
    }
    
    enum ImportError: Error {
        case invalidFileFormat
        case contextNotAvailable
        case decodingFailed(String)
        case importFailed(String)
    }
    
    // MARK: - Import Functions
    
    static func importData(from url: URL, context: NSManagedObjectContext, clearExisting: Bool = false) -> ImportResult {
        do {
            // Read file
            let jsonData = try Data(contentsOf: url)
            
            // Decode JSON
            let decoder = JSONDecoder()
            let backupData = try decoder.decode(DataExporter.BackupData.self, from: jsonData)
            
            // Clear existing data if requested
            if clearExisting {
                try clearAllData(context: context)
            }
            
            // Import data with relationship tracking
            var idMapping: [String: NSManagedObjectID] = [:]
            
            // Import in order to maintain relationships
            try importExerciseGroups(backupData.exerciseGroups, context: context, idMapping: &idMapping)
            try importExercises(backupData.exercises, context: context, idMapping: &idMapping)
            try importWorkoutPrograms(backupData.workoutPrograms, context: context, idMapping: &idMapping)
            try importWorkoutPlans(backupData.workoutPlans, context: context, idMapping: &idMapping)
            try importWorkouts(backupData.workouts, context: context, idMapping: &idMapping)
            try importRestPeriods(backupData.restPeriods, context: context, idMapping: &idMapping)
            
            // Final save to ensure everything is persisted
            if context.hasChanges {
                try context.save()
            }
            
            let totalRecords = backupData.exerciseGroups.count + backupData.exercises.count + 
                              backupData.workoutPrograms.count + backupData.workoutPlans.count + 
                              backupData.workouts.count + backupData.restPeriods.count
            
            return ImportResult(
                success: true,
                error: nil,
                recordCount: totalRecords,
                message: "Successfully imported \(totalRecords) records"
            )
            
        } catch let error as DecodingError {
            return ImportResult(success: false, error: error, recordCount: 0, message: "Failed to decode backup file: \(error.localizedDescription)")
        } catch let error as ImportError {
            return ImportResult(success: false, error: error, recordCount: 0, message: "Import failed: \(error.localizedDescription)")
        } catch let error as NSError {
            // Enhanced error reporting for validation errors
            var errorMessage = "Unexpected error: \(error.localizedDescription)"
            
            if let detailedErrors = error.userInfo[NSDetailedErrorsKey] as? [NSError] {
                errorMessage += "\n\nDetailed errors:"
                for (index, detailError) in detailedErrors.enumerated() {
                    errorMessage += "\n\(index + 1). \(detailError.localizedDescription)"
                    if let validationKey = detailError.userInfo[NSValidationKeyErrorKey] as? String {
                        errorMessage += " (Key: \(validationKey))"
                    }
                    if let validationObject = detailError.userInfo[NSValidationObjectErrorKey] {
                        errorMessage += " (Object: \(validationObject))"
                    }
                }
            }
            
            print("Import Error Details: \(errorMessage)")
            return ImportResult(success: false, error: error, recordCount: 0, message: errorMessage)
        } catch {
            return ImportResult(success: false, error: error, recordCount: 0, message: "Unexpected error: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Clear Data
    
    private static func clearAllData(context: NSManagedObjectContext) throws {
        let entities = ["ExerciseGroup", "Exercise", "WorkoutProgram", "WorkoutPlan", "Workout", "RestPeriod"]
        
        for entityName in entities {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            try context.execute(deleteRequest)
        }
        
        try context.save()
    }
    
    // MARK: - Import Individual Entities
    
    private static func importExerciseGroups(_ groups: [DataExporter.ExerciseGroupData], 
                                            context: NSManagedObjectContext, 
                                            idMapping: inout [String: NSManagedObjectID]) throws {
        for groupData in groups {
            let group = ExerciseGroup(context: context)
            group.name = groupData.name
            
            try context.save()
            idMapping[groupData.id] = group.objectID
        }
    }
    
    private static func importExercises(_ exercises: [DataExporter.ExerciseData], 
                                       context: NSManagedObjectContext, 
                                       idMapping: inout [String: NSManagedObjectID]) throws {
        // First pass: Create all exercises without relationships
        var tempMapping: [String: Exercise] = [:]
        
        for exerciseData in exercises {
            let exercise = Exercise(context: context)
            exercise.name = exerciseData.name
            tempMapping[exerciseData.id] = exercise
        }
        
        // Save first batch
        try context.save()
        
        // Second pass: Establish relationships and update mapping
        for exerciseData in exercises {
            guard let exercise = tempMapping[exerciseData.id] else { continue }
            
            // Store permanent objectID
            idMapping[exerciseData.id] = exercise.objectID
            
            // Link to group if exists
            if let groupId = exerciseData.groupId,
               let groupObjectID = idMapping[groupId] {
                do {
                    let group = try context.existingObject(with: groupObjectID)
                    if let validGroup = group as? ExerciseGroup {
                        exercise.group = validGroup
                    }
                } catch {
                    print("Warning: Could not find group with ID \(groupId)")
                }
            }
        }
        
        // Final save with relationships
        if context.hasChanges {
            try context.save()
        }
    }
    
    private static func importWorkoutPrograms(_ programs: [DataExporter.WorkoutProgramData], 
                                             context: NSManagedObjectContext, 
                                             idMapping: inout [String: NSManagedObjectID]) throws {
        let dateFormatter = ISO8601DateFormatter()
        
        for programData in programs {
            let program = WorkoutProgram(context: context)
            program.name = programData.name
            
            if let startString = programData.start {
                program.start = dateFormatter.date(from: startString)
            }
            
            if let endString = programData.end {
                program.end = dateFormatter.date(from: endString)
            }
            
            try context.save()
            idMapping[programData.id] = program.objectID
        }
    }
    
    private static func importWorkoutPlans(_ plans: [DataExporter.WorkoutPlanData], 
                                          context: NSManagedObjectContext, 
                                          idMapping: inout [String: NSManagedObjectID]) throws {
        // First pass: Create all workout plans
        var tempMapping: [String: WorkoutPlan] = [:]
        
        for planData in plans {
            let plan = WorkoutPlan(context: context)
            plan.numWorkouts = planData.numWorkouts
            tempMapping[planData.id] = plan
        }
        
        // Save first batch
        try context.save()
        
        // Second pass: Establish relationships
        for planData in plans {
            guard let plan = tempMapping[planData.id] else { continue }
            
            // Store permanent objectID
            idMapping[planData.id] = plan.objectID
            
            // Link to exercise if exists
            if let exerciseId = planData.exerciseId,
               let exerciseObjectID = idMapping[exerciseId] {
                do {
                    let exercise = try context.existingObject(with: exerciseObjectID)
                    if let validExercise = exercise as? Exercise {
                        plan.exercise = validExercise
                    }
                } catch {
                    print("Warning: Could not find exercise with ID \(exerciseId)")
                }
            }
            
            // Link to programs using mutableSetValue (safer for CoreData)
            if !planData.programIds.isEmpty {
                let programsSet = plan.mutableSetValue(forKey: "programs")
                
                for programId in planData.programIds {
                    if let programObjectID = idMapping[programId] {
                        do {
                            let program = try context.existingObject(with: programObjectID)
                            if let validProgram = program as? WorkoutProgram {
                                programsSet.add(validProgram)
                            }
                        } catch {
                            print("Warning: Could not find program with ID \(programId)")
                        }
                    }
                }
            }
        }
        
        // Final save with relationships
        if context.hasChanges {
            try context.save()
        }
    }
    
    private static func importWorkouts(_ workouts: [DataExporter.WorkoutData], 
                                      context: NSManagedObjectContext, 
                                      idMapping: inout [String: NSManagedObjectID]) throws {
        let dateFormatter = ISO8601DateFormatter()
        
        // First pass: Create all workouts
        var tempMapping: [String: Workout] = [:]
        
        for workoutData in workouts {
            let workout = Workout(context: context)
            workout.completed = workoutData.completed
            workout.notes = workoutData.notes
            
            if let dateString = workoutData.date {
                workout.date = dateFormatter.date(from: dateString)
            }
            
            tempMapping[workoutData.id] = workout
        }
        
        // Save first batch
        try context.save()
        
        // Second pass: Establish relationships
        for workoutData in workouts {
            guard let workout = tempMapping[workoutData.id] else { continue }
            
            // Store permanent objectID
            idMapping[workoutData.id] = workout.objectID
            
            // Link to exercise if exists
            if let exerciseId = workoutData.exerciseId,
               let exerciseObjectID = idMapping[exerciseId] {
                do {
                    let exercise = try context.existingObject(with: exerciseObjectID)
                    if let validExercise = exercise as? Exercise {
                        workout.exercise = validExercise
                    }
                } catch {
                    print("Warning: Could not find exercise with ID \(exerciseId)")
                }
            }
            
            // Link to program if exists
            if let programId = workoutData.programId,
               let programObjectID = idMapping[programId] {
                do {
                    let program = try context.existingObject(with: programObjectID)
                    if let validProgram = program as? WorkoutProgram {
                        workout.program = validProgram
                    }
                } catch {
                    print("Warning: Could not find program with ID \(programId)")
                }
            }
        }
        
        // Final save with relationships
        if context.hasChanges {
            try context.save()
        }
    }
    
    private static func importRestPeriods(_ periods: [DataExporter.RestPeriodData], 
                                         context: NSManagedObjectContext, 
                                         idMapping: inout [String: NSManagedObjectID]) throws {
        let dateFormatter = ISO8601DateFormatter()
        
        for periodData in periods {
            let period = RestPeriod(context: context)
            period.explanation = periodData.explanation
            
            if let startString = periodData.startDate {
                period.startDate = dateFormatter.date(from: startString)
            }
            
            if let endString = periodData.endDate {
                period.endDate = dateFormatter.date(from: endString)
            }
            
            try context.save()
            idMapping[periodData.id] = period.objectID
        }
    }
}

