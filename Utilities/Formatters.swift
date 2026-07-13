import Foundation

enum Formatters {
    static let currency: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "USD"
        return f
    }()

    static let weight: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = 2
        f.maximumFractionDigits = 4
        return f
    }()

    static let percent: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = 1
        f.maximumFractionDigits = 2
        return f
    }()

    static func currencyString(_ value: Double) -> String {
        currency.string(from: NSNumber(value: value)) ?? "$0.00"
    }

    static func weightString(_ value: Double, unit: WeightUnit) -> String {
        let s = weight.string(from: NSNumber(value: value)) ?? "0"
        return "\(s) \(unit.rawValue)"
    }

    static func percentString(_ value: Double) -> String {
        let s = percent.string(from: NSNumber(value: value)) ?? "0"
        return "\(value >= 0 ? "+" : "")\(s)%"
    }

    /// Plain decimal string (no symbol/grouping) suitable for pre-filling an editable text field.
    static func rawNumberString(_ value: Double) -> String {
        if value == value.rounded() && abs(value) < 1e15 {
            return String(Int(value))
        }
        var s = String(format: "%.4f", value)
        while s.hasSuffix("0") { s.removeLast() }
        if s.hasSuffix(".") { s.removeLast() }
        return s
    }
}
