import Foundation
import CoreData
import UIKit

class DataWriter {
    
    let dataLoader = DataLoader.shared
    static let shared = DataWriter()
    
    func exportCoreData(url: URL) {
        let coordinator = dataLoader.persistentContainer.persistentStoreCoordinator
        guard let storeURL = coordinator.persistentStores.first?.url else {
            print("Persistent store URL not found")
            return
        }

        let fileManager = FileManager.default
        let walFileURL = storeURL.deletingPathExtension().appendingPathExtension("sqlite-wal")
        let shmFileURL = storeURL.deletingPathExtension().appendingPathExtension("sqlite-shm")

        // Destination directory (for example, the Documents directory)
        let exportedStoreURL = url.appendingPathComponent("ExportedData.sqlite")
        let exportedWalFileURL = url.appendingPathComponent("ExportedData.sqlite-wal")
        let exportedShmFileURL = url.appendingPathComponent("ExportedData.sqlite-shm")

        do {
            // Copy the main SQLite file
            if fileManager.fileExists(atPath: exportedStoreURL.path) {
                try fileManager.removeItem(at: exportedStoreURL)
            }
            try fileManager.copyItem(at: storeURL, to: exportedStoreURL)

            // Copy the -wal file if it exists
            if fileManager.fileExists(atPath: walFileURL.path) {
                if fileManager.fileExists(atPath: exportedWalFileURL.path) {
                    try fileManager.removeItem(at: exportedWalFileURL)
                }
                try fileManager.copyItem(at: walFileURL, to: exportedWalFileURL)
            }

            // Copy the -shm file if it exists
            if fileManager.fileExists(atPath: shmFileURL.path) {
                if fileManager.fileExists(atPath: exportedShmFileURL.path) {
                    try fileManager.removeItem(at: exportedShmFileURL)
                }
                try fileManager.copyItem(at: shmFileURL, to: exportedShmFileURL)
            }

            print("Core Data export successful")
        } catch {
            print("Failed to export Core Data: \(error)")
        }
    }

    
    func importCoreData(from url: URL) throws {
        let persistentContainer = (UIApplication.shared.delegate as! AppDelegate).persistentContainer
        let storeURL = persistentContainer.persistentStoreCoordinator.persistentStores.first?.url
        
        if let storeURL = storeURL {
            try persistentContainer.persistentStoreCoordinator.replacePersistentStore(at: storeURL, withPersistentStoreFrom: url, type: .sqlite)
        }
    }
    
    
    func createWorkoutCSV(workouts: [Workout]) -> String {
        return workouts.map { w in
            w.toCSVString()
        }.joined(separator: "\n")
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        for p in paths {
            print(p)
        }
        return paths[0]
    }
    
    func writeCSV(data: String, to fileNamed: String, headers: [String]) -> URL? {
        let filename = getDocumentsDirectory().appendingPathComponent(fileNamed)
        do {
            let dataToWrite = "\(headers.joined(separator: ","))\n\(data)"
            try dataToWrite.write(to: filename, atomically: true, encoding: String.Encoding.utf8)
            print("CSV file successfully written to: \(filename)")
            return filename
        } catch {
            print("Failed to write CSV file: \(error)")
            return nil
        }
    }
    
}
