import SwiftUI
import UniformTypeIdentifiers

enum MetalFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case gold = "Gold"
    case silver = "Silver"

    var id: String { rawValue }

    func matches(_ metal: Metal) -> Bool {
        switch self {
        case .all: return true
        case .gold: return metal == .gold
        case .silver: return metal == .silver
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var vaultStore: VaultStore
    @EnvironmentObject var priceService: GoldPriceService
    @State private var showingAddLot = false
    @State private var editingLot: GoldLot?
    @State private var filter: MetalFilter = .all

    // Export / import
    @State private var showingExporter = false
    @State private var exportDocument = VaultExportDocument(lots: [])
    @State private var showingImporter = false
    @State private var pendingImportLots: [GoldLot]?
    @State private var showingImportModeChoice = false
    @State private var resultMessage: String?
    @State private var showingResultAlert = false

    var filteredLots: [GoldLot] {
        vaultStore.lots.filter { filter.matches($0.metal) }
    }

    var sortedLots: [GoldLot] {
        filteredLots.sorted(by: { $0.date > $1.date })
    }

    private var defaultMetalForNewLot: Metal {
        filter == .silver ? .silver : .gold
    }

    private var exportFilename: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return "MetalVault-\(f.string(from: Date()))"
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    SummaryCardView(lots: filteredLots, spotProvider: { priceService.spot(for: $0) })
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }

                Section {
                    HStack {
                        Text("Gold: \(Formatters.currencyString(priceService.spot(for: .gold)))/oz")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("Silver: \(Formatters.currencyString(priceService.spot(for: .silver)))/oz")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    if let updated = priceService.lastUpdated {
                        Text("Updated \(updated.formatted(date: .omitted, time: .shortened))")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    if let error = priceService.errorMessage {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(.orange)
                    }
                }

                Section("Purchases") {
                    Picker("Filter", selection: $filter) {
                        ForEach(MetalFilter.allCases) { f in
                            Text(f.rawValue).tag(f)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 8, trailing: 16))

                    if filteredLots.isEmpty {
                        Text(vaultStore.lots.isEmpty
                             ? "No purchases yet. Tap + to add your first lot."
                             : "No \(filter.rawValue.lowercased()) purchases yet.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(sortedLots) { lot in
                            LotRowView(lot: lot, spotPerOz: priceService.spot(for: lot.metal))
                                .contentShape(Rectangle())
                                .onTapGesture { editingLot = lot }
                        }
                        .onDelete { offsets in
                            let idsToDelete = offsets.map { sortedLots[$0].id }
                            vaultStore.lots.removeAll { idsToDelete.contains($0.id) }
                        }
                    }
                }
            }
            .navigationTitle("Bullion Ledger")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        Task { await priceService.refresh() }
                    } label: {
                        if priceService.isLoading {
                            ProgressView()
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            exportDocument = VaultExportDocument(lots: vaultStore.lots)
                            showingExporter = true
                        } label: {
                            Label("Export Data", systemImage: "square.and.arrow.up")
                        }
                        Button {
                            showingImporter = true
                        } label: {
                            Label("Import Data", systemImage: "square.and.arrow.down")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddLot = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddLot) {
                AddLotView(defaultMetal: defaultMetalForNewLot)
            }
            .sheet(item: $editingLot) { lot in
                AddLotView(existingLot: lot)
            }
            .fileExporter(
                isPresented: $showingExporter,
                document: exportDocument,
                contentType: .json,
                defaultFilename: exportFilename
            ) { result in
                if case .failure(let error) = result {
                    resultMessage = "Export failed: \(error.localizedDescription)"
                    showingResultAlert = true
                }
            }
            .fileImporter(
                isPresented: $showingImporter,
                allowedContentTypes: [.json]
            ) { result in
                switch result {
                case .success(let url):
                    importFile(at: url)
                case .failure(let error):
                    resultMessage = "Import failed: \(error.localizedDescription)"
                    showingResultAlert = true
                }
            }
            .confirmationDialog(
                "Import \(pendingImportLots?.count ?? 0) Purchase\((pendingImportLots?.count ?? 0) == 1 ? "" : "s")",
                isPresented: $showingImportModeChoice,
                titleVisibility: .visible
            ) {
                Button("Merge with Existing") {
                    if let lots = pendingImportLots {
                        vaultStore.mergeImport(lots)
                        resultMessage = "Merged \(lots.count) purchase(s) into your vault."
                        showingResultAlert = true
                    }
                    pendingImportLots = nil
                }
                Button("Replace All Data", role: .destructive) {
                    if let lots = pendingImportLots {
                        vaultStore.replaceAll(with: lots)
                        resultMessage = "Replaced your vault with \(lots.count) purchase(s)."
                        showingResultAlert = true
                    }
                    pendingImportLots = nil
                }
                Button("Cancel", role: .cancel) { pendingImportLots = nil }
            } message: {
                Text("Merge updates matching purchases and adds new ones. Replace clears everything currently in the vault first.")
            }
            .alert(
                "Bullion Ledger",
                isPresented: $showingResultAlert,
                presenting: resultMessage
            ) { _ in
                Button("OK", role: .cancel) {}
            } message: { message in
                Text(message)
            }
            .task {
                await priceService.refresh()
            }
            .refreshable {
                await priceService.refresh()
            }
        }
    }

    private func importFile(at url: URL) {
        let accessed = url.startAccessingSecurityScopedResource()
        defer { if accessed { url.stopAccessingSecurityScopedResource() } }
        do {
            let data = try Data(contentsOf: url)
            let lots = try VaultCoding.decode(data)
            pendingImportLots = lots
            showingImportModeChoice = true
        } catch {
            resultMessage = "Import failed: \(error.localizedDescription)"
            showingResultAlert = true
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(VaultStore())
        .environmentObject(GoldPriceService())
}
