import Foundation

/// Persists your gold purchases to a JSON file in the app's Documents directory.
@MainActor
final class VaultStore: ObservableObject {
    @Published var lots: [GoldLot] = [] {
        didSet { save() }
    }

    private let fileURL: URL = {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return dir.appendingPathComponent("gold_lots.json")
    }()

    init() {
        load()
    }

    func add(_ lot: GoldLot) {
        lots.append(lot)
    }

    func update(_ lot: GoldLot) {
        guard let index = lots.firstIndex(where: { $0.id == lot.id }) else { return }
        lots[index] = lot
    }

    func delete(_ lot: GoldLot) {
        lots.removeAll { $0.id == lot.id }
    }

    /// Adds imported lots, updating any that already exist (matched by id) and
    /// appending the rest. Safe to run the same import twice.
    func mergeImport(_ imported: [GoldLot]) {
        var updated = lots
        for lot in imported {
            if let index = updated.firstIndex(where: { $0.id == lot.id }) {
                updated[index] = lot
            } else {
                updated.append(lot)
            }
        }
        lots = updated
    }

    /// Wipes the current vault and replaces it entirely with the imported lots.
    func replaceAll(with imported: [GoldLot]) {
        lots = imported
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        if let decoded = try? JSONDecoder().decode([GoldLot].self, from: data) {
            lots = decoded
        }
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(lots) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
