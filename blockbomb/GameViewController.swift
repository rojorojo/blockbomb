// GameViewController.swift

import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Print debug info to help diagnose the blank screen issue
        print("GameViewController viewDidLoad")
        
        // Configure the view
        if let view = self.view as? SKView {
            print("Setting up SKView")
            
            // Create and configure the scene
            let scene = GameScene(size: view.bounds.size)
            print("Scene created with size: \(view.bounds.size)")
            scene.scaleMode = .aspectFill
            
            // Present the scene
            view.presentScene(scene)
            
            // SpriteKit debugging options
            view.ignoresSiblingOrder = true
            view.showsFPS = true
            view.showsNodeCount = true
            
            print("Scene presented to view")
        } else {
            print("Failed to cast view to SKView")
        }
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
