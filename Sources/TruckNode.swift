import SpriteKit

public enum TruckType: String {
    case bomber = "Projectile_Bomber"
    case bus = "Projectile_Bus"
    case crotchRocket = "Projectile_CrotchRocket"
    case dart = "Projectile_Dart"
    case doomstone = "Projectile_Doomstone"
    case mirv = "Projectile_MIRV"
}

public class TruckNode: SKSpriteNode {
    public let truckType: TruckType
    public var hasUsedAbility = false
    public var isLaunched = false

    public init(type: TruckType) {
        self.truckType = type
        var color = SKColor.red
        var size = CGSize(width: 50, height: 26)

        switch type {
        case .bomber:
            color = SKColor(red: 0.85, green: 0.2, blue: 0.2, alpha: 1.0)
            size = CGSize(width: 56, height: 28)
        case .bus:
            color = SKColor(red: 0.95, green: 0.8, blue: 0.1, alpha: 1.0)
            size = CGSize(width: 72, height: 28)
        case .crotchRocket:
            color = SKColor(red: 0.2, green: 0.85, blue: 0.3, alpha: 1.0)
            size = CGSize(width: 40, height: 20)
        case .dart:
            color = SKColor(red: 0.2, green: 0.5, blue: 0.95, alpha: 1.0)
            size = CGSize(width: 50, height: 22)
        case .doomstone:
            color = SKColor(red: 0.4, green: 0.4, blue: 0.45, alpha: 1.0)
            size = CGSize(width: 60, height: 32)
        case .mirv:
            color = SKColor(red: 0.7, green: 0.3, blue: 0.9, alpha: 1.0)
            size = CGSize(width: 52, height: 26)
        }

        super.init(texture: nil, color: color, size: size)
        self.name = "Truck"
        setupPhysics(massMultiplier: type == .doomstone ? 3.0 : 1.0)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupPhysics(massMultiplier: CGFloat) {
        self.physicsBody = SKPhysicsBody(rectangleOf: self.size)
        self.physicsBody?.isDynamic = false
        self.physicsBody?.allowsRotation = true
        self.physicsBody?.friction = 0.5
        self.physicsBody?.restitution = 0.2
        self.physicsBody?.mass = 1.5 * massMultiplier
        self.physicsBody?.categoryBitMask = PhysicsCategory.truck
        self.physicsBody?.contactTestBitMask = PhysicsCategory.structure | PhysicsCategory.skull | PhysicsCategory.ground
        self.physicsBody?.collisionBitMask = PhysicsCategory.structure | PhysicsCategory.skull | PhysicsCategory.ground
    }

    public func launch(withImpulse impulse: CGVector) {
        self.physicsBody?.isDynamic = true
        self.physicsBody?.applyImpulse(impulse)
        self.isLaunched = true
    }

    public func activateAbility() {
        guard isLaunched, !hasUsedAbility, let pb = self.physicsBody else { return }
        hasUsedAbility = true

        switch truckType {
        case .bus:
            // Nitro Boost
            let currentVel = pb.velocity
            let boost = CGVector(dx: currentVel.dx * 1.8, dy: currentVel.dy * 1.5 + 100)
            pb.velocity = boost
            flashEffect(color: .orange)

        case .bomber:
            // Drop Bomb
            guard let scene = self.scene else { return }
            let bomb = SKSpriteNode(color: .black, size: CGSize(width: 24, height: 24))
            bomb.position = CGPoint(x: self.position.x, y: self.position.y - 20)
            bomb.physicsBody = SKPhysicsBody(circleOfRadius: 12)
            bomb.physicsBody?.categoryBitMask = PhysicsCategory.truck
            bomb.physicsBody?.collisionBitMask = PhysicsCategory.structure | PhysicsCategory.ground | PhysicsCategory.skull
            bomb.physicsBody?.contactTestBitMask = PhysicsCategory.structure | PhysicsCategory.ground | PhysicsCategory.skull
            bomb.name = "Bomb"
            scene.addChild(bomb)
            bomb.physicsBody?.applyImpulse(CGVector(dx: 0, dy: -30))

        case .mirv:
            // Split into 3
            guard let scene = self.scene else { return }
            for angleOffset in [-0.3, 0.3] {
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
            flashEffect(color: .purple)

        case .crotchRocket:
            // Turbo dart
            pb.velocity = CGVector(dx: pb.velocity.dx * 2.2, dy: pb.velocity.dy * 1.2)
            flashEffect(color: .green)

        default:
            break
        }
    }

    private func flashEffect(color: SKColor) {
        let flash = SKAction.sequence([
            SKAction.colorize(with: color, colorBlendFactor: 1.0, duration: 0.08),
            SKAction.colorize(withColorBlendFactor: 0.0, duration: 0.15)
        ])
        run(flash)
    }
}
