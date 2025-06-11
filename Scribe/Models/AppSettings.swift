import SwiftUI

@Observable
class AppSettings {
    var colorScheme: ColorScheme?

    init() {
        // Load saved settings
        if let savedScheme = UserDefaults.standard.object(forKey: "colorScheme") as? Int {
            switch savedScheme {
            case 0:
                self.colorScheme = .light
            case 1:
                self.colorScheme = .dark
            default:
                self.colorScheme = nil
            }
        } else {
            self.colorScheme = nil
        }
    }

    func setColorScheme(_ scheme: ColorScheme?) {
        self.colorScheme = scheme

        // Save to UserDefaults
        if let scheme = scheme {
            UserDefaults.standard.set(scheme == .light ? 0 : 1, forKey: "colorScheme")
        } else {
            UserDefaults.standard.removeObject(forKey: "colorScheme")
        }
    }

    var themeDisplayName: String {
        switch colorScheme {
        case .light:
            return "Light"
        case .dark:
            return "Dark"
        case nil:
            return "System"
        case .some(_):
            return "System"
        }
    }
}
