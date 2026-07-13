import Foundation

/// Which precious metal a lot is made of.
enum Metal: String, CaseIterable, Identifiable, Codable {
    case gold
    case silver

    var id: String { rawValue }

    var label: String {
        switch self {
        case .gold: return "Gold"
        case .silver: return "Silver"
        }
    }

    /// Ticker symbol used by the spot price API.
    var symbol: String {
        switch self {
        case .gold: return "XAU"
        case .silver: return "XAG"
        }
    }
}
