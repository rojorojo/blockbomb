import SwiftUI
import SpriteKit

struct GameSceneView: UIViewRepresentable {
    @ObservedObject var gameController: GameController
    var onShapeGalleryRequest: () -> Void
    
    func makeUIView(context: Context) -> SKView {
        // Create a properly configured SKView
        let view = SKView()
        view.ignoresSiblingOrder = true
        view.showsFPS = false
        view.showsNodeCount = false
        
        // Create the scene immediately rather than waiting for updateUIView
        let scene = GameScene()
        scene.scaleMode = .resizeFill
        
        // Connect scene to controller
        gameController.setGameScene(scene)

        scene.shapeGalleryRequestHandler = onShapeGalleryRequest
        
        
        // Present the scene immediately
        view.presentScene(scene)
        scene.size = view.bounds.size
        scene.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        
        return view
    }
    
    func updateUIView(_ uiView: SKView, context: Context) {
        // Make sure the scene is properly sized when the view updates
        if let scene = uiView.scene as? GameScene {
            // Only update size if it has changed significantly
            if abs(scene.size.width - uiView.bounds.width) > 1 || 
               abs(scene.size.height - uiView.bounds.height) > 1 {
                scene.size = uiView.bounds.size
            }
            
            // Ensure game over display setting is maintained
            scene.shouldDisplayGameOver = false
        }
    }
}
