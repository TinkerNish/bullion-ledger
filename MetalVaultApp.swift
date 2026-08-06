import SwiftUI

@main
struct MetalVaultApp: App {
    @StateObject private var vaultStore = VaultStore()
    @StateObject private var priceService = GoldPriceService()
    @StateObject private var alertStore = PriceAlertStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(vaultStore)
                .environmentObject(priceService)
                .environmentObject(alertStore)
                .onAppear {
                    alertStore.observe(priceService)
                }
        }
    }
}
