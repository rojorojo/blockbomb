import SpriteKit

// Extension containing all touch handling functionality
extension GameScene {
    // MARK: - Touch Handling
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        // Check if we touched the debug button
        if let touchedNode = nodes(at: location).first, touchedNode.name == "debugButton" {
            // Present the SwiftUI gallery view instead of the SpriteKit version
            presentSwiftUIShapeGallery()
            return
        }
        
        // Check if we touched the reset hearts debug button
        if let touchedNode = nodes(at: location).first, touchedNode.name == "resetHeartsButton" {
            // Reset heart count to 3 for testing purposes
            #if DEBUG
            ReviveHeartManager.shared.debugSetHearts(3)
            print("Debug: Reset heart count to 3")
            #endif
            return
        }
        
        // Check if we touched the reset hearts button
        if let touchedNode = nodes(at: location).first, touchedNode.name == "resetHeartsButton" {
            // Reset hearts to 3 for testing
            ReviveHeartManager.shared.debugSetHearts(3)
            return
        }
        
        // Look for a draggable node (either piece or container touch target)
        if let touchedNode = nodes(at: location).first(where: { $0.name == "draggable_piece" }) {
            
            // Handle touch differently based on node type
            if let pieceNode = touchedNode as? PieceNode {
                // Direct piece touch - use existing handling
                handlePieceTouchBegan(pieceNode, at: location)
            }
            else {
                // Container touch target - extract container index and find piece
                handleContainerTouchBegan(touchedNode, at: location)
            }
        }
    }
    
    // Helper to handle touches that hit a piece directly
    private func handlePieceTouchBegan(_ pieceNode: PieceNode, at location: CGPoint) {
        selectedNode = pieceNode
        
        // Convert the node's position to scene coordinates for dragging
        let nodePositionInScene = pieceNode.parent!.convert(pieceNode.position, to: self)
        originalPosition = nodePositionInScene
        
        // Standard piece handling
        let nodeScale = pieceNode.xScale
        pieceNode.removeFromParent()
        pieceNode.position = nodePositionInScene
        pieceNode.zPosition = 150
        addChild(pieceNode)
        
        // Scale up for dragging
        pieceNode.run(SKAction.scale(to: 1.2, duration: 0.1))
        
        // Apply offset
        touchOffset = CGPoint(
            x: pieceNode.position.x - location.x,
            y: pieceNode.position.y - location.y + dragVerticalOffset
        )
    }
    
    // Helper to handle touches that hit a container's touch target
    private func handleContainerTouchBegan(_ touchTarget: SKNode, at location: CGPoint) {
        // Extract container info from the touch target
        guard let containerIndex = touchTarget.userData?.value(forKey: "containerIndex") as? Int,
              let container = childNode(withName: "pieceContainer\(containerIndex)"),
              let pieceNode = container.children.first(where: { $0.name == "piece" }) as? PieceNode else {
            return
        }
        
        // Set this as our selected node
        selectedNode = pieceNode
        
        // Get position info
        let nodePositionInScene = container.convert(pieceNode.position, to: self)
        originalPosition = nodePositionInScene
        
        // Remove piece from container
        pieceNode.removeFromParent()
        
        // Position piece at original position first
        pieceNode.position = nodePositionInScene
        pieceNode.zPosition = 150
        addChild(pieceNode)
        
        // Scale up for dragging
        pieceNode.run(SKAction.scale(to: 1.2, duration: 0.1))
        
        // Calculate offset for finger position
        touchOffset = CGPoint(
            x: pieceNode.position.x - location.x,
            y: pieceNode.position.y - location.y + dragVerticalOffset
        )
        
        // Move piece immediately to correct finger offset position
        let newPosition = CGPoint(
            x: location.x + touchOffset.x,
            y: location.y + touchOffset.y
        )
        pieceNode.position = newPosition
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let selectedNode = selectedNode else { return }
        let location = touch.location(in: self)
        
        // Apply the stored offset to position the piece above the finger
        let offsetPosition = CGPoint(
            x: location.x + touchOffset.x,
            y: location.y + touchOffset.y
        )
        selectedNode.position = offsetPosition
        
        // Update ghost piece preview and glow effects - use the piece position (not touch location)
        // to determine grid cell, since the piece has been offset from the touch
        if let gridCell = gameBoard.gridCellAt(scenePosition: offsetPosition) {
            if gridCell != currentGridCell {
                currentGridCell = gridCell
                gameBoard.showGhostPiece(selectedNode.gridPiece, at: gridCell)
                
                // Show completion glow preview if piece can be placed
                if gameBoard.canPlacePiece(selectedNode.gridPiece, at: gridCell) {
                    gameBoard.showCompletionGlow(for: selectedNode.gridPiece, at: gridCell)
                }
            }
        } else {
            // Not over grid, clear ghost and glow
            currentGridCell = nil
            gameBoard.clearGhostPiece() 
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let selectedNode = selectedNode, let originalPosition = originalPosition else { return }
        
        // Reset the touch offset
        touchOffset = .zero
        
        // Check if we have a valid grid cell
        if let gridCell = currentGridCell {
            if gameBoard.canPlacePiece(selectedNode.gridPiece, at: gridCell) {
                // Award points for the piece and cleared lines
                let linesCleared = gameBoard.placePiece(selectedNode.gridPiece, at: gridCell)
                let rowPoints = calculatePoints(forLines: linesCleared.rows)
                let columnPoints = calculatePoints(forLines: linesCleared.columns)
                let comboBonus = (linesCleared.rows > 0 && linesCleared.columns > 0) ? 500 : 0
                let piecePoints = calculatePointsForPiece(selectedNode.gridPiece)
                score += piecePoints + rowPoints + columnPoints + comboBonus
                updateScoreLabel()
                
                // Play audio for different scenarios
                if (linesCleared.rows > 0 && linesCleared.columns > 0) {
                    // Combo - escalating combo sound based on total lines cleared
                    let totalLines = linesCleared.rows + linesCleared.columns
                    AudioManager.shared.playComboSound(comboLevel: totalLines)
                    AudioManager.shared.triggerHapticFeedback(for: .combo)
                } else if (linesCleared.rows > 0 || linesCleared.columns > 0) {
                    // Line clear - escalating sound based on number of lines
                    let totalLines = linesCleared.rows + linesCleared.columns
                    AudioManager.shared.playLineClearSound(lineCount: totalLines)
                    AudioManager.shared.triggerHapticFeedback(for: .lineClear)
                } else {
                    // Simple block placement
                    AudioManager.shared.playBlockPlaceSound()
                    AudioManager.shared.triggerHapticFeedback(for: .blockPlace)
                }
                
                // Show more dramatic confirmation for line clears
                if (linesCleared.rows > 0 || linesCleared.columns > 0) {
                    let totalPoints = piecePoints + rowPoints + columnPoints + comboBonus
                    flashLinesClearedConfirmation(rows: linesCleared.rows, 
                                                  columns: linesCleared.columns,
                                                  totalPoints: totalPoints)
                } else {
                    flashConfirmation()
                }
                
                // Remove the piece from the scene
                selectedNode.removeFromParent()
                
                // Remove from draggable pieces array
                if let index = pieceNodes.firstIndex(of: selectedNode) {
                    pieceNodes.remove(at: index)
                }
                
                // Reset selection
                self.selectedNode = nil
                self.originalPosition = nil
                self.currentGridCell = nil
                
                // Check if we need to set up new pieces
                if pieceNodes.isEmpty {
                    setupDraggablePieces()
                } else {
                    // After placing a piece, check if any remaining pieces can be placed
                    checkGameStateAfterPlacement()
                }
                
                return
            }
        }
        
        // If we couldn't place the piece, return it to its original container
        returnPieceToContainer()
        
        // Play invalid placement sound if the piece was dropped over the grid but couldn't be placed
        if currentGridCell != nil {
            AudioManager.shared.playInvalidPlacementSound()
            AudioManager.shared.triggerHapticFeedback(for: .invalidPlacement)
        }
        
        // Reset selection
        self.selectedNode = nil
        self.originalPosition = nil
        self.currentGridCell = nil
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Handle touch cancellation (like system interruption) the same as touchesEnded
        touchOffset = .zero
        returnPieceToContainer()
        self.selectedNode = nil
        self.originalPosition = nil
        self.currentGridCell = nil
    }
    
    func returnPieceToContainer() {
        guard let selectedNode = selectedNode else { return }
        
        // Find the container this piece belongs to
        if let index = pieceNodes.firstIndex(of: selectedNode) {
            if let container = childNode(withName: "pieceContainer\(index)") {
                // Calculate the destination position (the center of the container in scene coordinates)
                let containerCenter = container.position
                
                // Create animation to move back to container center
                let moveBack = SKAction.move(to: containerCenter, duration: 0.2)
                let scaleBack = SKAction.scale(to: 0.6, duration: 0.1)  // Scale back to container size
                
                // Store the piece's shape to recreate it correctly
                let pieceShape = selectedNode.gridPiece.shape
                let pieceColor = selectedNode.gridPiece.shape.color
                
                selectedNode.run(SKAction.group([moveBack, scaleBack])) { [weak self] in
                    guard let self = self else { return }
                    
                    // Remove the existing piece
                    selectedNode.removeFromParent()
                    
                    // Instead of trying to reposition the existing piece, create a new one
                    // This ensures it's created using the same code path as the initial setup
                    let newPiece = PieceNode(shape: pieceShape, color: pieceColor)
                    
                    // Apply scale first
                    newPiece.setScale(0.6)
                    
                    // This matches the code in setupDraggablePieces to ensure consistency
                    let tempNode = SKNode()
                    self.addChild(tempNode)
                    tempNode.addChild(newPiece)
                    
                    // Get the bounding box of the piece
                    let bounds = newPiece.calculateAccumulatedFrame()
                    
                    // Calculate the offset from the piece's registration point to its visual center
                    let centerOffsetX = bounds.midX - newPiece.position.x
                    let centerOffsetY = bounds.midY - newPiece.position.y
                    
                    // Remove from temp measurement node
                    newPiece.removeFromParent()
                    tempNode.removeFromParent()
                    
                    // Position exactly as in setupDraggablePieces
                    newPiece.position = CGPoint(x: -centerOffsetX, y: -centerOffsetY)
                    newPiece.name = "piece"  // Use the new piece name
                    newPiece.zPosition = 100
                    container.addChild(newPiece)
                    
                    // Replace the old piece reference with the new one
                    if let selectedIndex = self.pieceNodes.firstIndex(of: selectedNode) {
                        self.pieceNodes[selectedIndex] = newPiece
                    }
                    
                    // Add the floating animation
                    let moveAction = SKAction.sequence([
                        SKAction.moveBy(x: 0, y: 5, duration: 0.5),
                        SKAction.moveBy(x: 0, y: -5, duration: 0.5)
                    ])
                    newPiece.run(SKAction.repeatForever(moveAction))
                }
            } else {
                // Fallback if container not found
                returnPieceToOriginalPosition()
            }
        } else {
            // Fallback if piece not in pieceNodes
            returnPieceToOriginalPosition()
        }
        
        // Reset selection
        self.selectedNode = nil
        self.originalPosition = nil
        self.currentGridCell = nil
    }
    
    func returnPieceToOriginalPosition() {
        guard let selectedNode = selectedNode, let originalPosition = originalPosition else { return }
        let moveBack = SKAction.move(to: originalPosition, duration: 0.2)
        selectedNode.run(moveBack)
    }
    
    func isOverGameBoard(_ position: CGPoint) -> Bool {
        let boardRect = CGRect(
            x: gameBoard.boardNode.position.x,
            y: gameBoard.boardNode.position.y,
            width: CGFloat(gameBoard.columns) * gameBoard.blockSize,
            height: CGFloat(gameBoard.rows) * gameBoard.blockSize
        )
        return boardRect.contains(position)
    }
}
