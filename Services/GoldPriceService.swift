import Foundation

struct SpotPriceResponse: Codable {
    let price: Double
    let currency: String
    let updatedAt: String
}

enum GoldPriceError: Error {
    case invalidResponse
}

/// Fetches live spot prices (USD per troy oz) for gold (XAU) and silver (XAG) from the
/// free, keyless gold-api.com endpoint. No account or API key required.
@MainActor
final class GoldPriceService: ObservableObject {
    @Published var pricePerOzGold: Double?
    @Published var pricePerOzSilver: Double?
    @Published var lastUpdated: Date?
    @Published var isLoading = false
    @Published var errorMessage: String?

    /// Backwards-compatible accessor for the gold price.
    var pricePerOz: Double? { pricePerOzGold }

    private func url(for metal: Metal) -> URL {
        URL(string: "https://api.gold-api.com/price/\(metal.symbol)")!
    }

    /// Current spot price for a metal, or 0 if not yet loaded.
    func spot(for metal: Metal) -> Double {
        switch metal {
        case .gold: return pricePerOzGold ?? 0
        case .silver: return pricePerOzSilver ?? 0
        }
    }

    func refresh() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        async let goldResult = fetch(.gold)
        async let silverResult = fetch(.silver)
        let (gold, silver) = await (goldResult, silverResult)

        var failures = 0
        if let gold {
            pricePerOzGold = gold
        } else {
            failures += 1
        }
        if let silver {
            pricePerOzSilver = silver
        } else {
            failures += 1
        }

        if failures == 2 {
            errorMessage = (pricePerOzGold == nil && pricePerOzSilver == nil)
                ? "Couldn't fetch live prices. Check your connection and try again."
                : "Couldn't refresh prices. Showing last known spot prices."
        } else if failures == 1 {
            errorMessage = "Couldn't refresh one of the spot prices. Showing last known value for it."
        }

        if failures < 2 {
            lastUpdated = Date()
        }
    }

    private func fetch(_ metal: Metal) async -> Double? {
        do {
            let (data, response) = try await URLSession.shared.data(from: url(for: metal))
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                throw GoldPriceError.invalidResponse
            }
            let decoded = try JSONDecoder().decode(SpotPriceResponse.self, from: data)
            return decoded.price
        } catch {
            return nil
        }
    }
}
