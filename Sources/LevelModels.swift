import Foundation
import CoreGraphics

public struct PartData: Codable {
    public let name: String
    public let x: CGFloat
    public let y: CGFloat
    public let angle: CGFloat
    public let hinged: Bool?
}

public struct LevelData: Codable {
    public let file: String?
    public let name: String?
    public let theme: String?
    public let width: CGFloat?
    public let height: CGFloat?
    public let launcherX: CGFloat?
    public let launcherY: CGFloat?
    public let projectiles: [String]?
    public let parts: [PartData]
}

public struct EpisodeData: Codable {
    public let id: String
    public let title: String
    public let levels: [String]
}
