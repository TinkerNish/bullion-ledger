import Foundation

/// Whether a price alert is watching for a buying opportunity (price drops to
/// or below target) or a selling opportunity (price rises to or above target).
enum AlertDirection: String, CaseIterable, Identifiable, Codable {
    case buy
    case sell

    var id: String { rawValue }

    var label: String {
        switch self {
        case .buy: return "Buy"
        case .sell: return "Sell"
        }
    }

    var symbolName: String {
        switch self {
        case .buy: return "arrow.down.circle.fill"
        case .sell: return "arrow.up.circle.fill"
        }
    }

    var helpText: String {
        switch self {
        case .buy: return "Notify me when the price drops to or below my target."
        case .sell: return "Notify me when the price rises to or above my target."
        }
    }

    /// Whether the current spot price satisfies this alert's target.
    func isSatisfied(currentPrice: Double, targetPrice: Double) -> Bool {
        switch self {
        case .buy: return currentPrice <= targetPrice
        case .sell: return currentPrice >= targetPrice
        }
    }
}
