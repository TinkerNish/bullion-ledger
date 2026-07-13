import SwiftUI

struct LotRowView: View {
    let lot: GoldLot
    let spotPerOz: Double

    var gainLoss: Double { lot.gainLoss(atSpotPerOz: spotPerOz) }
    var gainLossPercent: Double { lot.gainLossPercent(atSpotPerOz: spotPerOz) }

    private var metalColor: Color {
        lot.metal == .gold ? Color(red: 0.83, green: 0.68, blue: 0.21) : Color(white: 0.6)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Circle()
                    .fill(metalColor)
                    .frame(width: 8, height: 8)
                Text(lot.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text(Formatters.weightString(lot.displayUnit.fromTroyOunces(lot.weightOz), unit: lot.displayUnit))
                    .font(.subheadline)
            }

            HStack {
                Text("Paid \(Formatters.currencyString(lot.pricePaidPerOz))/oz")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: gainLoss >= 0 ? "arrow.up.right" : "arrow.down.right")
                    Text(Formatters.currencyString(gainLoss))
                    Text("(\(Formatters.percentString(gainLossPercent)))")
                }
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(gainLoss >= 0 ? Color.green : Color.red)
            }

            if !lot.notes.isEmpty {
                Text(lot.notes)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    LotRowView(
        lot: GoldLot(date: .now, weightOz: 1, totalCostPaid: 3900),
        spotPerOz: 4118
    )
    .padding()
}
