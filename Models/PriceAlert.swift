import Foundation

/// A user-configured buy or sell price target for a metal. When the live spot
/// price crosses `targetPrice` in the direction of `direction`, a local
/// notification is fired and the alert disables itself so it doesn't repeat.
struct PriceAlert: Identifiable, Codable, Equatable {
    var id: UUID
    var metal: Metal
    var direction: AlertDirection
    var targetPrice: Double
    var isEnabled: Bool
    var createdAt: Date
    var lastTriggeredAt: Date?

    init(
        id: UUID = UUID(),
        metal: Metal,
        direction: AlertDirection,
        targetPrice: Double,
        isEnabled: Bool = true,
        createdAt: Date = Date(),
        lastTriggeredAt: Date? = nil
    ) {
        self.id = id
        self.metal = metal
        self.direction = direction
        self.targetPrice = targetPrice
        self.isEnabled = isEnabled
        self.createdAt = createdAt
        self.lastTriggeredAt = lastTriggeredAt
    }

    var summary: String {
        "\(direction.label) \(metal.label) at \(Formatters.currencyString(targetPrice))/oz"
    }
}
