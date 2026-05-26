import Foundation

extension UserDefaults {
    /// A shared UserDefaults suite used for syncing settings and worship data between the main app and home screen widgets.
    static var shared: UserDefaults {
        #if targetEnvironment(simulator)
        // In the simulator, suite-based storage works without provisioning.
        return UserDefaults(suiteName: "group.sa.Alrashed.Azzam.Hasana") ?? .standard
        #else
        // For physical devices, fall back to standard if the App Group is not configured.
        return UserDefaults(suiteName: "group.sa.Alrashed.Azzam.Hasana") ?? .standard
        #endif
    }
}
