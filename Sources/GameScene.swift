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
    private var launcherPosition = CGPoint(x: -770, y: -140)
    private var isDraggingSlingshot = false
    private var isPanningCamera = false
    private var panStartPoint = CGPoint.zero
    private var worldStartPos = CGPoint.zero
    private var dragStart = CGPoint.zero
    private var dragCurrent = CGPoint.zero

    private var slingshotLineL: SKShapeNode?
    private var slingshotLineR: SKShapeNode?
    private var aimGuideRing: SKShapeNode?
    private var trajectoryDots: [SKShapeNode] = []
    private var worldNode = SKNode()
    private var hudNode = SKNode()
    private var bgNode: SKSpriteNode?

    private var score = 0
    private var scoreLabel = SKLabelNode(fontNamed: "HelveticaNeue-Black")
    private var skullsLeftLabel = SKLabelNode(fontNamed: "HelveticaNeue-Black")
    private var levelNameLabel = SKLabelNode(fontNamed: "HelveticaNeue-Bold")
    private var trucksLeftLabel = SKLabelNode(fontNamed: "HelveticaNeue-Bold")
    private var remainingSkullsCount = 0

    // Zoom level scale to display both launcher and targets simultaneously
    private let fieldScale: CGFloat = 0.65

    override public func didMove(to view: SKView) {
        self.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        self.backgroundColor = SKColor(red: 0.12, green: 0.08, blue: 0.08, alpha: 1.0)
        
        physicsWorld.gravity = CGVector(dx: 0.0, dy: -9.8 * 60.0)
        physicsWorld.contactDelegate = self

        // Background
        if let bgTex = loadTexture(named: "Episode03BG.png") ?? loadTexture(named: "Episode01BG.png") {
            let bg = SKSpriteNode(texture: bgTex)
            bg.size = CGSize(width: size.width * 1.8, height: size.height * 1.3)
            bg.zPosition = -100
            addChild(bg)
            self.bgNode = bg
        }

        worldNode.setScale(fieldScale)
        addChild(worldNode)
        addChild(hudNode)

        setupHUD()
        loadLevelList()

        let startLevelName = levelFiles.indices.contains(currentLevelIndex) ? levelFiles[currentLevelIndex] : "Outpost"
        loadLevel(named: startLevelName)

        AudioManager.shared.playMusic()
    }

    private func setupHUD() {
        scoreLabel.fontSize = 24
        scoreLabel.fontColor = .yellow
        scoreLabel.horizontalAlignmentMode = .left
        scoreLabel.position = CGPoint(x: -size.width / 2 + 40, y: size.height / 2 - 45)
        scoreLabel.text = "SCORE: 0"
        scoreLabel.zPosition = 100
        hudNode.addChild(scoreLabel)

        levelNameLabel.fontSize = 20
        levelNameLabel.fontColor = .white
        levelNameLabel.horizontalAlignmentMode = .center
        levelNameLabel.position = CGPoint(x: 0, y: size.height / 2 - 45)
        levelNameLabel.text = "LEVEL: OUTPOST"
        levelNameLabel.zPosition = 100
        hudNode.addChild(levelNameLabel)

        skullsLeftLabel.fontSize = 24
        skullsLeftLabel.fontColor = SKColor(red: 1.0, green: 0.35, blue: 0.35, alpha: 1.0)
        skullsLeftLabel.horizontalAlignmentMode = .right
        skullsLeftLabel.position = CGPoint(x: size.width / 2 - 40, y: size.height / 2 - 45)
        skullsLeftLabel.text = "SKULLS: 0"
        skullsLeftLabel.zPosition = 100
        hudNode.addChild(skullsLeftLabel)

        trucksLeftLabel.fontSize = 18
        trucksLeftLabel.fontColor = SKColor(white: 0.85, alpha: 1.0)
        trucksLeftLabel.horizontalAlignmentMode = .left
        trucksLeftLabel.position = CGPoint(x: -size.width / 2 + 40, y: size.height / 2 - 80)
        trucksLeftLabel.text = "TRUCKS: 3"
        trucksLeftLabel.zPosition = 100
        hudNode.addChild(trucksLeftLabel)

        // Retry button
        let restartBtn = SKShapeNode(rectOf: CGSize(width: 95, height: 38), cornerRadius: 8)
        restartBtn.fillColor = SKColor(white: 0.2, alpha: 0.85)
        restartBtn.strokeColor = .yellow
        restartBtn.lineWidth = 2.5
        restartBtn.position = CGPoint(x: size.width / 2 - 70, y: -size.height / 2 + 45)
        restartBtn.name = "RestartButton"
        restartBtn.zPosition = 100
        let restartLbl = SKLabelNode(fontNamed: "HelveticaNeue-Bold")
        restartLbl.text = "RETRY"
        restartLbl.fontSize = 16
        restartLbl.verticalAlignmentMode = .center
        restartLbl.name = "RestartButton"
        restartBtn.addChild(restartLbl)
        hudNode.addChild(restartBtn)

        // Slingshot elastic bands
        slingshotLineL = SKShapeNode()
        slingshotLineL?.strokeColor = SKColor(red: 0.95, green: 0.7, blue: 0.15, alpha: 1.0)
        slingshotLineL?.lineWidth = 7
        slingshotLineL?.zPosition = 25
        worldNode.addChild(slingshotLineL!)

        slingshotLineR = SKShapeNode()
        slingshotLineR?.strokeColor = SKColor(red: 0.85, green: 0.6, blue: 0.1, alpha: 1.0)
        slingshotLineR?.lineWidth = 7
        slingshotLineR?.zPosition = 38
        worldNode.addChild(slingshotLineR!)

        // Aim guide ring
        aimGuideRing = SKShapeNode(circleOfRadius: 50)
        aimGuideRing?.strokeColor = .yellow
        aimGuideRing?.lineWidth = 3
        aimGuideRing?.fillColor = SKColor(red: 1.0, green: 0.9, blue: 0.2, alpha: 0.2)
        aimGuideRing?.zPosition = 28
        worldNode.addChild(aimGuideRing!)

        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.15, duration: 0.7),
            SKAction.scale(to: 0.92, duration: 0.7)
        ])
        aimGuideRing?.run(SKAction.repeatForever(pulse))

        // Trajectory dots
        for _ in 0..<22 {
            let dot = SKShapeNode(circleOfRadius: 6)
            dot.fillColor = .yellow
            dot.strokeColor = .white
            dot.lineWidth = 1.5
            dot.alpha = 0.85
            dot.isHidden = true
            dot.zPosition = 50
            worldNode.addChild(dot)
            trajectoryDots.append(dot)
        }
    }

    private func loadLevelList() {
        if let data = findResourceData(named: "episodes", ext: "json"),
           let episodes = try? JSONDecoder().decode([EpisodeData].self, from: data) {
            var allLevels: [String] = []
            for ep in episodes {
                allLevels.append(contentsOf: ep.levels)
            }
            if !allLevels.isEmpty {
                self.levelFiles = allLevels
                return
            }
        }

        self.levelFiles = [
            "Outpost", "Castle Walls", "Stilt House Party", "Fortress Of Bang",
            "Drawbridge", "Throwing Stones", "Slow Ride", "Graveyard", "Block Buster",
            "Ambush", "Arachnoid", "Bang Through", "Bank Heist", "Face Off"
        ]
    }

    private func findResourceData(named name: String, ext: String) -> Data? {
        let clean = name.replacingOccurrences(of: ".\(ext)", with: "")
        if let url = Bundle.main.url(forResource: clean, withExtension: ext) { return try? Data(contentsOf: url) }
        for sub in ["Levels", "Resources", "Resources/Levels", "Resources/Episodes"] {
            if let url = Bundle.main.url(forResource: clean, withExtension: ext, subdirectory: sub) {
                return try? Data(contentsOf: url)
            }
        }
        if let urls = Bundle.main.urls(forResourcesWithExtension: ext, subdirectory: nil) {
            if let match = urls.first(where: { $0.deletingPathExtension().lastPathComponent == clean }) {
                return try? Data(contentsOf: match)
            }
        }
        return nil
    }

    public func loadLevel(named levelName: String) {
        worldNode.removeAllChildren()
        worldNode.addChild(slingshotLineL!)
        worldNode.addChild(slingshotLineR!)
        worldNode.addChild(aimGuideRing!)
        for dot in trajectoryDots { worldNode.addChild(dot) }

        var level: LevelData?
        if let data = findResourceData(named: levelName, ext: "json") {
            level = try? JSONDecoder().decode(LevelData.self, from: data)
        }
        if level == nil {
            level = makeFallbackLevel(named: levelName)
        }

        guard let current = level else { return }
        self.currentLevel = current
        self.remainingSkullsCount = 0

        levelNameLabel.text = "LEVEL: \(levelName.uppercased())"

        if let lx = current.launcherX, let ly = current.launcherY {
            launcherPosition = CGPoint(x: lx, y: ly)
        } else {
            launcherPosition = CGPoint(x: -770, y: -140)
        }
        aimGuideRing?.position = launcherPosition

        // 1. Build Ground
        let groundW: CGFloat = 3800.0
        let groundH: CGFloat = 160.0
        let ground = SKSpriteNode(color: SKColor(red: 0.22, green: 0.12, blue: 0.08, alpha: 1.0),
                                  size: CGSize(width: groundW, height: groundH))
        ground.position = CGPoint(x: 0, y: -380)
        ground.physicsBody = SKPhysicsBody(rectangleOf: ground.size)
        ground.physicsBody?.isDynamic = false
        ground.physicsBody?.friction = 0.95
        ground.physicsBody?.categoryBitMask = PhysicsCategory.ground
        ground.physicsBody?.collisionBitMask = PhysicsCategory.all
        ground.zPosition = 5
        worldNode.addChild(ground)

        let grass = SKSpriteNode(color: SKColor(red: 0.35, green: 0.55, blue: 0.2, alpha: 1.0),
                                 size: CGSize(width: groundW, height: 14))
        grass.position = CGPoint(x: 0, y: -380 + groundH / 2 - 7)
        grass.zPosition = 6
        worldNode.addChild(grass)

        // 2. Build Slingshot posts
        buildSlingshot(at: launcherPosition)

        // 3. Spawn Level Parts
        for part in current.parts {
            spawnPart(part)
        }

        // 4. Setup Trucks
        truckQueue.removeAll()
        if let projs = current.projectiles, !projs.isEmpty {
            for p in projs {
                truckQueue.append(TruckType(rawValue: p) ?? .bus)
            }
        } else {
            truckQueue = [.crotchRocket, .bus, .bomber, .doomstone]
        }

        updateTruckQueueHUD()
        skullsLeftLabel.text = "SKULLS: \(remainingSkullsCount)"
        prepareNextTruck()

        // Center camera so both launcher and target castle are balanced on screen
        worldNode.position = CGPoint(x: -80, y: 40)
    }

    private func buildSlingshot(at pos: CGPoint) {
        let base = SKShapeNode(rectOf: CGSize(width: 24, height: 110), cornerRadius: 5)
        base.fillColor = SKColor(red: 0.35, green: 0.2, blue: 0.1, alpha: 1.0)
        base.strokeColor = .black
        base.lineWidth = 2.5
        base.position = CGPoint(x: pos.x, y: pos.y - 70)
        base.zPosition = 20
        worldNode.addChild(base)

        let postLeft = SKShapeNode(rectOf: CGSize(width: 16, height: 80), cornerRadius: 4)
        postLeft.fillColor = SKColor(red: 0.45, green: 0.25, blue: 0.12, alpha: 1.0)
        postLeft.strokeColor = .black
        postLeft.lineWidth = 2.5
        postLeft.position = CGPoint(x: pos.x - 24, y: pos.y - 10)
        postLeft.zRotation = -0.25
        postLeft.zPosition = 20
        worldNode.addChild(postLeft)

        let postRight = SKShapeNode(rectOf: CGSize(width: 16, height: 80), cornerRadius: 4)
        postRight.fillColor = SKColor(red: 0.5, green: 0.3, blue: 0.15, alpha: 1.0)
        postRight.strokeColor = .black
        postRight.lineWidth = 2.5
        postRight.position = CGPoint(x: pos.x + 24, y: pos.y - 10)
        postRight.zRotation = 0.25
        postRight.zPosition = 20
        worldNode.addChild(postRight)
    }

    private func spawnPart(_ part: PartData) {
        let isSkull = part.name.contains("Skull")
        let isCircle = part.name.contains("Circle")
        let isGround = part.name.contains("GroundBox") || part.name.contains("Indestructium") || part.name.contains("Bedrock") || part.name.contains("Anchor")
        let isExplosive = part.name.contains("Boiler") || part.name.contains("Dynamite") || part.name.contains("Barrel")

        let size = determineSize(part.name)
        let color = determineColor(part.name)

        let node: SKNode
        if isSkull {
            let skullNode = SKNode()
            let skullBase = SKShapeNode(circleOfRadius: size.width / 2)
            skullBase.fillColor = .white
            skullBase.strokeColor = .black
            skullBase.lineWidth = 2.5
            skullNode.addChild(skullBase)

            // Red glowing target ring
            let targetRing = SKShapeNode(circleOfRadius: size.width / 2 + 8)
            targetRing.strokeColor = SKColor(red: 1.0, green: 0.2, blue: 0.2, alpha: 0.7)
            targetRing.lineWidth = 2
            skullNode.addChild(targetRing)

            let eyeL = SKShapeNode(circleOfRadius: 4.5)
            eyeL.fillColor = .black
            eyeL.position = CGPoint(x: -7, y: 3)
            skullNode.addChild(eyeL)

            let eyeR = SKShapeNode(circleOfRadius: 4.5)
            eyeR.fillColor = .black
            eyeR.position = CGPoint(x: 7, y: 3)
            skullNode.addChild(eyeR)

            let teeth = SKShapeNode(rectOf: CGSize(width: 14, height: 6))
            teeth.fillColor = .black
            teeth.position = CGPoint(x: 0, y: -9)
            skullNode.addChild(teeth)

            node = skullNode
        } else {
            let shape = SKShapeNode(rectOf: size, cornerRadius: 2)
            shape.fillColor = color
            shape.strokeColor = SKColor(white: 0.1, alpha: 0.85)
            shape.lineWidth = 1.5
            node = shape
        }

        node.position = CGPoint(x: part.x, y: part.y)
        node.zRotation = part.angle * (.pi / 180.0)
        node.name = part.name
        node.zPosition = isSkull ? 16 : 10

        if isCircle || isSkull {
            node.physicsBody = SKPhysicsBody(circleOfRadius: size.width / 2)
        } else {
            node.physicsBody = SKPhysicsBody(rectangleOf: size)
        }

        if isGround {
            node.physicsBody?.isDynamic = false
            node.physicsBody?.categoryBitMask = PhysicsCategory.ground
        } else {
            node.physicsBody?.isDynamic = true
            node.physicsBody?.friction = 0.95
            node.physicsBody?.restitution = 0.05
            node.physicsBody?.linearDamping = 1.5
            node.physicsBody?.angularDamping = 1.8
            node.physicsBody?.isResting = true

            if isSkull {
                node.physicsBody?.mass = 1.0
                node.physicsBody?.categoryBitMask = PhysicsCategory.skull
                remainingSkullsCount += 1
            } else if isExplosive {
                node.physicsBody?.mass = 1.2
                node.physicsBody?.categoryBitMask = PhysicsCategory.explosive
            } else {
                node.physicsBody?.mass = 1.8
                node.physicsBody?.categoryBitMask = PhysicsCategory.structure
            }
        }

        node.physicsBody?.collisionBitMask = PhysicsCategory.all
        node.physicsBody?.contactTestBitMask = PhysicsCategory.truck | PhysicsCategory.ground | PhysicsCategory.explosive

        worldNode.addChild(node)
    }

    private func determineSize(_ name: String) -> CGSize {
        if name.contains("GroundBox") { return CGSize(width: 2034, height: 100) }
        if name.contains("HugeSquare") { return CGSize(width: 130, height: 130) }
        if name.contains("LargeSquare") { return CGSize(width: 85, height: 85) }
        if name.contains("MediumSquare") { return CGSize(width: 52, height: 52) }
        if name.contains("SmallSquare") { return CGSize(width: 32, height: 32) }
        if name.contains("VeryLongBeam") { return CGSize(width: 210, height: 24) }
        if name.contains("LongBeam") { return CGSize(width: 150, height: 24) }
        if name.contains("LargeBeam") { return CGSize(width: 105, height: 24) }
        if name.contains("MediumBeam") { return CGSize(width: 72, height: 24) }
        if name.contains("SmallBeam") { return CGSize(width: 44, height: 24) }
        if name.contains("LargeCircle") { return CGSize(width: 80, height: 80) }
        if name.contains("MediumCircle") { return CGSize(width: 55, height: 55) }
        if name.contains("SmallCircle") { return CGSize(width: 32, height: 32) }
        if name.contains("Skull") { return CGSize(width: 48, height: 48) }
        if name.contains("Boiler") || name.contains("Barrel") { return CGSize(width: 46, height: 64) }
        return CGSize(width: 50, height: 50)
    }

    private func determineColor(_ name: String) -> SKColor {
        if name.contains("Skull") { return .white }
        if name.contains("Wood") { return SKColor(red: 0.76, green: 0.52, blue: 0.32, alpha: 1.0) }
        if name.contains("Glass") { return SKColor(red: 0.45, green: 0.85, blue: 0.95, alpha: 0.75) }
        if name.contains("Stone") { return SKColor(red: 0.62, green: 0.62, blue: 0.66, alpha: 1.0) }
        if name.contains("Steel") { return SKColor(red: 0.38, green: 0.42, blue: 0.52, alpha: 1.0) }
        if name.contains("Rubber") { return SKColor(red: 0.95, green: 0.75, blue: 0.15, alpha: 1.0) }
        if name.contains("Lava") { return SKColor(red: 0.95, green: 0.25, blue: 0.05, alpha: 1.0) }
        if name.contains("Indestructium") { return SKColor(red: 0.3, green: 0.3, blue: 0.35, alpha: 1.0) }
        if name.contains("Explosive") || name.contains("Boiler") || name.contains("Dynamite") {
            return SKColor(red: 0.95, green: 0.15, blue: 0.1, alpha: 1.0)
        }
        return SKColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0)
    }

    private func updateTruckQueueHUD() {
        let count = truckQueue.count + (activeTruck != nil && !activeTruck!.isLaunched ? 1 : 0)
        trucksLeftLabel.text = "TRUCKS: \(count)"
    }

    private func prepareNextTruck() {
        guard !truckQueue.isEmpty else {
            checkGameOver()
            return
        }

        let type = truckQueue.removeFirst()
        let truck = TruckNode(type: type)
        truck.position = launcherPosition
        truck.zPosition = 35
        worldNode.addChild(truck)
        activeTruck = truck
        aimGuideRing?.isHidden = false
        updateTruckQueueHUD()
        updateSlingshotLines(truckPos: launcherPosition)
    }

    private func updateSlingshotLines(truckPos: CGPoint) {
        let prongL = CGPoint(x: launcherPosition.x - 24, y: launcherPosition.y + 15)
        let prongR = CGPoint(x: launcherPosition.x + 24, y: launcherPosition.y + 15)

        let pathL = CGMutablePath()
        pathL.move(to: prongL)
        pathL.addLine(to: CGPoint(x: truckPos.x - 25, y: truckPos.y))
        slingshotLineL?.path = pathL

        let pathR = CGMutablePath()
        pathR.move(to: prongR)
        pathR.addLine(to: CGPoint(x: truckPos.x + 25, y: truckPos.y))
        slingshotLineR?.path = pathR
    }

    override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }

        let hudLoc = touch.location(in: hudNode)
        for node in hudNode.nodes(at: hudLoc) {
            if node.name == "RestartButton" || node.parent?.name == "RestartButton" {
                AudioManager.shared.triggerHaptic(style: .medium)
                let name = levelFiles.indices.contains(currentLevelIndex) ? levelFiles[currentLevelIndex] : "Outpost"
                loadLevel(named: name)
                return
            }
        }

        let location = touch.location(in: worldNode)

        // Mid-air ability tap
        if let truck = activeTruck, truck.isLaunched {
            truck.activateAbility()
            return
        }

        // Check if touching slingshot/launcher
        let dist = hypot(location.x - launcherPosition.x, location.y - launcherPosition.y)
        if dist < 250 || (location.x < launcherPosition.x + 120 && abs(location.y - launcherPosition.y) < 220) {
            isDraggingSlingshot = true
            dragStart = launcherPosition
            dragCurrent = location
            aimGuideRing?.isHidden = true
            updateSlingshotAim()
        } else {
            // Touch anywhere else pans the camera
            isPanningCamera = true
            panStartPoint = touch.location(in: self)
            worldStartPos = worldNode.position
        }
    }

    override public func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }

        if isDraggingSlingshot {
            dragCurrent = touch.location(in: worldNode)
            updateSlingshotAim()
        } else if isPanningCamera {
            let current = touch.location(in: self)
            let dx = current.x - panStartPoint.x
            worldNode.position.x = max(-500, min(300, worldStartPos.x + dx))
        }
    }

    override public func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isPanningCamera {
            isPanningCamera = false
            return
        }

        guard isDraggingSlingshot else { return }
        isDraggingSlingshot = false

        let dx = dragStart.x - dragCurrent.x
        let dy = dragStart.y - dragCurrent.y
        let pullDist = hypot(dx, dy)

        updateSlingshotLines(truckPos: launcherPosition)
        for dot in trajectoryDots { dot.isHidden = true }

        if pullDist > 20, let truck = activeTruck {
            let maxPull: CGFloat = 175.0
            let clampedDist = min(pullDist, maxPull)
            let ratio = clampedDist / pullDist

            // Direct powerful throw velocity
            let speedMult: CGFloat = 16.5
            let vx = dx * ratio * speedMult
            let vy = dy * ratio * speedMult

            truck.launch(withVelocity: CGVector(dx: vx, dy: vy))
            updateTruckQueueHUD()

            run(SKAction.sequence([
                SKAction.wait(forDuration: 5.5),
                SKAction.run { [weak self] in
                    self?.prepareNextTruck()
                }
            ]))
        } else if let truck = activeTruck, !truck.isLaunched {
            truck.position = launcherPosition
            aimGuideRing?.isHidden = false
        }
    }

    private func updateSlingshotAim() {
        let maxPull: CGFloat = 175.0
        let dx = dragCurrent.x - dragStart.x
        let dy = dragCurrent.y - dragStart.y
        let dist = hypot(dx, dy)

        var clampedPos = dragCurrent
        if dist > maxPull {
            clampedPos = CGPoint(x: dragStart.x + (dx / dist) * maxPull,
                                 y: dragStart.y + (dy / dist) * maxPull)
        }

        if let truck = activeTruck, !truck.isLaunched {
            truck.position = clampedPos
            truck.zRotation = atan2(-dy, -dx) * 0.4
        }

        updateSlingshotLines(truckPos: clampedPos)

        let pullX = dragStart.x - clampedPos.x
        let pullY = dragStart.y - clampedPos.y
        let speedMult: CGFloat = 16.5

        var simPos = clampedPos
        var simVel = CGVector(dx: pullX * speedMult, dy: pullY * speedMult)
        let gravity = CGVector(dx: 0, dy: -9.8 * 60.0)

        for dot in trajectoryDots {
            dot.position = simPos
            dot.isHidden = false
            simVel.dx += gravity.dx * 0.035
            simVel.dy += gravity.dy * 0.035
            simPos.x += simVel.dx * 0.035
            simPos.y += simVel.dy * 0.035
        }
    }

    public func didBegin(_ contact: SKPhysicsContact) {
        let maskA = contact.bodyA.categoryBitMask
        let maskB = contact.bodyB.categoryBitMask

        if contact.collisionImpulse > 25 {
            AudioManager.shared.triggerHaptic(style: .medium)
        }

        // Skull hit
        if maskA == PhysicsCategory.skull || maskB == PhysicsCategory.skull {
            let skullBody = maskA == PhysicsCategory.skull ? contact.bodyA : contact.bodyB
            if let node = skullBody.node {
                destroySkull(node)
            }
        }

        // Explosive hit
        if maskA == PhysicsCategory.explosive || maskB == PhysicsCategory.explosive {
            let expBody = maskA == PhysicsCategory.explosive ? contact.bodyA : contact.bodyB
            if let node = expBody.node {
                triggerExplosion(at: node.position)
                node.removeFromParent()
            }
        }

        // Material sound effects
        if maskA == PhysicsCategory.truck || maskB == PhysicsCategory.truck {
            let otherBody = maskA == PhysicsCategory.truck ? contact.bodyB : contact.bodyA
            if let name = otherBody.node?.name {
                if name.contains("Wood") { AudioManager.shared.playSFX(named: "Wood_Impact") }
                else if name.contains("Stone") { AudioManager.shared.playSFX(named: "Stone_Impact") }
                else if name.contains("Steel") { AudioManager.shared.playSFX(named: "Steel_Impact") }
                else if name.contains("Rubber") { AudioManager.shared.playSFX(named: "Rubber_Impact") }
            }
        }
    }

    private func destroySkull(_ node: SKNode) {
        let pos = node.position
        node.removeFromParent()
        score += 5000
        remainingSkullsCount = max(0, remainingSkullsCount - 1)
        scoreLabel.text = "SCORE: \(score)"
        skullsLeftLabel.text = "SKULLS: \(remainingSkullsCount)"

        AudioManager.shared.playSFX(named: "Skull_Destruction")
        AudioManager.shared.triggerHaptic(style: .heavy)

        for _ in 0..<12 {
            let bit = SKShapeNode(circleOfRadius: 4)
            bit.fillColor = .white
            bit.strokeColor = .gray
            bit.position = pos
            bit.physicsBody = SKPhysicsBody(circleOfRadius: 4)
            bit.physicsBody?.applyImpulse(CGVector(dx: CGFloat.random(in: -30...30), dy: CGFloat.random(in: 15...40)))
            worldNode.addChild(bit)
            bit.run(SKAction.sequence([SKAction.fadeOut(withDuration: 0.9), SKAction.removeFromParent()]))
        }

        if remainingSkullsCount <= 0 {
            triggerWin()
        }
    }

    private func triggerExplosion(at pos: CGPoint) {
        score += 1000
        AudioManager.shared.playSFX(named: "BonusBombExplosion2")
        AudioManager.shared.triggerHaptic(style: .heavy)

        let flash = SKShapeNode(circleOfRadius: 90)
        flash.position = pos
        flash.fillColor = .orange
        flash.strokeColor = .yellow
        flash.lineWidth = 3
        flash.alpha = 0.9
        flash.zPosition = 60
        worldNode.addChild(flash)

        flash.run(SKAction.sequence([
            SKAction.scale(to: 2.5, duration: 0.16),
            SKAction.fadeOut(withDuration: 0.25),
            SKAction.removeFromParent()
        ]))

        let explosionRadius: CGFloat = 240.0
        for child in worldNode.children {
            guard let pb = child.physicsBody, pb.isDynamic else { continue }
            let dist = hypot(child.position.x - pos.x, child.position.y - pos.y)
            if dist < explosionRadius && dist > 1.0 {
                let force = (1.0 - dist / explosionRadius) * 140.0
                let impulse = CGVector(dx: (child.position.x - pos.x) / dist * force,
                                       dy: (child.position.y - pos.y) / dist * force + 25)
                pb.applyImpulse(impulse)
            }
        }
    }

    private func triggerWin() {
        AudioManager.shared.playSFX(named: "Winner")
        AudioManager.shared.triggerWinHaptic()

        let banner = SKShapeNode(rectOf: CGSize(width: 520, height: 160), cornerRadius: 22)
        banner.fillColor = SKColor(red: 0.1, green: 0.5, blue: 0.12, alpha: 0.95)
        banner.strokeColor = .yellow
        banner.lineWidth = 4.5
        banner.position = CGPoint(x: 0, y: 30)
        banner.zPosition = 200

        let winLabel = SKLabelNode(fontNamed: "HelveticaNeue-Black")
        winLabel.text = "LEVEL COMPLETE!"
        winLabel.fontSize = 42
        winLabel.fontColor = .yellow
        winLabel.position = CGPoint(x: 0, y: 15)
        banner.addChild(winLabel)

        let nextLabel = SKLabelNode(fontNamed: "HelveticaNeue-Bold")
        nextLabel.text = "LOADING NEXT LEVEL..."
        nextLabel.fontSize = 20
        nextLabel.fontColor = .white
        nextLabel.position = CGPoint(x: 0, y: -35)
        banner.addChild(nextLabel)

        hudNode.addChild(banner)

        run(SKAction.sequence([
            SKAction.wait(forDuration: 2.8),
            SKAction.run { [weak self] in
                guard let self = self else { return }
                banner.removeFromParent()
                self.currentLevelIndex = (self.currentLevelIndex + 1) % max(1, self.levelFiles.count)
                let nextName = self.levelFiles[self.currentLevelIndex]
                self.loadLevel(named: nextName)
            }
        ]))
    }

    private func checkGameOver() {
        if remainingSkullsCount > 0 {
            let failLabel = SKLabelNode(fontNamed: "HelveticaNeue-Black")
            failLabel.text = "OUT OF TRUCKS!"
            failLabel.fontSize = 44
            failLabel.fontColor = .red
            failLabel.position = CGPoint(x: 0, y: 30)
            failLabel.zPosition = 200
            hudNode.addChild(failLabel)

            run(SKAction.sequence([
                SKAction.wait(forDuration: 2.2),
                SKAction.run { [weak self] in
                    guard let self = self else { return }
                    failLabel.removeFromParent()
                    let name = self.levelFiles.indices.contains(self.currentLevelIndex) ? self.levelFiles[self.currentLevelIndex] : "Outpost"
                    self.loadLevel(named: name)
                }
            ]))
        }
    }

    override public func update(_ currentTime: TimeInterval) {
        if let truck = activeTruck, truck.isLaunched {
            // Track truck in flight smoothly
            let targetX = -truck.position.x * fieldScale
            let targetY = -truck.position.y * fieldScale * 0.4
            worldNode.position.x += (targetX - worldNode.position.x) * 0.08
            worldNode.position.y += (targetY - worldNode.position.y) * 0.08
        } else if !isPanningCamera {
            // Balanced view of both launcher and targets
            let targetX: CGFloat = -80.0
            let targetY: CGFloat = 40.0
            worldNode.position.x += (targetX - worldNode.position.x) * 0.05
            worldNode.position.y += (targetY - worldNode.position.y) * 0.05
        }
    }

    private func loadTexture(named name: String) -> SKTexture? {
        if let image = UIImage(named: name) { return SKTexture(image: image) }
        if let path = Bundle.main.path(forResource: name, ofType: nil) { return SKTexture(imageNamed: path) }
        if let path = Bundle.main.path(forResource: name, ofType: nil, inDirectory: "Textures") { return SKTexture(imageNamed: path) }
        return nil
    }

    private func makeFallbackLevel(named name: String) -> LevelData {
        return LevelData(
            file: name,
            name: name,
            theme: "Theme_HellsHighway",
            width: 2034.0,
            height: 768.0,
            launcherX: -770.0,
            launcherY: -140.0,
            projectiles: ["Projectile_CrotchRocket", "Projectile_Bus", "Projectile_Bomber"],
            parts: [
                PartData(name: "StructurePart_IndestructiumHugeSquare", x: 450, y: -290, angle: 0, hinged: false),
                PartData(name: "StructurePart_WoodMediumBeam", x: 400, y: -200, angle: 90, hinged: false),
                PartData(name: "StructurePart_WoodMediumBeam", x: 500, y: -200, angle: 90, hinged: false),
                PartData(name: "StructurePart_WoodLongBeam", x: 450, y: -155, angle: 0, hinged: false),
                PartData(name: "StructurePart_WoodMediumBeam", x: 420, y: -110, angle: 90, hinged: false),
                PartData(name: "StructurePart_WoodMediumBeam", x: 480, y: -110, angle: 90, hinged: false),
                PartData(name: "StructurePart_WoodMediumBeam", x: 450, y: -65, angle: 0, hinged: false),
                PartData(name: "StructurePart_Skull", x: 450, y: -25, angle: 0, hinged: false),
                PartData(name: "StructurePart_Skull", x: 450, y: -200, angle: 0, hinged: false),
                PartData(name: "StructurePart_Boiler", x: 580, y: -200, angle: 0, hinged: false)
            ]
        )
    }
}
