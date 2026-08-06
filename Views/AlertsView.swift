import SwiftUI

struct AlertsView: View {
    @EnvironmentObject var alertStore: PriceAlertStore
    @EnvironmentObject var priceService: GoldPriceService
    @State private var showingAddAlert = false
    @State private var editingAlert: PriceAlert?

    private var sortedAlerts: [PriceAlert] {
        alertStore.alerts.sorted { $0.createdAt > $1.createdAt }
    }

    var body: some View {
        List {
            if !alertStore.notificationsAuthorized {
                Section {
                    Label(
                        "Notifications aren't enabled. Turn them on in Settings so Bullion Ledger can alert you when a price is hit.",
                        systemImage: "bell.slash"
                    )
                    .font(.footnote)
                    .foregroundStyle(.orange)
                }
            }

            if sortedAlerts.isEmpty {
                Section {
                    Text("No alerts yet. Tap + to get notified when gold or silver hits a buy or sell price.")
                        .foregroundStyle(.secondary)
                }
            } else {
                Section("Alerts") {
                    ForEach(sortedAlerts) { alert in
                        AlertRowView(
                            alert: alert,
                            currentPrice: priceService.spot(for: alert.metal),
                            onEdit: { editingAlert = alert },
                            onToggle: { newValue in alertStore.setEnabled(newValue, for: alert) }
                        )
                    }
                    .onDelete { offsets in
                        alertStore.delete(at: offsets, in: sortedAlerts)
                    }
                }
            }
        }
        .navigationTitle("Price Alerts")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddAlert = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddAlert) {
            AddAlertView()
        }
        .sheet(item: $editingAlert) { alert in
            AddAlertView(existingAlert: alert)
        }
        .onAppear {
            alertStore.requestAuthorizationIfNeeded()
        }
    }
}

private struct AlertRowView: View {
    let alert: PriceAlert
    let currentPrice: Double
    let onEdit: () -> Void
    let onToggle: (Bool) -> Void

    var body: some View {
        HStack {
            Button(action: onEdit) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: alert.direction.symbolName)
                        .foregroundStyle(alert.direction == .buy ? .green : .red)
                        .font(.title3)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(alert.direction.label) \(alert.metal.label)")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text("Target: \(Formatters.currencyString(alert.targetPrice))/oz")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        if let firedAt = alert.lastTriggeredAt {
                            Text("Triggered \(firedAt.formatted(date: .abbreviated, time: .shortened))")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        } else if currentPrice > 0 {
                            Text("Current: \(Formatters.currencyString(currentPrice))/oz")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .buttonStyle(.plain)

            Spacer()

            Toggle("", isOn: Binding(get: { alert.isEnabled }, set: onToggle))
                .labelsHidden()
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    NavigationStack {
        AlertsView()
            .environmentObject(PriceAlertStore())
            .environmentObject(GoldPriceService())
    }
}
