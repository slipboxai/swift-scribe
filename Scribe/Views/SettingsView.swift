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

    var body: some View {
        #if os(iOS)
            // Use different navigation patterns based on device
            if UIDevice.current.userInterfaceIdiom == .phone {
                // iPhone: Use NavigationStack with list-style navigation
                NavigationStack {
                    List {
                        ForEach(SettingsTab.allCases) { tab in
                            NavigationLink(destination: destinationView(for: tab)) {
                                Label(tab.rawValue, systemImage: tab.icon)
                            }
                        }
                    }
                    .navigationTitle("Settings")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: {
                                dismiss()
                            }) {
                                Image(systemName: "xmark")
                            }
                        }
                    }
                }
            } else {
                // iPad: Use NavigationSplitView
                splitViewLayout
            }
        #else
            // macOS: Use NavigationSplitView
            splitViewLayout
        #endif
    }

    private var splitViewLayout: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // Sidebar - following WWDC 2025 sidebar best practices
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
                    Button(action: {
                        selectedTab = tab
                    }) {
                        Label(tab.rawValue, systemImage: tab.icon)
                            .foregroundColor(selectedTab == tab ? .accentColor : .primary)
                    }
                    .listRowBackground(
                        selectedTab == tab ? Color.accentColor.opacity(0.1) : Color.clear)
                }
                .navigationTitle("Settings")
                .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 250)
                .toolbarBackground(.hidden)
            #endif
        } detail: {
            // Main content area with proper navigation structure
            Group {
                switch selectedTab {
                case .general:
                    GeneralSettingsView()
                case .appearance:
                    AppearanceSettingsView(settings: settings, selectedTheme: $selectedTheme)
                case .about:
                    AboutSettingsView()
                }
            }
            .navigationTitle(selectedTab.rawValue)
            #if os(macOS)
                .navigationSplitViewStyle(.balanced)
                .navigationSubtitle("")
            #endif
            .toolbar {
                #if os(iOS)
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                #endif
            }
            .toolbarBackground(.hidden)
        }
        .frame(minWidth: 600, minHeight: 400)
        .onAppear {
            selectedTheme = ThemeOption.from(colorScheme: settings.colorScheme)
        }
    }

    @ViewBuilder
    private func destinationView(for tab: SettingsTab) -> some View {
        switch tab {
        case .general:
            GeneralSettingsView()
                .navigationTitle(tab.rawValue)
                .navigationBarTitleDisplayMode(.large)
        case .appearance:
            AppearanceSettingsView(settings: settings, selectedTheme: $selectedTheme)
                .navigationTitle(tab.rawValue)
                .navigationBarTitleDisplayMode(.large)
                .onAppear {
                    selectedTheme = ThemeOption.from(colorScheme: settings.colorScheme)
                }
        case .about:
            AboutSettingsView()
                .navigationTitle(tab.rawValue)
                .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct GeneralSettingsView: View {
    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("General Settings")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text("Configure general app behavior and preferences.")
                            .foregroundStyle(.secondary)
                    }

                    // Following WWDC 2025 grouping guidelines
                    GroupBox("Coming Soon") {
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
                .padding()
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)  // WWDC 2025: Let new materials shine through
    }
}

struct AppearanceSettingsView: View {
    @Bindable var settings: AppSettings
    @Binding var selectedTheme: ThemeOption

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Appearance")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text("Customize the look and feel of the app.")
                            .foregroundStyle(.secondary)
                    }

                    // Following WWDC 2025 control grouping and styling
                    GroupBox("Theme") {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Color Scheme")
                                    .fontWeight(.medium)
                                Spacer()
                            }

                            Picker("Theme", selection: $selectedTheme) {
                                ForEach(ThemeOption.allCases, id: \.self) { option in
                                    Text(option.displayName)
                                        .tag(option)
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
                .padding()
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)  // WWDC 2025: Clean background for new materials
    }
}

struct AboutSettingsView: View {
    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("About")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text("Information about Slipbox Scribe.")
                            .foregroundStyle(.secondary)
                    }

                    GroupBox("App Information") {
                        VStack(spacing: 16) {
                            HStack {
                                Image(systemName: "app.badge")
                                    .font(.largeTitle)
                                    .foregroundStyle(.blue)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Slipbox Scribe")
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
                                HStack {
                                    Text("Version")
                                        .fontWeight(.medium)
                                    Spacer()
                                    Text("1.0.0")
                                        .foregroundStyle(.secondary)
                                        .fontDesign(.monospaced)
                                }

                                HStack {
                                    Text("Build")
                                        .fontWeight(.medium)
                                    Spacer()
                                    Text("1.0.0 (1)")
                                        .foregroundStyle(.secondary)
                                        .fontDesign(.monospaced)
                                }

                                HStack {
                                    Text("Platform")
                                        .fontWeight(.medium)
                                    Spacer()
                                    #if os(macOS)
                                        Text("macOS")
                                            .foregroundStyle(.secondary)
                                    #elseif os(iOS)
                                        Text("iOS")
                                            .foregroundStyle(.secondary)
                                    #endif
                                }
                            }
                        }
                        .padding()
                    }
                }
                .padding()
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)  // WWDC 2025: Let materials show through
    }
}

#Preview {
    SettingsView(settings: AppSettings())
}
