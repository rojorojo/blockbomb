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
        
        // Check if we touched a draggable piece
        if let node = nodes(at: location).first(where: { $0.name == "draggable_piece" }) as? PieceNode {
            selectedNode = node
            // Convert the node's position to scene coordinates for dragging
            // This is important because the node is now inside a container
            let nodePositionInScene = node.parent!.convert(node.position, to: self)
            originalPosition = nodePositionInScene
            // Remove from parent container and add directly to scene for dragging
            let nodeScale = node.xScale
            let zPosition = node.zPosition
            node.removeFromParent()
            node.position = nodePositionInScene
            node.setScale(nodeScale)
            node.zPosition = zPosition
            addChild(node)
            // Calculate offset between touch point and node center
            // Apply additional vertical offset to position piece above finger
            touchOffset = CGPoint(
                x: node.position.x - location.x,
                y: node.position.y - location.y + dragVerticalOffset
            )
            // Scale up slightly to indicate selection
            node.run(SKAction.scale(to: 1.1 * nodeScale, duration: 0.1))
            node.zPosition = 150
        }
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
        
        // Update ghost piece preview - use the piece position (not touch location)
        // to determine grid cell, since the piece has been offset from the touch
        if let gridCell = gameBoard.gridCellAt(scenePosition: offsetPosition) {
            if gridCell != currentGridCell {
                currentGridCell = gridCell
                gameBoard.showGhostPiece(selectedNode.gridPiece, at: gridCell)
            }
        } else {
            // Not over grid, clear ghost
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
                
                // Show more dramatic confirmation for line clears
                if (linesCleared.rows > 0 || linesCleared.columns > 0) {
                    flashLinesClearedConfirmation(at: selectedNode.position, 
                                                  rows: linesCleared.rows, 
                                                  columns: linesCleared.columns)
                } else {
                    flashConfirmation(at: selectedNode.position)
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
                
                // Create animation to move back
                let moveBack = SKAction.move(to: containerCenter, duration: 0.2)
                let scaleBack = SKAction.scale(to: 0.6, duration: 0.1)
                
                selectedNode.run(SKAction.group([moveBack, scaleBack])) { [weak self] in
                    // Remove from scene and add back to the container
                    guard let self = self, let selectedNode = self.selectedNode else { return }
                    selectedNode.removeFromParent()
                    
                    // First measure the piece to find its center offset
                    let tempNode = SKNode()
                    self.addChild(tempNode)
                    tempNode.addChild(selectedNode)
                    
                    // Get the bounding box of the piece
                    let bounds = selectedNode.calculateAccumulatedFrame()
                    
                    // Calculate the offset from the piece's registration point to its visual center
                    let centerOffsetX = bounds.midX - selectedNode.position.x
                    let centerOffsetY = bounds.midY - selectedNode.position.y
                    
                    // Remove from temp measurement node
                    selectedNode.removeFromParent()
                    tempNode.removeFromParent()
                    
                    // Position the piece so its visual center aligns with the container center
                    selectedNode.position = CGPoint(x: -centerOffsetX, y: -centerOffsetY)
                    selectedNode.zPosition = 100.0
                    container.addChild(selectedNode)
                    
                    // Restore the floating animation
                    let moveAction = SKAction.sequence([
                        SKAction.moveBy(x: 0, y: 5, duration: 0.5),
                        SKAction.moveBy(x: 0, y: -5, duration: 0.5)
                    ])
                    selectedNode.run(SKAction.repeatForever(moveAction))
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
