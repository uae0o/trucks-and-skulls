import SpriteKit
import AVFoundation

public struct PhysicsCategory {
    public static let none: UInt32      = 0
    public static let all: UInt32       = UInt32.max
    public static let ground: UInt32    = 0b1       // 1
    public static let structure: UInt32 = 0b10      // 2
    public static let skull: UInt32     = 0b100     // 4
    public static let truck: UInt32     = 0b1000    // 8
    public static let explosive: UInt32 = 0b10000   // 16
}

public class GameScene: SKScene, SKPhysicsContactDelegate {
    public var currentLevelIndex = 0
    public var levelFiles: [String] = []
    public var currentLevel: LevelData?

    private var activeTruck: TruckNode?
    private var truckQueue: [TruckType] = []
    private var launcherPosition = CGPoint(x: -400, y: -150)
    private var isDragging = false
    private var dragStart = CGPoint.zero
    private var dragCurrent = CGPoint.zero

    private var slingshotLine: SKShapeNode?
    private var trajectoryDots: [SKShapeNode] = []
    private var worldNode = SKNode()
    private var hudNode = SKNode()

    private var score = 0
    private var scoreLabel = SKLabelNode(fontNamed: "HelveticaNeue-Bold")
    private var skullsLeftLabel = SKLabelNode(fontNamed: "HelveticaNeue-Bold")
    private var remainingSkullsCount = 0

    override public func didMove(to view: SKView) {
        self.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        self.backgroundColor = SKColor(red: 0.12, green: 0.12, blue: 0.16, alpha: 1.0)
        
        physicsWorld.gravity = CGVector(dx: 0.0, dy: -9.8 * 80.0)
        physicsWorld.contactDelegate = self

        addChild(worldNode)
        addChild(hudNode)

        setupHUD()
        loadLevelList()
        if !levelFiles.isEmpty {
            loadLevel(named: levelFiles[currentLevelIndex])
        }
    }

    private func setupHUD() {
        scoreLabel.fontSize = 24
        scoreLabel.fontColor = .yellow
        scoreLabel.horizontalAlignmentMode = .left
        scoreLabel.position = CGPoint(x: -size.width / 2 + 40, y: size.height / 2 - 50)
        scoreLabel.text = "SCORE: 0"
        hudNode.addChild(scoreLabel)

        skullsLeftLabel.fontSize = 24
        skullsLeftLabel.fontColor = .red
        skullsLeftLabel.horizontalAlignmentMode = .right
        skullsLeftLabel.position = CGPoint(x: size.width / 2 - 40, y: size.height / 2 - 50)
        skullsLeftLabel.text = "SKULLS: 0"
        hudNode.addChild(skullsLeftLabel)

        slingshotLine = SKShapeNode()
        slingshotLine?.strokeColor = .yellow
        slingshotLine?.lineWidth = 4
        worldNode.addChild(slingshotLine!)

        for _ in 0..<15 {
            let dot = SKShapeNode(circleOfRadius: 4)
            dot.fillColor = .white
            dot.strokeColor = .clear
            dot.alpha = 0.6
            dot.isHidden = true
            worldNode.addChild(dot)
            trajectoryDots.append(dot)
        }
    }

    private func loadLevelList() {
        if let url = Bundle.main.url(forResource: "levels_index", withExtension: "json", subdirectory: "Levels"),
           let data = try? Data(contentsOf: url),
           let list = try? JSONDecoder().decode([String].self, from: data) {
            levelFiles = list
        } else {
            // Fallback list of levels
            levelFiles = ["Episode01_Level01", "Ambush", "Arachnoid"]
        }
    }

    public func loadLevel(named levelName: String) {
        worldNode.removeAllChildren()
        worldNode.addChild(slingshotLine!)
        for dot in trajectoryDots { worldNode.addChild(dot) }

        var filename = levelName
        if filename.hasSuffix(".json") {
            filename = String(filename.dropLast(5))
        }

        var loadedData: LevelData?
        if let url = Bundle.main.url(forResource: filename, withExtension: "json", subdirectory: "Levels"),
           let data = try? Data(contentsOf: url) {
            loadedData = try? JSONDecoder().decode(LevelData.self, from: data)
        }

        guard let level = loadedData else {
            print("Failed to load level: \(levelName)")
            return
        }

        currentLevel = level
        remainingSkullsCount = 0

        if let lx = level.launcherX, let ly = level.launcherY {
            launcherPosition = CGPoint(x: lx, y: ly)
        } else {
            launcherPosition = CGPoint(x: -400, y: -150)
        }

        // Spawn Ground
        let groundW = level.width ?? 2034
        let groundH = level.height ?? 768
        let ground = SKSpriteNode(color: SKColor(red: 0.25, green: 0.15, blue: 0.1, alpha: 1.0),
                                  size: CGSize(width: groundW * 1.5, height: 120))
        ground.position = CGPoint(x: 0, y: -groundH / 2 + 20)
        ground.physicsBody = SKPhysicsBody(rectangleOf: ground.size)
        ground.physicsBody?.isDynamic = false
        ground.physicsBody?.categoryBitMask = PhysicsCategory.ground
        ground.physicsBody?.collisionBitMask = PhysicsCategory.all
        worldNode.addChild(ground)

        // Spawn Parts
        for part in level.parts {
            spawnPart(part)
        }

        // Setup Projectiles
        truckQueue.removeAll()
        if let projs = level.projectiles {
            for p in projs {
                if let t = TruckType(rawValue: p) {
                    truckQueue.append(t)
                } else {
                    truckQueue.append(.bus)
                }
            }
        }
        if truckQueue.isEmpty {
            truckQueue = [.bus, .bomber, .crotchRocket]
        }

        skullsLeftLabel.text = "SKULLS: \(remainingSkullsCount)"
        prepareNextTruck()
    }

    private func spawnPart(_ part: PartData) {
        let isSkull = part.name.contains("Skull")
        let isCircle = part.name.contains("Circle")
        let isTriangle = part.name.contains("Triangle")
        let isGround = part.name.contains("GroundBox")
        let isExplosive = part.name.contains("Boiler") || part.name.contains("Dynamite") || part.name.contains("Barrel")

        let size = determineSize(part.name)
        let color = determineColor(part.name)

        let node = SKSpriteNode(color: color, size: size)
        node.position = CGPoint(x: part.x, y: part.y)
        node.zRotation = part.angle * (.pi / 180.0)
        node.name = part.name

        if isCircle {
            node.physicsBody = SKPhysicsBody(circleOfRadius: size.width / 2)
        } else {
            node.physicsBody = SKPhysicsBody(rectangleOf: size)
        }

        if isGround {
            node.physicsBody?.isDynamic = false
            node.physicsBody?.categoryBitMask = PhysicsCategory.ground
        } else if isSkull {
            node.physicsBody?.isDynamic = true
            node.physicsBody?.categoryBitMask = PhysicsCategory.skull
            remainingSkullsCount += 1
        } else if isExplosive {
            node.physicsBody?.isDynamic = true
            node.physicsBody?.categoryBitMask = PhysicsCategory.explosive
        } else {
            node.physicsBody?.isDynamic = true
            node.physicsBody?.categoryBitMask = PhysicsCategory.structure
        }

        node.physicsBody?.collisionBitMask = PhysicsCategory.all
        node.physicsBody?.contactTestBitMask = PhysicsCategory.truck | PhysicsCategory.ground | PhysicsCategory.explosive

        worldNode.addChild(node)
    }

    private func determineSize(_ name: String) -> CGSize {
        if name.contains("GroundBox") { return CGSize(width: 2034, height: 100) }
        if name.contains("HugeSquare") { return CGSize(width: 140, height: 140) }
        if name.contains("LargeSquare") { return CGSize(width: 90, height: 90) }
        if name.contains("MediumSquare") { return CGSize(width: 55, height: 55) }
        if name.contains("SmallSquare") { return CGSize(width: 32, height: 32) }
        if name.contains("VeryLongBeam") { return CGSize(width: 220, height: 24) }
        if name.contains("LongBeam") { return CGSize(width: 160, height: 24) }
        if name.contains("LargeBeam") { return CGSize(width: 110, height: 24) }
        if name.contains("MediumBeam") { return CGSize(width: 75, height: 24) }
        if name.contains("SmallBeam") { return CGSize(width: 44, height: 24) }
        if name.contains("LargeCircle") { return CGSize(width: 80, height: 80) }
        if name.contains("MediumCircle") { return CGSize(width: 55, height: 55) }
        if name.contains("SmallCircle") { return CGSize(width: 32, height: 32) }
        if name.contains("Skull") { return CGSize(width: 44, height: 44) }
        if name.contains("Boiler") || name.contains("Barrel") { return CGSize(width: 45, height: 65) }
        return CGSize(width: 50, height: 50)
    }

    private func determineColor(_ name: String) -> SKColor {
        if name.contains("Skull") { return .white }
        if name.contains("Wood") { return SKColor(red: 0.72, green: 0.48, blue: 0.28, alpha: 1.0) }
        if name.contains("Glass") { return SKColor(red: 0.4, green: 0.8, blue: 0.9, alpha: 0.7) }
        if name.contains("Stone") { return SKColor(red: 0.6, green: 0.6, blue: 0.65, alpha: 1.0) }
        if name.contains("Steel") { return SKColor(red: 0.35, green: 0.4, blue: 0.5, alpha: 1.0) }
        if name.contains("Rubber") { return SKColor(red: 0.9, green: 0.7, blue: 0.1, alpha: 1.0) }
        if name.contains("Lava") { return SKColor(red: 0.95, green: 0.3, blue: 0.05, alpha: 1.0) }
        if name.contains("Explosive") || name.contains("Boiler") || name.contains("Dynamite") {
            return SKColor(red: 0.9, green: 0.1, blue: 0.1, alpha: 1.0)
        }
        return SKColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0)
    }

    private func prepareNextTruck() {
        guard !truckQueue.isEmpty else {
            checkGameOver()
            return
        }

        let type = truckQueue.removeFirst()
        let truck = TruckNode(type: type)
        truck.position = launcherPosition
        worldNode.addChild(truck)
        activeTruck = truck
    }

    override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: worldNode)

        if let truck = activeTruck, truck.isLaunched {
            // In flight tap -> trigger ability!
            truck.activateAbility()
            return
        }

        let dist = hypot(location.x - launcherPosition.x, location.y - launcherPosition.y)
        if dist < 120 {
            isDragging = true
            dragStart = launcherPosition
            dragCurrent = location
            updateSlingshotAim()
        }
    }

    override public func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isDragging, let touch = touches.first else { return }
        dragCurrent = touch.location(in: worldNode)
        updateSlingshotAim()
    }

    override public func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isDragging else { return }
        isDragging = false

        let dx = dragStart.x - dragCurrent.x
        let dy = dragStart.y - dragCurrent.y
        let pullDist = hypot(dx, dy)

        slingshotLine?.path = nil
        for dot in trajectoryDots { dot.isHidden = true }

        if pullDist > 30, let truck = activeTruck {
            let maxPull: CGFloat = 180.0
            let clampedDist = min(pullDist, maxPull)
            let ratio = clampedDist / pullDist
            let forceMult: CGFloat = 18.0

            let impulse = CGVector(dx: dx * ratio * forceMult, dy: dy * ratio * forceMult)
            truck.launch(withImpulse: impulse)

            // Switch to next truck after delay
            run(SKAction.sequence([
                SKAction.wait(forDuration: 5.0),
                SKAction.run { [weak self] in
                    self?.prepareNextTruck()
                }
            ]))
        }
    }

    private func updateSlingshotAim() {
        let path = CGMutablePath()
        path.move(to: launcherPosition)
        path.addLine(to: dragCurrent)
        slingshotLine?.path = path

        let dx = dragStart.x - dragCurrent.x
        let dy = dragStart.y - dragCurrent.y
        let forceMult: CGFloat = 18.0

        var simPos = launcherPosition
        var simVel = CGVector(dx: dx * forceMult * 0.016, dy: dy * forceMult * 0.016)
        let gravity = CGVector(dx: 0, dy: -9.8 * 80.0 * 0.016 * 0.016)

        for dot in trajectoryDots {
            dot.position = simPos
            dot.isHidden = false
            simVel.dx += gravity.dx
            simVel.dy += gravity.dy
            simPos.x += simVel.dx * 3.0
            simPos.y += simVel.dy * 3.0
        }
    }

    public func didBegin(_ contact: SKPhysicsContact) {
        let maskA = contact.bodyA.categoryBitMask
        let maskB = contact.bodyB.categoryBitMask

        // Check if Skull is hit
        if maskA == PhysicsCategory.skull || maskB == PhysicsCategory.skull {
            let skullBody = maskA == PhysicsCategory.skull ? contact.bodyA : contact.bodyB
            if let node = skullBody.node {
                destroySkull(node)
            }
        }

        // Check if Explosive is hit
        if maskA == PhysicsCategory.explosive || maskB == PhysicsCategory.explosive {
            let expBody = maskA == PhysicsCategory.explosive ? contact.bodyA : contact.bodyB
            if let node = expBody.node {
                triggerExplosion(at: node.position)
                node.removeFromParent()
            }
        }
    }

    private func destroySkull(_ node: SKNode) {
        node.removeFromParent()
        score += 5000
        remainingSkullsCount -= 1
        scoreLabel.text = "SCORE: \(score)"
        skullsLeftLabel.text = "SKULLS: \(max(0, remainingSkullsCount))"

        if remainingSkullsCount <= 0 {
            triggerWin()
        }
    }

    private func triggerExplosion(at pos: CGPoint) {
        score += 1000
        let flash = SKShapeNode(circleOfRadius: 80)
        flash.position = pos
        flash.fillColor = .orange
        flash.alpha = 0.8
        worldNode.addChild(flash)

        flash.run(SKAction.sequence([
            SKAction.scale(to: 2.0, duration: 0.15),
            SKAction.fadeOut(withDuration: 0.2),
            SKAction.removeFromParent()
        ]))
    }

    private func triggerWin() {
        let winLabel = SKLabelNode(fontNamed: "HelveticaNeue-Black")
        winLabel.text = "LEVEL COMPLETE!"
        winLabel.fontSize = 48
        winLabel.fontColor = .green
        winLabel.position = CGPoint(x: 0, y: 50)
        hudNode.addChild(winLabel)

        run(SKAction.sequence([
            SKAction.wait(forDuration: 2.5),
            SKAction.run { [weak self] in
                guard let self = self else { return }
                self.currentLevelIndex = (self.currentLevelIndex + 1) % self.levelFiles.count
                self.loadLevel(named: self.levelFiles[self.currentLevelIndex])
                winLabel.removeFromParent()
            }
        ]))
    }

    private func checkGameOver() {
        if remainingSkullsCount > 0 {
            let failLabel = SKLabelNode(fontNamed: "HelveticaNeue-Black")
            failLabel.text = "OUT OF TRUCKS!"
            failLabel.fontSize = 48
            failLabel.fontColor = .red
            failLabel.position = CGPoint(x: 0, y: 50)
            hudNode.addChild(failLabel)

            run(SKAction.sequence([
                SKAction.wait(forDuration: 2.0),
                SKAction.run { [weak self] in
                    guard let self = self else { return }
                    self.loadLevel(named: self.levelFiles[self.currentLevelIndex])
                    failLabel.removeFromParent()
                }
            ]))
        }
    }

    override public func update(_ currentTime: TimeInterval) {
        if let truck = activeTruck, truck.isLaunched {
            // Camera follow
            let targetX = -truck.position.x
            let targetY = -truck.position.y * 0.4
            worldNode.position.x += (targetX - worldNode.position.x) * 0.08
            worldNode.position.y += (targetY - worldNode.position.y) * 0.08
        } else {
            // Idle camera on launcher
            let targetX = -launcherPosition.x - 150
            worldNode.position.x += (targetX - worldNode.position.x) * 0.05
            worldNode.position.y += (-worldNode.position.y) * 0.05
        }
    }
}
