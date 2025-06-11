import Speech
import SwiftData
import SwiftUI

struct ContentView: View {
    @State var selection: Memo?
    @State var currentMemo: Memo = Memo.blank()
    @State private var showingSettings = false
    @Environment(AppSettings.self) private var settings

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                ForEach(memos, id: \.id) { memo in
                    NavigationLink(value: memo) {
                        Text(memo.title)
                    }
                }
            }
            .navigationTitle("Memos")
            .toolbar {
                #if os(iOS)
                    // Group primary actions together
                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        Button {
                            memos.append(Memo.blank())
                        } label: {
                            Label("Add Item", systemImage: "plus")
                        }

                        Button {
                            showingSettings = true
                        } label: {
                            Label("Settings", systemImage: "gearshape")
                        }
                    }
                #elseif os(macOS)
                    // On macOS, settings are in the app menu, so only show the Add button
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            memos.append(Memo.blank())
                        } label: {
                            Label("Add Item", systemImage: "plus")
                        }
                    }
                #endif
            }
            .toolbarBackground(.hidden)
        } detail: {
            if selection != nil {
                TranscriptView(memo: $currentMemo)
            } else {
                Text("Select an item")
            }
        }
        .onChange(of: selection) {
            if let selection {
                currentMemo = selection
            }
        }
        #if os(iOS)
            .sheet(isPresented: $showingSettings) {
                SettingsView(settings: settings)
            }
        #endif
    }

    @State var memos: [Memo] = []
}
