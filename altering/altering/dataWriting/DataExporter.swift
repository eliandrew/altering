//
//  DataExporter.swift
//  altering
//
//  Export CoreData to JSON for backup and device transfer
//

import Foundation
import CoreData
import UIKit

class DataExporter {
    
    // MARK: - Export Result
    
    struct ExportResult {
        let success: Bool
        let fileURL: URL?
        let error: Error?
        let recordCount: Int
    }
    
    // MARK: - Export Data Structure
    
    struct BackupData: Codable {
        let version: String
        let exportDate: String
        let exerciseGroups: [ExerciseGroupData]
        let exercises: [ExerciseData]
        let workoutPrograms: [WorkoutProgramData]
        let workoutPlans: [WorkoutPlanData]
        let workouts: [WorkoutData]
        let restPeriods: [RestPeriodData]
    }
    
    struct ExerciseGroupData: Codable {
        let id: String
        let name: String?
    }
    
    struct ExerciseData: Codable {
        let id: String
        let name: String?
        let groupId: String?
    }
    
    struct WorkoutProgramData: Codable {
        let id: String
        let name: String?
        let start: String?
        let end: String?
    }
    
    struct WorkoutPlanData: Codable {
        let id: String
        let numWorkouts: Int64
        let exerciseId: String?
        let programIds: [String]
    }
    
    struct WorkoutData: Codable {
        let id: String
        let completed: Bool
        let date: String?
        let notes: String?
        let exerciseId: String?
        let programId: String?
    }
    
    struct RestPeriodData: Codable {
        let id: String
        let startDate: String?
        let endDate: String?
        let explanation: String?
    }
    
    // MARK: - Export Functions
    
    static func exportAllData(context: NSManagedObjectContext) -> ExportResult {
        do {
            // Fetch all data
            let exerciseGroups = try fetchExerciseGroups(context: context)
            let exercises = try fetchExercises(context: context)
            let workoutPrograms = try fetchWorkoutPrograms(context: context)
            let workoutPlans = try fetchWorkoutPlans(context: context)
            let workouts = try fetchWorkouts(context: context)
            let restPeriods = try fetchRestPeriods(context: context)
            
            // Create backup data structure
            let dateFormatter = ISO8601DateFormatter()
            let backupData = BackupData(
                version: "1.0",
                exportDate: dateFormatter.string(from: Date()),
                exerciseGroups: exerciseGroups,
                exercises: exercises,
                workoutPrograms: workoutPrograms,
                workoutPlans: workoutPlans,
                workouts: workouts,
                restPeriods: restPeriods
            )
            
            // Convert to JSON
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let jsonData = try encoder.encode(backupData)
            
            // Save to file
            let fileName = "altering_backup_\(Date().timeIntervalSince1970).json"
            let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
            try jsonData.write(to: fileURL)
            
            let totalRecords = exerciseGroups.count + exercises.count + workoutPrograms.count + 
                              workoutPlans.count + workouts.count + restPeriods.count
            
            return ExportResult(success: true, fileURL: fileURL, error: nil, recordCount: totalRecords)
            
        } catch {
            return ExportResult(success: false, fileURL: nil, error: error, recordCount: 0)
        }
    }
    
    // MARK: - Fetch Functions
    
    private static func fetchExerciseGroups(context: NSManagedObjectContext) throws -> [ExerciseGroupData] {
        let fetchRequest: NSFetchRequest<ExerciseGroup> = ExerciseGroup.fetchRequest()
        let groups = try context.fetch(fetchRequest)
        
        return groups.map { group in
            ExerciseGroupData(
                id: group.objectID.uriRepresentation().absoluteString,
                name: group.name
            )
        }
    }
    
    private static func fetchExercises(context: NSManagedObjectContext) throws -> [ExerciseData] {
        let fetchRequest: NSFetchRequest<Exercise> = Exercise.fetchRequest()
        let exercises = try context.fetch(fetchRequest)
        
        return exercises.map { exercise in
            ExerciseData(
                id: exercise.objectID.uriRepresentation().absoluteString,
                name: exercise.name,
                groupId: exercise.group?.objectID.uriRepresentation().absoluteString
            )
        }
    }
    
    private static func fetchWorkoutPrograms(context: NSManagedObjectContext) throws -> [WorkoutProgramData] {
        let fetchRequest: NSFetchRequest<WorkoutProgram> = WorkoutProgram.fetchRequest()
        let programs = try context.fetch(fetchRequest)
        
        let dateFormatter = ISO8601DateFormatter()
        
        return programs.map { program in
            WorkoutProgramData(
                id: program.objectID.uriRepresentation().absoluteString,
                name: program.name,
                start: program.start.map { dateFormatter.string(from: $0) },
                end: program.end.map { dateFormatter.string(from: $0) }
            )
        }
    }
    
    private static func fetchWorkoutPlans(context: NSManagedObjectContext) throws -> [WorkoutPlanData] {
        let fetchRequest: NSFetchRequest<WorkoutPlan> = WorkoutPlan.fetchRequest()
        let plans = try context.fetch(fetchRequest)
        
        return plans.map { plan in
            let programIds = (plan.programs?.allObjects as? [WorkoutProgram])?.map {
                $0.objectID.uriRepresentation().absoluteString
            } ?? []
            
            return WorkoutPlanData(
                id: plan.objectID.uriRepresentation().absoluteString,
                numWorkouts: plan.numWorkouts,
                exerciseId: plan.exercise?.objectID.uriRepresentation().absoluteString,
                programIds: programIds
            )
        }
    }
    
    private static func fetchWorkouts(context: NSManagedObjectContext) throws -> [WorkoutData] {
        let fetchRequest: NSFetchRequest<Workout> = Workout.fetchRequest()
        let workouts = try context.fetch(fetchRequest)
        
        let dateFormatter = ISO8601DateFormatter()
        
        return workouts.map { workout in
            WorkoutData(
                id: workout.objectID.uriRepresentation().absoluteString,
                completed: workout.completed,
                date: workout.date.map { dateFormatter.string(from: $0) },
                notes: workout.notes,
                exerciseId: workout.exercise?.objectID.uriRepresentation().absoluteString,
                programId: workout.program?.objectID.uriRepresentation().absoluteString
            )
        }
    }
    
    private static func fetchRestPeriods(context: NSManagedObjectContext) throws -> [RestPeriodData] {
        let fetchRequest: NSFetchRequest<RestPeriod> = RestPeriod.fetchRequest()
        let periods = try context.fetch(fetchRequest)
        
        let dateFormatter = ISO8601DateFormatter()
        
        return periods.map { period in
            RestPeriodData(
                id: period.objectID.uriRepresentation().absoluteString,
                startDate: period.startDate.map { dateFormatter.string(from: $0) },
                endDate: period.endDate.map { dateFormatter.string(from: $0) },
                explanation: period.explanation
            )
        }
    }
}

