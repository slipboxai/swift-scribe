import SwiftUI

enum SettingsTab: String, CaseIterable, Identifiable {
    case general = "General"
    case appearance = "Appearance"
    case about = "About"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .general:
            return "gearshape"
        case .appearance:
            return "paintbrush"
        case .about:
            return "info.circle"
        }
    }
}

enum ThemeOption: CaseIterable {
    case system
    case light
    case dark

    var displayName: String {
        switch self {
        case .system:
            return "System"
        case .light:
            return "Light"
        case .dark:
            return "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }

    static func from(colorScheme: ColorScheme?) -> ThemeOption {
        switch colorScheme {
        case .light:
            return .light
        case .dark:
            return .dark
        case .none:
            return .system
        case .some(_):
            return .system
        }
    }
}

struct SettingsView: View {
    @Bindable var settings: AppSettings
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTheme: ThemeOption = .system
    @State private var selectedTab: SettingsTab = .general
    @State private var columnVisibility = NavigationSplitViewVisibility.all

    private var isPhone: Bool {
        #if os(iOS)
            return UIDevice.current.userInterfaceIdiom == .phone
        #else
            return false
        #endif
    }

    var body: some View {
        #if os(iOS)
            phoneLayout
        #else
            splitViewLayout
        #endif
    }

    #if os(iOS)
        private var phoneLayout: some View {
            NavigationStack {
                List {
                    ForEach(SettingsTab.allCases) { tab in
                        NavigationLink(destination: settingsContent(for: tab)) {
                            Label(tab.rawValue, systemImage: tab.icon)
                        }
                    }
                }
                .navigationTitle("Settings")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        dismissButton
                    }
                }
            }
        }
    #endif

    private var splitViewLayout: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            sidebarContent
        } detail: {
            detailContent
        }
        .frame(minWidth: 600, minHeight: 400)
        .onAppear {
            selectedTheme = ThemeOption.from(colorScheme: settings.colorScheme)
        }
    }

    private var sidebarContent: some View {
        #if os(macOS)
            List(SettingsTab.allCases, selection: $selectedTab) { tab in
                Label(tab.rawValue, systemImage: tab.icon)
                    .tag(tab)
            }
            .navigationTitle("Settings")
            .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 250)
            .toolbarBackground(.hidden)
            .padding(.top, 10)
            .toolbar(removing: .sidebarToggle)
        #else
            List(SettingsTab.allCases) { tab in
                Button(action: { selectedTab = tab }) {
                    Label(tab.rawValue, systemImage: tab.icon)
                        .foregroundColor(selectedTab == tab ? .accentColor : .primary)
                }
                .listRowBackground(
                    selectedTab == tab ? Color.accentColor.opacity(0.1) : Color.clear
                )
            }
            .navigationTitle("Settings")
            .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 250)
            .toolbarBackground(.hidden)
        #endif
    }

    private var detailContent: some View {
        settingsContent(for: selectedTab)
            .navigationTitle(selectedTab.rawValue)
            #if os(macOS)
                .navigationSplitViewStyle(.balanced)
                .navigationSubtitle("")
            #endif
            .toolbar {
                #if os(iOS)
                    ToolbarItem(placement: .navigationBarTrailing) {
                        dismissButton
                    }
                #endif
            }
            .toolbarBackground(.hidden)
    }

    private var dismissButton: some View {
        Button(action: { dismiss() }) {
            Image(systemName: "xmark")
        }
    }

    @ViewBuilder
    private func settingsContent(for tab: SettingsTab) -> some View {
        switch tab {
        case .general:
            GeneralSettingsView()
        case .appearance:
            AppearanceSettingsView(settings: settings, selectedTheme: $selectedTheme)
                .onAppear {
                    selectedTheme = ThemeOption.from(colorScheme: settings.colorScheme)
                }
        case .about:
            AboutSettingsView()
        }
    }
}

struct GeneralSettingsView: View {
    var body: some View {
        SettingsPageView(
            title: "General Settings",
            subtitle: "Configure general app behavior and preferences."
        ) {
            SettingsGroup(title: "Coming Soon") {
                HStack {
                    Image(systemName: "wrench.and.screwdriver")
                        .foregroundStyle(.secondary)
                        .font(.title2)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("General Preferences")
                            .fontWeight(.medium)
                        Text("Additional settings will be added in future updates")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }
                .padding()
            }
        }
    }
}

struct AppearanceSettingsView: View {
    @Bindable var settings: AppSettings
    @Binding var selectedTheme: ThemeOption

    var body: some View {
        SettingsPageView(
            title: "Appearance",
            subtitle: "Customize the look and feel of the app."
        ) {
            SettingsGroup(title: "Theme") {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Color Scheme")
                            .fontWeight(.medium)
                        Spacer()
                    }

                    Picker("Theme", selection: $selectedTheme) {
                        ForEach(ThemeOption.allCases, id: \.self) { option in
                            Text(option.displayName).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: selectedTheme) { _, newValue in
                        settings.setColorScheme(newValue.colorScheme)
                    }

                    Text(
                        "Choose how the app appears. System uses your device's appearance setting."
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                .padding()
            }
        }
    }
}

struct AboutSettingsView: View {
    var body: some View {
        SettingsPageView(
            title: "About",
            subtitle: "Information about Swift Scribe."
        ) {
            SettingsGroup(title: "App Information") {
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: "app.badge")
                            .font(.largeTitle)
                            .foregroundStyle(.blue)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Swift Scribe")
                                .font(.headline)
                                .fontWeight(.semibold)
                            Text("AI-powered audio transcription and note-taking")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()
                    }

                    Divider()

                    VStack(spacing: 12) {
                        SettingsInfoRow(label: "Version", value: "1.0.0")
                        SettingsInfoRow(label: "Build", value: "1.0.0 (1)")
                        SettingsInfoRow(label: "Platform", value: platformName)
                    }
                }
                .padding()
            }
        }
    }

    private var platformName: String {
        #if os(macOS)
            return "macOS"
        #elseif os(iOS)
            return "iOS"
        #else
            return "Unknown"
        #endif
    }
}

// MARK: - Reusable Components

struct SettingsPageView<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder let content: Content

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(title)
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text(subtitle)
                            .foregroundStyle(.secondary)
                    }

                    content
                }
                .padding()
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
    }
}

struct SettingsGroup<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        GroupBox(title) {
            content
        }
    }
}

struct SettingsInfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .fontWeight(.medium)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
                .fontDesign(.monospaced)
        }
    }
}

#Preview {
    SettingsView(settings: AppSettings())
}
