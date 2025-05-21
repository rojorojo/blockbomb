
import SpriteKit

class Grid {
    let columns: Int
    let rows: Int
    let tileSize: CGFloat
    let node = SKNode()
    var tiles: [[SKSpriteNode?]]

    var size: CGSize {
        return CGSize(width: CGFloat(columns) * tileSize, height: CGFloat(rows) * tileSize)
    }

    init(columns: Int, rows: Int, tileSize: CGFloat) {
        self.columns = columns
        self.rows = rows
        self.tileSize = tileSize
        self.tiles = Array(repeating: Array(repeating: nil, count: rows), count: columns)
        setupGrid()
    }

    private func setupGrid() {
        for col in 0..<columns {
            for row in 0..<rows {
                let tile = SKSpriteNode(color: .darkGray, size: CGSize(width: tileSize - 2, height: tileSize - 2))
                tile.position = CGPoint(x: CGFloat(col) * tileSize + tileSize / 2,
                                        y: CGFloat(row) * tileSize + tileSize / 2)
                node.addChild(tile)
            }
        }
    }
}
//
//  Grid.swift
//  blockbomb
//
//  Created by Robert Johnson on 5/15/25.
//

