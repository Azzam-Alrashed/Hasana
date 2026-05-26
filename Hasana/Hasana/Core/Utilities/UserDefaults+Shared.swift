import Foundation

extension UserDefaults {
    /// A shared UserDefaults suite used for syncing data between the main app and home screen widgets.
    /// Both the main app and the HasanaWidgets extension must belong to the same App Group:
    /// `group.sa.Alrashed.Azzam.Hasana`
    nonisolated(unsafe) static let shared: UserDefaults =
        UserDefaults(suiteName: "group.sa.Alrashed.Azzam.Hasana") ?? .standard
}
