import SwiftUI

struct AddLotView: View {
    @EnvironmentObject var vaultStore: VaultStore
    @Environment(\.dismiss) private var dismiss

    /// When non-nil, the form edits this existing lot instead of creating a new one.
    var existingLot: GoldLot? = nil

    @State private var date: Date
    @State private var weightText: String
    @State private var unit: WeightUnit
    @State private var metal: Metal
    @State private var totalPaidText: String
    @State private var notes: String
    @State private var showingDeleteConfirm = false

    init(existingLot: GoldLot? = nil, defaultMetal: Metal = .gold) {
        self.existingLot = existingLot
        _date = State(initialValue: existingLot?.date ?? Date())
        if let lot = existingLot {
            _weightText = State(initialValue: Formatters.rawNumberString(lot.displayUnit.fromTroyOunces(lot.weightOz)))
            _totalPaidText = State(initialValue: Formatters.rawNumberString(lot.totalCostPaid))
        } else {
            _weightText = State(initialValue: "")
            _totalPaidText = State(initialValue: "")
        }
        _unit = State(initialValue: existingLot?.displayUnit ?? .troyOunce)
        _metal = State(initialValue: existingLot?.metal ?? defaultMetal)
        _notes = State(initialValue: existingLot?.notes ?? "")
    }

    private var isEditing: Bool { existingLot != nil }

    private var weightValue: Double? { Double(weightText) }
    private var totalPaidValue: Double? { Double(totalPaidText) }

    private var pricePerOzPreview: Double? {
        guard let w = weightValue, w > 0, let paid = totalPaidValue else { return nil }
        let oz = unit.toTroyOunces(w)
        return paid / oz
    }

    private var canSave: Bool {
        guard let w = weightValue, w > 0 else { return false }
        guard let p = totalPaidValue, p > 0 else { return false }
        return true
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Purchase Details") {
                    Picker("Metal", selection: $metal) {
                        ForEach(Metal.allCases) { m in
                            Text(m.label).tag(m)
                        }
                    }
                    .pickerStyle(.segmented)

                    DatePicker("Date", selection: $date, displayedComponents: .date)

                    HStack {
                        TextField("Weight", text: $weightText)
                            .keyboardType(.decimalPad)
                        Picker("Unit", selection: $unit) {
                            ForEach(WeightUnit.allCases) { u in
                                Text(u.rawValue).tag(u)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 140)
                    }

                    TextField("Total amount paid (USD)", text: $totalPaidText)
                        .keyboardType(.decimalPad)

                    if let ppo = pricePerOzPreview {
                        HStack {
                            Text("Price paid per oz")
                            Spacer()
                            Text(Formatters.currencyString(ppo))
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Notes") {
                    TextField("e.g. dealer name, coin type", text: $notes, axis: .vertical)
                }

                if isEditing {
                    Section {
                        Button("Delete Purchase", role: .destructive) {
                            showingDeleteConfirm = true
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Purchase" : "Add Purchase")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!canSave)
                }
            }
            .confirmationDialog(
                "Delete this purchase?",
                isPresented: $showingDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    if let lot = existingLot {
                        vaultStore.delete(lot)
                    }
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    private func save() {
        guard let w = weightValue, let paid = totalPaidValue else { return }
        let oz = unit.toTroyOunces(w)
        var lot = existingLot ?? GoldLot(
            date: date,
            weightOz: oz,
            totalCostPaid: paid,
            displayUnit: unit,
            metal: metal,
            notes: notes
        )
        lot.date = date
        lot.weightOz = oz
        lot.totalCostPaid = paid
        lot.displayUnit = unit
        lot.metal = metal
        lot.notes = notes

        if isEditing {
            vaultStore.update(lot)
        } else {
            vaultStore.add(lot)
        }
        dismiss()
    }
}

#Preview {
    AddLotView()
        .environmentObject(VaultStore())
}
