import SwiftUI

@main
struct MetalVaultApp: App {
    @StateObject private var vaultStore = VaultStore()
    @StateObject private var priceService = GoldPriceService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(vaultStore)
                .environmentObject(priceService)
        }
    }
}
