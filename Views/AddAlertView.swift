import SwiftUI

struct AddAlertView: View {
    @EnvironmentObject var alertStore: PriceAlertStore
    @EnvironmentObject var priceService: GoldPriceService
    @Environment(\.dismiss) private var dismiss

    var existingAlert: PriceAlert?

    @State private var metal: Metal
    @State private var direction: AlertDirection
    @State private var targetPriceText: String

    init(existingAlert: PriceAlert? = nil, defaultMetal: Metal = .gold) {
        self.existingAlert = existingAlert
        _metal = State(initialValue: existingAlert?.metal ?? defaultMetal)
        _direction = State(initialValue: existingAlert?.direction ?? .buy)
        _targetPriceText = State(initialValue: existingAlert.map { Formatters.rawNumberString($0.targetPrice) } ?? "")
    }

    private var targetPrice: Double? {
        Double(targetPriceText)
    }

    private var isValid: Bool {
        guard let price = targetPrice else { return false }
        return price > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Metal") {
                    Picker("Metal", selection: $metal) {
                        ForEach(Metal.allCases) { m in
                            Text(m.label).tag(m)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Alert Type") {
                    Picker("Type", selection: $direction) {
                        ForEach(AlertDirection.allCases) { d in
                            Text(d.label).tag(d)
                        }
                    }
                    .pickerStyle(.segmented)
                    Text(direction.helpText)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Target Price (per oz)") {
                    HStack {
                        Text("$")
                        TextField("0.00", text: $targetPriceText)
                            .keyboardType(.decimalPad)
                    }
                    let current = priceService.spot(for: metal)
                    if current > 0 {
                        Text("Current \(metal.label.lowercased()) spot: \(Formatters.currencyString(current))/oz")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle(existingAlert == nil ? "New Alert" : "Edit Alert")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!isValid)
                }
            }
        }
    }

    private func save() {
        guard let price = targetPrice else { return }
        if var alert = existingAlert {
            alert.metal = metal
            alert.direction = direction
            alert.targetPrice = price
            alert.isEnabled = true
            alert.lastTriggeredAt = nil
            alertStore.update(alert)
            alertStore.requestAuthorizationIfNeeded()
        } else {
            let alert = PriceAlert(metal: metal, direction: direction, targetPrice: price)
            alertStore.add(alert)
        }
        dismiss()
    }
}

#Preview {
    AddAlertView()
        .environmentObject(PriceAlertStore())
        .environmentObject(GoldPriceService())
}
