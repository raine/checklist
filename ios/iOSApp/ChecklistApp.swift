import AppIntents
import SwiftUI

@main
struct ChecklistApp: App {
    @AppStorage("appearanceMode") private var appearanceModeRaw: Int = AppearanceMode.system.rawValue

    private var appearanceMode: AppearanceMode {
        AppearanceMode(rawValue: appearanceModeRaw) ?? .system
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(appearanceMode.colorScheme)
                .task {
                    ChecklistShortcuts.updateAppShortcutParameters()
                }
        }
    }
}
