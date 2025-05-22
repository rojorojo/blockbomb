import SwiftUI
import SpriteKit

struct ShapeGalleryView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            
                List {
                ForEach(TetrominoShape.Category.allCases, id: \.self) { category in
                    Section(header: Text(category.rawValue)) {
                        ForEach(TetrominoShape.shapes(in: category), id: \.self) { shape in
                            HStack {
                                ShapePreviewView(shape: shape)
                                    .frame(width: 60, height: 60)
                                    .background(shape.uiColor.opacity(0.3))
                                    .cornerRadius(6)
                                
                                Text(shape.displayName)
                                    .font(.body)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Shape Gallery")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
            
            .background(Color(UIColor(red: 0.1, green: 0.1, blue: 0.2, alpha: 1.0)))
            .edgesIgnoringSafeArea([.horizontal, .bottom])
            
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct ShapePreviewView: UIViewRepresentable {
    let shape: TetrominoShape
    
    func makeUIView(context: Context) -> SKView {
        let view = SKView()
        view.backgroundColor = .clear
        
        let scene = SKScene(size: CGSize(width: 100, height: 100))
        scene.backgroundColor = .clear
        
        let node = createShapeNode(for: shape)
        node.position = CGPoint(x: scene.size.width/2, y: scene.size.height/2)
        scene.addChild(node)
        
        view.presentScene(scene)
        return view
    }
    
    func updateUIView(_ uiView: SKView, context: Context) {
        // No updates needed
    }
    
    private func createShapeNode(for shape: TetrominoShape) -> SKNode {
        let container = SKNode()
        let blockSize: CGFloat = 15
        
        // Get cells for this shape
        let cells = shape.cells
        
        // Find min/max coordinates to center the shape
        var minX = Int.max, minY = Int.max, maxX = Int.min, maxY = Int.min
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
            let block = SKShapeNode(rectOf: CGSize(width: blockSize-2, height: blockSize-2), cornerRadius: 2)
            block.fillColor = shape.color
            block.strokeColor = UIColor.black
            block.lineWidth = 1
           
            // Position relative to shape center
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
