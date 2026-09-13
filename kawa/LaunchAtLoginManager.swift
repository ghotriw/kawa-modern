import Foundation
import ServiceManagement

final class LaunchAtLoginManager: ObservableObject {
    static let shared = LaunchAtLoginManager()

    @Published var isEnabled: Bool {
        didSet {
            guard isEnabled != (SMAppService.mainApp.status == .enabled) else { return }
            do {
                if isEnabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("[Kawa] Failed to update launch at login: \(error)")
                DispatchQueue.main.async {
                    self.isEnabled = (SMAppService.mainApp.status == .enabled)
                }
            }
        }
    }

    private init() {
        self.isEnabled = (SMAppService.mainApp.status == .enabled)
    }

    func refresh() {
        self.isEnabled = (SMAppService.mainApp.status == .enabled)
    }
}
