import AVFoundation
import Foundation
import Speech
import SwiftUI

struct TranscriptView: View {
    @Binding var memo: Memo
    @State var isRecording = false
    @State var isPlaying = false

    @State var recorder: Recorder
    @State var speechTranscriber: SpokenWordTranscriber

    @State var downloadProgress = 0.0

    @State var currentPlaybackTime = 0.0

    @State var timer: Timer?

    init(memo: Binding<Memo>) {
        self._memo = memo
        let transcriber = SpokenWordTranscriber(memo: memo)
        recorder = Recorder(transcriber: transcriber, memo: memo)
        speechTranscriber = transcriber
    }

    var body: some View {
        VStack(alignment: .leading) {
            Group {
                if !memo.isDone {
                    liveRecordingView
                } else {
                    playbackView
                }
            }
            Spacer()
        }
        .padding(20)
        .navigationTitle(memo.title)
        .toolbarBackground(.hidden)
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
                .disabled(memo.isDone)
            }

            ToolbarItem {
                Button {
                    handlePlayButtonTap()
                } label: {
                    Label("Play", systemImage: isPlaying ? "pause.fill" : "play").foregroundStyle(
                        .blue
                    ).font(.title)
                }
                .disabled(!memo.isDone)
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
        textScrollView(attributedString: memo.textBrokenUpByParagraphs())
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

