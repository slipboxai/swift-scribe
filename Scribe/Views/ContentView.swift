import Speech
import SwiftData
import SwiftUI

struct ContentView: View {
    @Query(sort: \Memo.createdAt, order: .reverse) private var memos: [Memo]
    @State var selection: Memo?
    @State var currentMemo: Memo = Memo.blank()
    @State private var showingSettings = false
    @State private var isRecording = false  // Track recording state globally
    @Environment(AppSettings.self) private var settings
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                ForEach(memos) { memo in
                    NavigationLink(value: memo) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(LocalizedStringKey(memo.title))
                                .font(.headline)
                            Text(memo.createdAt.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if !memo.text.characters.isEmpty {
                                Text(
                                    String(memo.text.characters.prefix(50))
                                        + (memo.text.characters.count > 50 ? "..." : "")
                                )
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                            }
                        }
                    }
                }
                .onDelete(perform: deleteMemos)
            }
            .navigationTitle("Memos")
            .navigationSplitViewColumnWidth(min: 250, ideal: 250, max: 400)
            .toolbar {
                #if os(iOS)
                    // Group primary actions together
                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        if !memos.isEmpty {
                            EditButton()
                        }

                        if !isRecording {
                            Button {
                                addMemo()
                            } label: {
                                Label("New Memo", systemImage: "plus")
                            }
                        }

                        Button {
                            showingSettings = true
                        } label: {
                            Label("Settings", systemImage: "gearshape")
                        }
                    }
                #elseif os(macOS)
                    // On macOS, settings are in the app menu, so only show the Add button
                    ToolbarItemGroup(placement: .primaryAction) {
                        if !memos.isEmpty && selection != nil {
                            Button {
                                if let selection = selection {
                                    deleteMemo(selection)
                                }
                            } label: {
                                Label("Delete Memo", systemImage: "trash")
                            }
                            .foregroundColor(.red)
                        }

                        if !isRecording {
                            Button {
                                addMemo()
                            } label: {
                                Label("New Memo", systemImage: "plus")
                            }
                        }
                    }
                #endif
            }
            .toolbarBackground(.hidden)
        } detail: {
            if selection != nil {
                TranscriptView(memo: $currentMemo, isRecording: $isRecording)
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

    private func addMemo() {
        let newMemo = Memo.blank()
        modelContext.insert(newMemo)
        selection = newMemo
        currentMemo = newMemo
    }

    private func deleteMemos(offsets: IndexSet) {
        for index in offsets {
            deleteMemo(memos[index])
        }
    }

    private func deleteMemo(_ memo: Memo) {
        if selection == memo {
            selection = nil
        }
        modelContext.delete(memo)
    }
}
