import Foundation
import UIKit

/// CSV gameplay data logger for Create ML compatibility
class GameplayDataLogger {
    static let shared = GameplayDataLogger()
    
    private let csvFileName = "gameplay_data.csv"
    private var csvFileURL: URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent(csvFileName)
    }
    
    private var currentSession: GameplaySession?
    private var gameStartTime: Date?
    private let fileManager = FileManager.default
    
    // Session tracking for 20-game limit
    private let maxSessions = 20
    private let sessionCountKey = "GameplayDataLogger_SessionCount"
    
    private var completedSessions: Int {
        get {
            return UserDefaults.standard.integer(forKey: sessionCountKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: sessionCountKey)
        }
    }
    
    private init() {
        setupCSVFile()
    }
    
    // MARK: - Public Interface
    
    /// Start a new gameplay session
    func startSession() {
        // Check if we've reached the maximum number of sessions
        if completedSessions >= maxSessions {
            print("GameplayDataLogger: Maximum sessions (\(maxSessions)) reached. Logging disabled.")
            return
        }
        
        currentSession = GameplaySession()
        gameStartTime = Date()
        print("GameplayDataLogger: Started new session \(currentSession?.sessionId ?? "unknown") (Session \(completedSessions + 1)/\(maxSessions))")
    }
    
    /// End the current gameplay session
    func endSession() {
        if currentSession != nil {
            completedSessions += 1
            print("GameplayDataLogger: Ended session (Total completed: \(completedSessions)/\(maxSessions))")
            
            if completedSessions >= maxSessions {
                print("GameplayDataLogger: Reached maximum sessions. Logging will be disabled for future games.")
                
                // Automatically upload CSV file to Firebase Storage after reaching 20 sessions
                uploadCSVToFirebase()
            }
        }
        
        currentSession = nil
        gameStartTime = nil
    }
    
    /// Log a gameplay move to CSV file
    func logMove(
        boardState: [[Bool]],
        availablePieces: [TetrominoShape],
        selectedPiece: TetrominoShape,
        scoreDelta: Int,
        linesCleared: Int
    ) {
        // Don't log if we've reached the maximum number of sessions
        if completedSessions >= maxSessions {
            return
        }
        
        guard let session = currentSession,
              let startTime = gameStartTime else {
            print("GameplayDataLogger: Cannot log move - no active session")
            return
        }
        
        let gameDuration = Date().timeIntervalSince(startTime)
        
        let move = GameplayMove(
            sessionId: session.sessionId,
            timestamp: Date(),
            boardState: flattenBoardState(boardState),
            availablePieces: encodePiecesAsBinary(availablePieces),
            selectedPiece: getPieceTypeId(selectedPiece),
            scoreDelta: scoreDelta,
            linesCleared: linesCleared,
            gameDuration: gameDuration
        )
        
        appendMoveToCSV(move)
    }
    
    // MARK: - CSV File Management
    
    private func setupCSVFile() {
        if !fileManager.fileExists(atPath: csvFileURL.path) {
            // Create new CSV file with header
            let header = GameplayMove.csvHeader + "\n"
            do {
                try header.write(to: csvFileURL, atomically: true, encoding: .utf8)
                print("GameplayDataLogger: Created new CSV file at \(csvFileURL.path)")
                print("GameplayDataLogger: Will collect data for \(maxSessions) game sessions (Currently: \(completedSessions)/\(maxSessions))")
            } catch {
                print("GameplayDataLogger: Error creating CSV file: \(error)")
            }
        } else {
            print("GameplayDataLogger: Using existing CSV file at \(csvFileURL.path)")
            print("GameplayDataLogger: Session progress: \(completedSessions)/\(maxSessions)")
        }
    }
    
    private func appendMoveToCSV(_ move: GameplayMove) {
        let csvRow = move.toCSVRow() + "\n"
        
        do {
            let fileHandle = try FileHandle(forWritingTo: csvFileURL)
            fileHandle.seekToEndOfFile()
            fileHandle.write(csvRow.data(using: .utf8)!)
            fileHandle.closeFile()
            
            print("GameplayDataLogger: Logged move - Piece: \(move.selectedPiece), Score: \(move.scoreDelta), Lines: \(move.linesCleared)")
        } catch {
            print("GameplayDataLogger: Error appending to CSV: \(error)")
        }
    }
    
    // MARK: - Data Encoding
    
    private func flattenBoardState(_ boardState: [[Bool]]) -> String {
        var flattenedState: [String] = []
        
        for row in boardState {
            for cell in row {
                flattenedState.append(cell ? "1" : "0")
            }
        }
        
        return flattenedState.joined(separator: ",")
    }
    
    private func encodePiecesAsBinary(_ pieces: [TetrominoShape]) -> String {
        // Get all possible piece types for binary encoding
        let allPieceTypes = TetrominoShape.allCases
        var binaryEncoding: [String] = []
        
        for pieceType in allPieceTypes {
            let isAvailable = pieces.contains(pieceType)
            binaryEncoding.append(isAvailable ? "1" : "0")
        }
        
        return binaryEncoding.joined(separator: ",")
    }
    
    private func getPieceTypeId(_ piece: TetrominoShape) -> Int {
        // Return the index of the piece in the enum's allCases array
        return TetrominoShape.allCases.firstIndex(of: piece) ?? -1
    }
    
    // MARK: - Utilities
    
    /// Get the current CSV file URL for debugging/testing
    func getCSVFileURL() -> URL {
        return csvFileURL
    }
    
    /// Get file size for monitoring
    func getCSVFileSize() -> Int64 {
        do {
            let attributes = try fileManager.attributesOfItem(atPath: csvFileURL.path)
            return attributes[.size] as? Int64 ?? 0
        } catch {
            return 0
        }
    }
    
    /// Clear CSV file (for testing)
    func clearCSVFile() {
        do {
            try fileManager.removeItem(at: csvFileURL)
            setupCSVFile()
            print("GameplayDataLogger: CSV file cleared and recreated")
        } catch {
            print("GameplayDataLogger: Error clearing CSV file: \(error)")
        }
    }
    
    // MARK: - Session Management
    
    /// Check if logging is still active (hasn't reached 20 sessions)
    func isLoggingActive() -> Bool {
        return completedSessions < maxSessions
    }
    
    /// Get the current session count
    func getCompletedSessionCount() -> Int {
        return completedSessions
    }
    
    /// Get the maximum number of sessions
    func getMaxSessions() -> Int {
        return maxSessions
    }
    
    /// Reset the session counter (for testing or restarting data collection)
    func resetSessionCounter() {
        completedSessions = 0
        print("GameplayDataLogger: Session counter reset. Logging reactivated.")
    }
    
    // MARK: - Firebase Storage Upload Integration
    
    /// Upload current CSV file to Firebase Storage (called automatically after 20 sessions)
    private func uploadCSVToFirebase() {
        guard fileManager.fileExists(atPath: csvFileURL.path) else {
            print("GameplayDataLogger: No CSV file to upload")
            return
        }
        
        print("GameplayDataLogger: Initiating automatic Firebase Storage upload after \(maxSessions) sessions")
        
        CSVFirebaseUploader.shared.uploadCSVFile(at: csvFileURL) { [weak self] success, result in
            DispatchQueue.main.async {
                if success {
                    print("GameplayDataLogger: CSV file successfully uploaded to Firebase Storage: \(result ?? "unknown")")
                    // Keep local file as backup - don't delete it
                } else {
                    print("GameplayDataLogger: Failed to upload CSV file to Firebase Storage: \(result ?? "unknown error")")
                }
            }
        }
    }
    
    /// Manual trigger for Firebase Storage upload (for testing)
    func manualUploadToFirebase(completion: @escaping (Bool, String?) -> Void) {
        guard fileManager.fileExists(atPath: csvFileURL.path) else {
            completion(false, "No CSV file to upload")
            return
        }
        
        print("GameplayDataLogger: Manual Firebase Storage upload triggered")
        CSVFirebaseUploader.shared.uploadCSVFile(at: csvFileURL, completion: completion)
    }
    
    /// Debug method to check CSV file status
    func debugCSVFileStatus() {
        print("=== CSV File Debug Info ===")
        print("CSV file path: \(csvFileURL.path)")
        print("File exists: \(fileManager.fileExists(atPath: csvFileURL.path))")
        print("File size: \(getCSVFileSize()) bytes")
        
        if fileManager.fileExists(atPath: csvFileURL.path) {
            do {
                let content = try String(contentsOf: csvFileURL)
                let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
                print("Number of lines: \(lines.count)")
                if lines.count > 0 {
                    print("First line (header): \(lines[0])")
                }
                if lines.count > 1 {
                    print("Second line (sample data): \(lines[1])")
                }
            } catch {
                print("Error reading CSV file: \(error)")
            }
        }
        print("==========================")
    }
}
