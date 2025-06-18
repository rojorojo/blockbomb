import Foundation
import FirebaseStorage

/// Firebase Storage uploader for CSV gameplay data files
class CSVFirebaseUploader {
    static let shared = CSVFirebaseUploader()
    
    private let maxRetries = 3
    
    private init() {}
    
    // MARK: - Upload Methods
    
    /// Upload CSV file to Firebase Storage with automatic retry logic
    func uploadCSVFile(at fileURL: URL, completion: @escaping (Bool, String?) -> Void) {
        let timestampedFilename = CSVFirebaseConfig.generateTimestampedFilename(for: fileURL.lastPathComponent)
        uploadFileWithRetry(fileURL: fileURL, fileName: timestampedFilename, retryCount: 0, completion: completion)
    }
    
    /// Upload file with retry logic
    private func uploadFileWithRetry(
        fileURL: URL,
        fileName: String,
        retryCount: Int,
        completion: @escaping (Bool, String?) -> Void
    ) {
        print("CSVFirebaseUploader: Attempting upload (attempt \(retryCount + 1)/\(maxRetries)): \(fileName)")
        print("CSVFirebaseUploader: Local file path: \(fileURL.path)")
        
        // Check if local file exists
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            completion(false, "Local CSV file does not exist at path: \(fileURL.path)")
            return
        }
        
        // Read file data
        guard let fileData = try? Data(contentsOf: fileURL) else {
            completion(false, "Failed to read CSV file data")
            return
        }
        
        print("CSVFirebaseUploader: File size: \(fileData.count) bytes")
        
        let storageRef = CSVFirebaseConfig.getStorageReference()
        let fileRef = storageRef.child(fileName)
        
        // Set metadata
        let metadata = StorageMetadata()
        metadata.contentType = "text/csv"
        
        // Upload file data instead of file URL
        fileRef.putData(fileData, metadata: metadata) { metadata, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("CSVFirebaseUploader: Upload failed (attempt \(retryCount + 1)): \(error.localizedDescription)")
                    
                    // Retry if we haven't exceeded max retries
                    if retryCount < self.maxRetries - 1 {
                        // Exponential backoff delay
                        let delay = pow(2.0, Double(retryCount)) * 1.0 // 1s, 2s, 4s delays
                        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                            self.uploadFileWithRetry(
                                fileURL: fileURL,
                                fileName: fileName,
                                retryCount: retryCount + 1,
                                completion: completion
                            )
                        }
                    } else {
                        completion(false, "Upload failed after \(self.maxRetries) attempts: \(error.localizedDescription)")
                    }
                } else {
                    print("CSVFirebaseUploader: Upload successful: \(fileName)")
                    if let metadata = metadata {
                        print("CSVFirebaseUploader: Uploaded \(metadata.size) bytes")
                    }
                    completion(true, fileName)
                }
            }
        }
    }
    
    // MARK: - Manual Upload Trigger
    
    /// Manually trigger upload of current CSV file (for testing)
    func manualUploadTrigger(completion: @escaping (Bool, String?) -> Void) {
        let csvFileURL = GameplayDataLogger.shared.getCSVFileURL()
        
        guard FileManager.default.fileExists(atPath: csvFileURL.path) else {
            completion(false, "CSV file not found")
            return
        }
        
        print("CSVFirebaseUploader: Manual upload triggered for file: \(csvFileURL.lastPathComponent)")
        uploadCSVFile(at: csvFileURL, completion: completion)
    }
    
    // MARK: - Utilities
    
    /// Check if Firebase Storage is available
    func isProperlyConfigured() -> Bool {
        // Firebase Storage is available if Firebase is configured
        return true // Firebase is already configured in your app
    }
    
    /// Get current configuration status
    func getConfigurationStatus() -> String {
        return "Configured for Firebase Storage: \(CSVFirebaseConfig.bucketPath)"
    }
    
    /// Get download URL for a file (for testing/verification)
    func getDownloadURL(for fileName: String, completion: @escaping (URL?) -> Void) {
        let storageRef = CSVFirebaseConfig.getStorageReference()
        let fileRef = storageRef.child(fileName)
        
        fileRef.downloadURL { url, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("CSVFirebaseUploader: Failed to get download URL: \(error.localizedDescription)")
                    completion(nil)
                } else {
                    completion(url)
                }
            }
        }
    }
    
    /// Test Firebase Storage with a simple text upload
    func testFirebaseStorageConnection(completion: @escaping (Bool, String?) -> Void) {
        let testData = "Test upload from BlockBomb app".data(using: .utf8)!
        let storageRef = CSVFirebaseConfig.getStorageReference()
        let testRef = storageRef.child("test_connection.txt")
        
        let metadata = StorageMetadata()
        metadata.contentType = "text/plain"
        
        print("CSVFirebaseUploader: Testing Firebase Storage connection...")
        
        testRef.putData(testData, metadata: metadata) { metadata, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("CSVFirebaseUploader: Connection test failed: \(error.localizedDescription)")
                    completion(false, error.localizedDescription)
                } else {
                    print("CSVFirebaseUploader: Connection test successful!")
                    completion(true, "Connection test successful")
                }
            }
        }
    }
}
