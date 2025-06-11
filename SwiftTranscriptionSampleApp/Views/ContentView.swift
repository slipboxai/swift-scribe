/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The app's main view.
*/

import SwiftUI
import SwiftData
import Speech

struct ContentView: View {
    @State var selection: Story?
    @State var currentStory: Story = Story.blank()
    
    var body: some View {
        NavigationSplitView {
            List(stories, selection: $selection) { story in
                NavigationLink(value: story) {
                    Text(story.title)
                }
            }
            
            .navigationTitle("Stories")
            
            .toolbar {
                ToolbarItem {
                    Button {
                        stories.append(Story.blank())
                    } label: {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
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
    }
    
    @State var stories: [Story] = []
}
