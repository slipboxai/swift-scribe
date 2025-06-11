import Speech
import SwiftData
import SwiftUI

struct ContentView: View {
    @State var selection: Story?
    @State var currentStory: Story = Story.blank()
    @State private var showingSettings = false
    @Environment(AppSettings.self) private var settings

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                ForEach(stories, id: \.id) { story in
                    NavigationLink(value: story) {
                        Text(story.title)
                    }
                }
            }
            .navigationTitle("Stories")
            .toolbar {
                #if os(iOS)
                    // Group primary actions together
                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        Button {
                            stories.append(Story.blank())
                        } label: {
                            Label("Add Item", systemImage: "plus")
                        }

                        // Add toolbar spacer to separate settings from primary actions
                        ToolbarSpacer(.fixed(16))

                        Button {
                            showingSettings = true
                        } label: {
                            Label("Settings", systemImage: "gearshape")
                        }
                        .navigationZoomTransitionSource(tag: "settings", in: settingsNamespace)
                    }
                #elseif os(macOS)
                    // On macOS, settings are in the app menu, so only show the Add button
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            stories.append(Story.blank())
                        } label: {
                            Label("Add Item", systemImage: "plus")
                        }
                    }
                #endif
            }
            .toolbarBackground(.hidden)
        } detail: {
            if selection != nil {
                TranscriptView(story: $currentStory)
            } else {
                Text("Select an item")
            }
        }
        .onChange(of: selection) {
            if let selection {
                currentStory = selection
            }
        }
        #if os(iOS)
            .sheet(isPresented: $showingSettings) {
                SettingsView(settings: settings)
                .navigationZoomTransitionDestination(tag: "settings", in: settingsNamespace)
            }
        #endif
    }

    @State var stories: [Story] = []
    #if os(iOS)
        @Namespace private var settingsNamespace
    #endif
}
