import Foundation

/// A single precious-metal purchase ("lot"). Weight is always stored internally in troy
/// ounces; `displayUnit` just remembers what unit you originally entered it in.
struct GoldLot: Identifiable, Codable, Equatable {
    var id: UUID
    var date: Date
    var weightOz: Double
    var totalCostPaid: Double
    var displayUnit: WeightUnit
    var metal: Metal
    var notes: String

    init(
        id: UUID = UUID(),
        date: Date,
        weightOz: Double,
        totalCostPaid: Double,
        displayUnit: WeightUnit = .troyOunce,
        metal: Metal = .gold,
        notes: String = ""
    ) {
        self.id = id
        self.date = date
        self.weightOz = weightOz
        self.totalCostPaid = totalCostPaid
        self.displayUnit = displayUnit
        self.metal = metal
        self.notes = notes
    }

    var pricePaidPerOz: Double {
        weightOz > 0 ? totalCostPaid / weightOz : 0
    }

    func currentValue(atSpotPerOz spot: Double) -> Double {
        weightOz * spot
    }

    func gainLoss(atSpotPerOz spot: Double) -> Double {
        currentValue(atSpotPerOz: spot) - totalCostPaid
    }

    func gainLossPercent(atSpotPerOz spot: Double) -> Double {
        totalCostPaid > 0 ? (gainLoss(atSpotPerOz: spot) / totalCostPaid) * 100 : 0
    }

    // Custom decoding so existing saved data (from before silver support was added,
    // which has no "metal" key) loads fine and defaults to .gold.
    enum CodingKeys: String, CodingKey {
        case id, date, weightOz, totalCostPaid, displayUnit, metal, notes
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        date = try c.decode(Date.self, forKey: .date)
        weightOz = try c.decode(Double.self, forKey: .weightOz)
        totalCostPaid = try c.decode(Double.self, forKey: .totalCostPaid)
        displayUnit = try c.decodeIfPresent(WeightUnit.self, forKey: .displayUnit) ?? .troyOunce
        metal = try c.decodeIfPresent(Metal.self, forKey: .metal) ?? .gold
        notes = try c.decodeIfPresent(String.self, forKey: .notes) ?? ""
    }
}
