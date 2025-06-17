import Foundation
import FirebaseStorage

/// Firebase Storage configuration for CSV uploads
struct CSVFirebaseConfig {
    // Firebase Storage Configuration
    static let bucketPath = "gameplay_data" // Folder path in Firebase Storage
    
    // Generate timestamped filename
    static func generateTimestampedFilename(for originalFilename: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
        let timestamp = dateFormatter.string(from: Date())
        
        // Extract file extension
        let fileExtension = (originalFilename as NSString).pathExtension
        let baseName = (originalFilename as NSString).deletingPathExtension
        
        return "\(baseName)_\(timestamp).\(fileExtension)"
    }
    
    // Get storage reference
    static func getStorageReference() -> StorageReference {
        return Storage.storage().reference().child(bucketPath)
    }
}
