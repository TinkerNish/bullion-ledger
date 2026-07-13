import Foundation

enum WeightUnit: String, CaseIterable, Identifiable, Codable {
    case troyOunce = "oz"
    case gram = "g"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .troyOunce: return "oz (troy)"
        case .gram: return "grams"
        }
    }

    static let gramsPerTroyOunce = 31.1034768

    /// Converts a value in this unit to troy ounces.
    func toTroyOunces(_ value: Double) -> Double {
        switch self {
        case .troyOunce: return value
        case .gram: return value / WeightUnit.gramsPerTroyOunce
        }
    }

    /// Converts a value in troy ounces to this unit.
    func fromTroyOunces(_ ounces: Double) -> Double {
        switch self {
        case .troyOunce: return ounces
        case .gram: return ounces * WeightUnit.gramsPerTroyOunce
        }
    }
}
