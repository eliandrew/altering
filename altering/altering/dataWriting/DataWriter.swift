import Foundation

class DataWriter {
    
    static let shared = DataWriter()
    
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
