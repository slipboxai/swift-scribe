/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The transcript view.
*/

import Foundation
import SwiftUI
import Speech
import AVFoundation

struct TranscriptView: View {
    @Binding var story: Story
    @State var isRecording = false
    @State var isPlaying = false
    
    @State var recorder: Recorder
    @State var speechTranscriber: SpokenWordTranscriber
    
    @State var downloadProgress = 0.0
    
    @State var currentPlaybackTime = 0.0
    
    @State var timer: Timer?
    
    init(story: Binding<Story>) {
        self._story = story
        let transcriber = SpokenWordTranscriber(story: story)
        recorder = Recorder(transcriber: transcriber, story: story)
        speechTranscriber = transcriber
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Group {
                if !story.isDone {
                    liveRecordingView
                } else {
                    playbackView
                }
            }
            Spacer()
        }
        .padding(20)
        .navigationTitle(story.title)
        .toolbar {
            ToolbarItem {
                Button {
                    handleRecordingButtonTap()
                } label: {
                    if isRecording {
                        Label("Stop", systemImage: "pause.fill").tint(.red)
                    } else {
                        Label("Record", systemImage: "record.circle").tint(.red)
                    }
                }
                .disabled(story.isDone)
            }
            
            ToolbarItem {
                Button {
                    handlePlayButtonTap()
                } label: {
                    Label("Play", systemImage: isPlaying ? "pause.fill" : "play").foregroundStyle(.blue).font(.title)
                }
                .disabled(!story.isDone)
            }
            
            ToolbarItem {
                ProgressView(value: downloadProgress, total: 100)
            }
            
        }
        .onChange(of: isRecording) { oldValue, newValue in
            guard newValue != oldValue else { return }
            if newValue == true {
                Task {
                    do {
                        try await recorder.record()
                    } catch {
                        print("could not record: \(error)")
                    }
                }
            } else {
                Task {
                    try await recorder.stopRecording()
                }
            }
        }
        .onChange(of: isPlaying) {
            handlePlayback()
        }
    }
    
    @ViewBuilder
    var liveRecordingView: some View {
        Text(speechTranscriber.finalizedTranscript + speechTranscriber.volatileTranscript)
            .font(.title)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    @ViewBuilder
    var playbackView: some View {
        textScrollView(attributedString: story.storyBrokenUpByLines())
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
