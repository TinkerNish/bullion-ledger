import SwiftUI

struct SummaryCardView: View {
    let lots: [GoldLot]
    /// Spot price (USD/oz) for a given metal.
    let spotProvider: (Metal) -> Double

    private func lots(for metal: Metal) -> [GoldLot] { lots.filter { $0.metal == metal } }

    var totalCost: Double { lots.reduce(0) { $0 + $1.totalCostPaid } }
    var currentValue: Double {
        lots.reduce(0) { $0 + $1.currentValue(atSpotPerOz: spotProvider($1.metal)) }
    }
    var gainLoss: Double { currentValue - totalCost }
    var gainLossPercent: Double { totalCost > 0 ? (gainLoss / totalCost) * 100 : 0 }

    private var goldOz: Double { lots(for: .gold).reduce(0) { $0 + $1.weightOz } }
    private var silverOz: Double { lots(for: .silver).reduce(0) { $0 + $1.weightOz } }

    private var weightSummary: String {
        let parts = [
            goldOz > 0 ? "\(Formatters.weightString(goldOz, unit: .troyOunce)) gold" : nil,
            silverOz > 0 ? "\(Formatters.weightString(silverOz, unit: .troyOunce)) silver" : nil,
        ].compactMap { $0 }
        return parts.isEmpty ? "0 oz" : parts.joined(separator: " · ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Vault Value")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(Formatters.currencyString(currentValue))
                .font(.system(size: 40, weight: .bold, design: .rounded))

            HStack {
                Label(weightSummary, systemImage: "scalemass")
                Spacer()
                Text("Cost basis: \(Formatters.currencyString(totalCost))")
            }
            .font(.footnote)
            .foregroundStyle(.secondary)

            Divider()

            HStack(spacing: 6) {
                Image(systemName: gainLoss >= 0 ? "arrow.up.right" : "arrow.down.right")
                Text(Formatters.currencyString(gainLoss))
                Text("(\(Formatters.percentString(gainLossPercent)))")
                Spacer()
                Text("vs. spot")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .font(.headline)
            .foregroundStyle(gainLoss >= 0 ? Color.green : Color.red)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    SummaryCardView(lots: [], spotProvider: { _ in 4118 })
        .padding()
}
