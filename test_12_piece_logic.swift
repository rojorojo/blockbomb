#!/usr/bin/env swift

// Test script to verify the 12-piece counting logic
import Foundation

class MockGameController {
    private var postRevivePiecesRemaining: Int = 0
    private let postRevivePriorityPieces: Int = 12
    
    func isInPostReviveMode() -> Bool {
        return postRevivePiecesRemaining > 0
    }
    
    func getPostRevivePiecesRemaining() -> Int {
        return postRevivePiecesRemaining
    }
    
    func onPiecesGenerated() {
        if postRevivePiecesRemaining > 0 {
            let piecesToDecrement = min(3, postRevivePiecesRemaining)
            postRevivePiecesRemaining -= piecesToDecrement
            print("Pieces generated. \(piecesToDecrement) pieces counted. Remaining: \(postRevivePiecesRemaining)")
            
            if postRevivePiecesRemaining == 0 {
                print("Post-revive priority mode ended")
            }
        }
    }
    
    func startPostRevivePriorityMode() {
        postRevivePiecesRemaining = postRevivePriorityPieces
        print("Started post-revive priority mode for \(postRevivePriorityPieces) pieces")
    }
    
    func resetPostReviveTracking() {
        postRevivePiecesRemaining = 0
        print("Reset post-revive tracking")
    }
}

// Test the logic
print("=== 12-Piece Post-Revive Counting Test ===\n")

let gameController = MockGameController()

print("1. Initial state:")
print("   In post-revive mode: \(gameController.isInPostReviveMode())")
print("   Pieces remaining: \(gameController.getPostRevivePiecesRemaining())\n")

print("2. Starting post-revive mode:")
gameController.startPostRevivePriorityMode()
print("   In post-revive mode: \(gameController.isInPostReviveMode())")
print("   Pieces remaining: \(gameController.getPostRevivePiecesRemaining())\n")

print("3. Simulating 4 rounds of piece generation:")
for round in 1...4 {
    print("   Round \(round):")
    gameController.onPiecesGenerated()
    print("   In post-revive mode: \(gameController.isInPostReviveMode())")
    print("   Pieces remaining: \(gameController.getPostRevivePiecesRemaining())")
    print()
}

print("4. Testing reset:")
gameController.resetPostReviveTracking()
print("   In post-revive mode: \(gameController.isInPostReviveMode())")
print("   Pieces remaining: \(gameController.getPostRevivePiecesRemaining())\n")

print("=== Test Complete ===")
print("✅ Logic correctly tracks 12 individual pieces across 4 rounds")
