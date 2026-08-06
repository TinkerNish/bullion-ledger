import Foundation
import Combine
import UserNotifications

/// Persists user-configured buy/sell price alerts, watches the live spot
/// prices from `GoldPriceService`, and fires a local notification the moment
/// an alert's target is reached.
@MainActor
final class PriceAlertStore: NSObject, ObservableObject {
    @Published var alerts: [PriceAlert] = [] {
        didSet { save() }
    }
    @Published var notificationsAuthorized = false

    private var cancellables = Set<AnyCancellable>()

    private let fileURL: URL = {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return dir.appendingPathComponent("price_alerts.json")
    }()

    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        load()
        refreshAuthorizationStatus()
    }

    /// Wires this store up to a price service so alerts are checked
    /// automatically every time a fresh spot price comes in — on manual
    /// refresh, pull-to-refresh, or app launch.
    func observe(_ priceService: GoldPriceService) {
        priceService.$pricePerOzGold
            .compactMap { $0 }
            .sink { [weak self] price in
                Task { @MainActor in self?.check(metal: .gold, currentPrice: price) }
            }
            .store(in: &cancellables)

        priceService.$pricePerOzSilver
            .compactMap { $0 }
            .sink { [weak self] price in
                Task { @MainActor in self?.check(metal: .silver, currentPrice: price) }
            }
            .store(in: &cancellables)
    }

    // MARK: - CRUD

    func add(_ alert: PriceAlert) {
        alerts.append(alert)
        requestAuthorizationIfNeeded()
    }

    func update(_ alert: PriceAlert) {
        guard let index = alerts.firstIndex(where: { $0.id == alert.id }) else { return }
        alerts[index] = alert
    }

    func delete(at offsets: IndexSet, in list: [PriceAlert]) {
        let ids = offsets.map { list[$0].id }
        alerts.removeAll { ids.contains($0.id) }
    }

    /// Enables or disables an alert. Re-enabling clears any prior trigger so
    /// it can fire again on the next crossing.
    func setEnabled(_ isEnabled: Bool, for alert: PriceAlert) {
        guard let index = alerts.firstIndex(where: { $0.id == alert.id }) else { return }
        alerts[index].isEnabled = isEnabled
        if isEnabled {
            alerts[index].lastTriggeredAt = nil
            requestAuthorizationIfNeeded()
        }
    }

    // MARK: - Notification authorization

    func requestAuthorizationIfNeeded() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            if settings.authorizationStatus == .notDetermined {
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                    Task { @MainActor in self?.notificationsAuthorized = granted }
                }
            } else {
                Task { @MainActor in self?.refreshAuthorizationStatus() }
            }
        }
    }

    private func refreshAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            Task { @MainActor in
                self?.notificationsAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }

    // MARK: - Threshold checking

    private func check(metal: Metal, currentPrice: Double) {
        guard currentPrice > 0 else { return }
        for index in alerts.indices {
            let alert = alerts[index]
            guard alert.metal == metal, alert.isEnabled else { continue }
            guard alert.direction.isSatisfied(currentPrice: currentPrice, targetPrice: alert.targetPrice) else { continue }
            // Already notified for this crossing — don't spam on every refresh.
            guard alert.lastTriggeredAt == nil else { continue }

            alerts[index].lastTriggeredAt = Date()
            alerts[index].isEnabled = false
            fireNotification(for: alert, currentPrice: currentPrice)
        }
    }

    private func fireNotification(for alert: PriceAlert, currentPrice: Double) {
        let content = UNMutableNotificationContent()
        content.title = "\(alert.direction.label) alert: \(alert.metal.label)"
        content.body = "\(alert.metal.label) is now \(Formatters.currencyString(currentPrice))/oz — your \(alert.direction.label.lowercased()) target of \(Formatters.currencyString(alert.targetPrice))/oz was reached."
        content.sound = .default

        let request = UNNotificationRequest(identifier: alert.id.uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Persistence

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        if let decoded = try? JSONDecoder().decode([PriceAlert].self, from: data) {
            alerts = decoded
        }
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(alerts) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}

// MARK: - Foreground presentation

extension PriceAlertStore: UNUserNotificationCenterDelegate {
    /// Without this, iOS suppresses local notification banners while the app
    /// is in the foreground. Alerts should show up even while you're looking
    /// at Bullion Ledger.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .list])
    }
}
