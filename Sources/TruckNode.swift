import SpriteKit

public enum TruckType: String {
    case bomber = "Projectile_Bomber"
    case bus = "Projectile_Bus"
    case crotchRocket = "Projectile_CrotchRocket"
    case dart = "Projectile_Dart"
    case doomstone = "Projectile_Doomstone"
    case mirv = "Projectile_MIRV"
}

public class TruckNode: SKNode {
    public let truckType: TruckType
    public var hasUsedAbility = false
    public var isLaunched = false
    public let truckSprite: SKSpriteNode

    public init(type: TruckType) {
        self.truckType = type

        var truckSize = CGSize(width: 90, height: 45)
        var textureName = "StoreItemTruckDefaultImageSm.png"
        var tintColor = SKColor.red

        switch type {
        case .bomber:
            truckSize = CGSize(width: 95, height: 48)
            textureName = "StoreItemTruckZombieImageSm.png"
            tintColor = SKColor(red: 0.9, green: 0.2, blue: 0.2, alpha: 1.0)
        case .bus:
            truckSize = CGSize(width: 110, height: 50)
            textureName = "StoreItemTruckHotrodImageSm.png"
            tintColor = SKColor(red: 0.95, green: 0.75, blue: 0.1, alpha: 1.0)
        case .crotchRocket:
            truckSize = CGSize(width: 80, height: 40)
            textureName = "StoreItemTruckBlingImageSm.png"
            tintColor = SKColor(red: 0.2, green: 0.85, blue: 0.3, alpha: 1.0)
        case .dart:
            truckSize = CGSize(width: 85, height: 42)
            textureName = "StoreItemTruckReptileImageSm.png"
            tintColor = SKColor(red: 0.2, green: 0.6, blue: 0.95, alpha: 1.0)
        case .doomstone:
            truckSize = CGSize(width: 105, height: 52)
            textureName = "StoreItemTruckGothImageSm.png"
            tintColor = SKColor(red: 0.5, green: 0.5, blue: 0.55, alpha: 1.0)
        case .mirv:
            truckSize = CGSize(width: 92, height: 46)
            textureName = "StoreItemTruckDefaultImageSm.png"
            tintColor = SKColor(red: 0.8, green: 0.3, blue: 0.95, alpha: 1.0)
        }

        // Texture or styled body
        let tex = TruckNode.loadTexture(named: textureName)
        if let t = tex {
            truckSprite = SKSpriteNode(texture: t, size: truckSize)
        } else {
            truckSprite = SKSpriteNode(color: tintColor, size: truckSize)
        }
        truckSprite.zPosition = 35

        super.init()
        self.name = "Truck"
        addChild(truckSprite)

        // Visual Wheels
        let wheelL = SKShapeNode(circleOfRadius: 10)
        wheelL.fillColor = .black
        wheelL.strokeColor = .gray
        wheelL.lineWidth = 2
        wheelL.position = CGPoint(x: -truckSize.width * 0.3, y: -truckSize.height * 0.4)
        wheelL.zPosition = 36
        addChild(wheelL)

        let wheelR = SKShapeNode(circleOfRadius: 10)
        wheelR.fillColor = .black
        wheelR.strokeColor = .gray
        wheelR.lineWidth = 2
        wheelR.position = CGPoint(x: truckSize.width * 0.3, y: -truckSize.height * 0.4)
        wheelR.zPosition = 36
        addChild(wheelR)

        // Glowing Headlight
        let light = SKShapeNode(circleOfRadius: 5)
        light.fillColor = .yellow
        light.strokeColor = .white
        light.position = CGPoint(x: truckSize.width * 0.48, y: -truckSize.height * 0.1)
        light.zPosition = 37
        addChild(light)

        setupPhysics(size: truckSize, massMultiplier: type == .doomstone ? 3.5 : 1.5)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private static func loadTexture(named name: String) -> SKTexture? {
        if let image = UIImage(named: name) { return SKTexture(image: image) }
        if let path = Bundle.main.path(forResource: name, ofType: nil) { return SKTexture(imageNamed: path) }
        if let path = Bundle.main.path(forResource: name, ofType: nil, inDirectory: "Textures") { return SKTexture(imageNamed: path) }
        return nil
    }

    private func setupPhysics(size: CGSize, massMultiplier: CGFloat) {
        self.physicsBody = SKPhysicsBody(rectangleOf: size)
        self.physicsBody?.isDynamic = false
        self.physicsBody?.allowsRotation = true
        self.physicsBody?.friction = 0.65
        self.physicsBody?.restitution = 0.25
        self.physicsBody?.mass = 2.0 * massMultiplier
        self.physicsBody?.categoryBitMask = PhysicsCategory.truck
        self.physicsBody?.contactTestBitMask = PhysicsCategory.structure | PhysicsCategory.skull | PhysicsCategory.ground | PhysicsCategory.explosive
        self.physicsBody?.collisionBitMask = PhysicsCategory.structure | PhysicsCategory.skull | PhysicsCategory.ground | PhysicsCategory.explosive
    }

    public func launch(withImpulse impulse: CGVector) {
        self.physicsBody?.isDynamic = true
        self.physicsBody?.applyImpulse(impulse)
        self.isLaunched = true

        AudioManager.shared.triggerHaptic(style: .heavy)

        switch truckType {
        case .bomber:
            AudioManager.shared.playSFX(named: "BrownBomber_Launch")
        case .bus:
            AudioManager.shared.playSFX(named: "CruelBus_Launch")
        default:
            AudioManager.shared.playSFX(named: "CrotchRocket_Launch")
        }
    }

    public func activateAbility() {
        guard isLaunched, !hasUsedAbility, let pb = self.physicsBody else { return }
        hasUsedAbility = true
        AudioManager.shared.triggerHaptic(style: .medium)

        switch truckType {
        case .bus:
            // Nitro Boost
            let currentVel = pb.velocity
            let boost = CGVector(dx: currentVel.dx * 1.9, dy: currentVel.dy * 1.4 + 120)
            pb.velocity = boost
            AudioManager.shared.playSFX(named: "Nitro")
            emitNitroFlames()

        case .bomber:
            // Drop Bomb
            guard let scene = self.scene else { return }
            let bomb = SKSpriteNode(color: .black, size: CGSize(width: 28, height: 28))
            bomb.position = CGPoint(x: self.position.x, y: self.position.y - 25)
            bomb.physicsBody = SKPhysicsBody(circleOfRadius: 14)
            bomb.physicsBody?.categoryBitMask = PhysicsCategory.truck
            bomb.physicsBody?.collisionBitMask = PhysicsCategory.structure | PhysicsCategory.ground | PhysicsCategory.skull
            bomb.physicsBody?.contactTestBitMask = PhysicsCategory.structure | PhysicsCategory.ground | PhysicsCategory.skull
            bomb.name = "Bomb"
            bomb.zPosition = 32
            scene.addChild(bomb)
            bomb.physicsBody?.applyImpulse(CGVector(dx: 0, dy: -40))
            AudioManager.shared.playSFX(named: "BrownBomber_TapEffect")

        case .mirv:
            // Split into 3
            guard let scene = self.scene else { return }
            for angleOffset in [-0.25, 0.25] {
                let sub = TruckNode(type: .crotchRocket)
                sub.position = self.position
                sub.hasUsedAbility = true
                sub.isLaunched = true
                scene.addChild(sub)
                sub.physicsBody?.isDynamic = true
                let v = pb.velocity
                let cosA = cos(angleOffset)
                let sinA = sin(angleOffset)
                let newVx = v.dx * CGFloat(cosA) - v.dy * CGFloat(sinA)
                let newVy = v.dx * CGFloat(sinA) + v.dy * CGFloat(cosA)
                sub.physicsBody?.velocity = CGVector(dx: newVx, dy: newVy)
            }
            AudioManager.shared.playSFX(named: "CrotchRocket_TapEffect")

        case .crotchRocket:
            pb.velocity = CGVector(dx: pb.velocity.dx * 2.1, dy: pb.velocity.dy * 1.3)
            AudioManager.shared.playSFX(named: "Nitro")
            emitNitroFlames()

        default:
            break
        }
    }

    private func emitNitroFlames() {
        let flame = SKShapeNode(ellipseOf: CGSize(width: 40, height: 16))
        flame.fillColor = .orange
        flame.strokeColor = .yellow
        flame.position = CGPoint(x: -50, y: 0)
        flame.zPosition = 34
        addChild(flame)
        flame.run(SKAction.sequence([
            SKAction.scale(to: 1.8, duration: 0.1),
            SKAction.fadeOut(withDuration: 0.2),
            SKAction.removeFromParent()
        ]))
    }
}
