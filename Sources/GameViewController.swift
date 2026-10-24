import UIKit
import SpriteKit

public class GameViewController: UIViewController {

    public var skView: SKView {
        return self.view as! SKView
    }

    override public func loadView() {
        let view = SKView(frame: UIScreen.main.bounds)
        view.backgroundColor = .black
        view.ignoresSiblingOrder = true
        view.showsFPS = false
        view.showsNodeCount = false
        self.view = view
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if skView.scene == nil {
            let sceneSize = CGSize(width: 1334, height: 750)
            let menuScene = MainMenuScene(size: sceneSize)
            menuScene.scaleMode = .aspectFill
            skView.presentScene(menuScene)
        }
    }

    override public var shouldAutorotate: Bool {
        return true
    }

    override public var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }

    override public var prefersStatusBarHidden: Bool {
        return true
    }
}
