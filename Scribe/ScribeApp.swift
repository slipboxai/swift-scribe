import SwiftData
import SwiftUI

@main
struct SwiftTranscriptionSampleApp: App {
    @State private var settings = AppSettings()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(settings)
                .preferredColorScheme(settings.colorScheme)
        }

        #if os(macOS)
            Settings {
                SettingsView(settings: settings)
            }
        #endif
    }
}
