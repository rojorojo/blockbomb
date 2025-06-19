import Foundation
import SpriteKit

/// Handles game synchronization between multiplayer participants
class MultiplayerSynchronization {
    
    private weak var gameController: MultiplayerGameController?
    private weak var gameScene: GameScene?
    
    init(gameController: MultiplayerGameController) {
        self.gameController = gameController
        self.gameScene = gameController.gameScene
    }
    
    /// Generate synchronized pieces for all players
    func generateSynchronizedPieces(from matchState: MultiplayerGameState.MatchState) -> [TetrominoShape] {
        // Use the synchronized pieces from the match state
        let synchronizedPieces = matchState.currentPieces.compactMap { pieceData in
            pieceData.toGridPiece()?.shape
        }
        
        // Update game scene with synchronized pieces
        if let gameScene = gameScene {
            gameScene.setSynchronizedPieces(synchronizedPieces)
        }
        
        print("MultiplayerSynchronization: Generated \(synchronizedPieces.count) synchronized pieces")
        return synchronizedPieces
    }
    
    /// Create turn data for submission
    func createTurnData() -> MultiplayerGameState.MoveData {
        // Create a dummy GridPiece for now - in real implementation this would come from the game
        let dummyShape = TetrominoShape.allCases.randomElement() ?? TetrominoShape.squareSmall
        let dummyGridPiece = GridPiece(shape: dummyShape, color: dummyShape.color)
        let dummyPlacement = GridCell(column: 0, row: 0)
        
        return MultiplayerGameState.MoveData(
            piece: dummyGridPiece,
            placement: dummyPlacement,
            scoreGained: 10, // This should come from actual game logic
            linesCleared: 0  // This should come from actual game logic
        )
    }
    
    /// Validate board state consistency between players
    func validateBoardState(localBoard: [[GridCell?]], remoteBoard: [[GridCell?]]) -> Bool {
        guard localBoard.count == remoteBoard.count else { return false }
        
        for (rowIndex, localRow) in localBoard.enumerated() {
            guard localRow.count == remoteBoard[rowIndex].count else { return false }
            
            for (colIndex, localCell) in localRow.enumerated() {
                let remoteCell = remoteBoard[rowIndex][colIndex]
                
                // Compare cell states (simplified comparison)
                if (localCell == nil) != (remoteCell == nil) {
                    return false
                }
            }
        }
        
        return true
    }
    
    /// Synchronize piece generation using a shared seed
    func generatePiecesWithSeed(_ seed: UInt32, count: Int) -> [TetrominoShape] {
        var generator = MultiplayerGameState.SeededRandomGenerator(seed: UInt64(seed))
        var pieces: [TetrominoShape] = []
        
        for _ in 0..<count {
            let randomValue = generator.next()
            let randomCase = Int(randomValue % UInt64(TetrominoShape.allCases.count))
            pieces.append(TetrominoShape.allCases[randomCase])
        }
        
        return pieces
    }
}


