import SwiftUI
import SpriteKit

struct ShapeGalleryView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 20) {
                    ForEach(TetrominoShape.allCases, id: \.self) { shape in
                        VStack {
                            TetrominoPreviewView(shape: shape)
                                .frame(height: 80)
                                .padding(10)
                                .background(Color(UIColor.systemGray6))
                                .cornerRadius(8)
                            
                            Text(String(describing: shape))
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(.top, 4)
                        }
                    }
                }
                .padding()
            }
            .background(Color(red: 0.1, green: 0.1, blue: 0.2))
            .navigationTitle("Shape Gallery")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back to Game") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .navigationViewStyle(.stack)
    }
}

struct TetrominoPreviewView: UIViewRepresentable {
    let shape: TetrominoShape
    
    func makeUIView(context: Context) -> SKView {
        let view = SKView()
        view.allowsTransparency = true
        view.backgroundColor = UIColor.black
        
        let scene = TetrominoPreviewScene(shape: shape, size: CGSize(width: 100, height: 80))
        scene.scaleMode = .aspectFit
        scene.backgroundColor = UIColor.black
        
        view.presentScene(scene)
        return view
    }
    
    func updateUIView(_ uiView: SKView, context: Context) {
        // No updates needed
    }
}

class TetrominoPreviewScene: SKScene {
    let shape: TetrominoShape
    let blockSize: CGFloat = 12
    
    init(shape: TetrominoShape, size: CGSize) {
        self.shape = shape
        super.init(size: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMove(to view: SKView) {
        backgroundColor = .clear
        
        let shapeNode = createShapeNode(for: shape)
        shapeNode.position = CGPoint(x: size.width/2, y: size.height/2)
        addChild(shapeNode)
    }
    
    private func createShapeNode(for shape: TetrominoShape) -> SKNode {
        let container = SKNode()
        
        // Get cells for this shape
        let cells = shape.cells()
        
        // Find minimum and maximum coordinates to center the shape
        var minX = Int.max, minY = Int.max
        var maxX = Int.min, maxY = Int.min
        
        for cell in cells {
            minX = min(minX, cell.column)
            minY = min(minY, cell.row)
            maxX = max(maxX, cell.column)
            maxY = max(maxY, cell.row)
        }
        
        let width = maxX - minX + 1
        let height = maxY - minY + 1
        
        // Create blocks
        for cell in cells {
            let block = SKShapeNode(rectOf: CGSize(width: blockSize - 2, height: blockSize - 2), cornerRadius: 3)
            block.fillColor = shape.color
            block.strokeColor = UIColor.black
            block.lineWidth = 1
            
            // Position block relative to shape center
            let xOffset = CGFloat(cell.column - minX - width/2) * blockSize
            let yOffset = CGFloat(cell.row - minY - height/2) * blockSize
            block.position = CGPoint(x: xOffset + blockSize/2, y: yOffset + blockSize/2)
            
            container.addChild(block)
        }
        
        return container
    }
}

// SwiftUI preview provider
struct ShapeGalleryView_Previews: PreviewProvider {
    static var previews: some View {
        ShapeGalleryView()
    }
}
