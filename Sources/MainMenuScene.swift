import SpriteKit

public class MainMenuScene: SKScene {

    override public func didMove(to view: SKView) {
        self.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        self.backgroundColor = SKColor(red: 0.1, green: 0.05, blue: 0.05, alpha: 1.0)

        // Background Image
        if let bgTexture = loadTexture(named: "Episode01BG.png") {
            let bgNode = SKSpriteNode(texture: bgTexture)
            bgNode.size = self.size
            bgNode.zPosition = -10
            addChild(bgNode)
        }

        // Trucks & Skulls Logo
        if let logoTexture = loadTexture(named: "T&SLogo02_Phone.png") {
            let logo = SKSpriteNode(texture: logoTexture)
            logo.position = CGPoint(x: 0, y: 120)
            let scaleRatio = min(600.0 / logo.size.width, 300.0 / logo.size.height)
            logo.setScale(scaleRatio)
            logo.zPosition = 5
            addChild(logo)

            let pulse = SKAction.sequence([
                SKAction.scale(to: scaleRatio * 1.05, duration: 1.2),
                SKAction.scale(to: scaleRatio * 0.98, duration: 1.2)
            ])
            logo.run(SKAction.repeatForever(pulse))
        } else {
            let titleLabel = SKLabelNode(fontNamed: "HelveticaNeue-Black")
            titleLabel.text = "TRUCKS & SKULLS"
            titleLabel.fontSize = 54
            titleLabel.fontColor = .orange
            titleLabel.position = CGPoint(x: 0, y: 120)
            titleLabel.zPosition = 5
            addChild(titleLabel)
        }

        // Play Button
        let playButton = SKShapeNode(rectOf: CGSize(width: 260, height: 75), cornerRadius: 18)
        playButton.fillColor = SKColor(red: 0.85, green: 0.2, blue: 0.1, alpha: 1.0)
        playButton.strokeColor = .yellow
        playButton.lineWidth = 4
        playButton.position = CGPoint(x: 0, y: -50)
        playButton.name = "PlayButton"
        playButton.zPosition = 10
        addChild(playButton)

        let playLabel = SKLabelNode(fontNamed: "HelveticaNeue-Black")
        playLabel.text = "PLAY GAME"
        playLabel.fontSize = 32
        playLabel.fontColor = .white
        playLabel.verticalAlignmentMode = .center
        playLabel.name = "PlayButton"
        playButton.addChild(playLabel)

        // Subtitle
        let subLabel = SKLabelNode(fontNamed: "HelveticaNeue-Bold")
        subLabel.text = "306 CLASSIC LEVELS • ARM64 RETRO"
        subLabel.fontSize = 18
        subLabel.fontColor = SKColor(white: 0.8, alpha: 1.0)
        subLabel.position = CGPoint(x: 0, y: -130)
        subLabel.zPosition = 10
        addChild(subLabel)

        // Start title music
        AudioManager.shared.playMusic()
    }

    private func loadTexture(named name: String) -> SKTexture? {
        if let image = UIImage(named: name) {
            return SKTexture(image: image)
        }
        if let path = Bundle.main.path(forResource: name, ofType: nil) {
            return SKTexture(imageNamed: path)
        }
        if let path = Bundle.main.path(forResource: name, ofType: nil, inDirectory: "Textures") {
            return SKTexture(imageNamed: path)
        }
        return nil
    }

    override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let touchedNodes = nodes(at: location)

        for node in touchedNodes {
            if node.name == "PlayButton" || node.parent?.name == "PlayButton" {
                startGame()
                return
            }
        }
        // Anywhere tap starts game
        startGame()
    }

    private func startGame() {
        guard let skView = self.view else { return }
        let gameScene = GameScene(size: self.size)
        gameScene.scaleMode = .aspectFill
        let transition = SKTransition.doorsOpenHorizontal(withDuration: 0.6)
        skView.presentScene(gameScene, transition: transition)
    }
}
