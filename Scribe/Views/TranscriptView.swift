import AVFoundation
import Foundation
import Speech
import SwiftUI

struct TranscriptView: View {
    @Binding var memo: Memo
    @State var isRecording = false
    @State var isPlaying = false
    @State var isGenerating = false

    @State var recorder: Recorder
    @State var speechTranscriber: SpokenWordTranscriber

    @State var downloadProgress = 0.0

    @State var currentPlaybackTime = 0.0

    @State var timer: Timer?

    // AI-generated content state
    @State var showingSummary = false
    @State var generatedSummary = ""

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
        .toolbar {
            Group {
                #if os(iOS)
                    ToolbarItem(placement: .navigationBarLeading) {
                        playbackControlsGroup
                    }

                    ToolbarItem(placement: .principal) {
                        recordingControlsGroup
                    }

                    ToolbarItem(placement: .navigationBarTrailing) {
                        aiControlsGroup
                    }
                #else
                    ToolbarItem {
                        aiControlsGroup
                    }

                    ToolbarSpacer(.fixed)

                    ToolbarItem {
                        recordingControlsGroup
                    }

                    ToolbarSpacer(.fixed)
                    ToolbarItem {
                        playbackControlsGroup
                    }
                    ToolbarSpacer(.fixed)

                #endif
            }
        }
        .onChange(of: isRecording) { oldValue, newValue in
            guard newValue != oldValue else { return }
            if newValue == true {
                Task {
                    do {
                        try await recorder.record()
                    } catch {
                        print("DEBUG: could not record: \(error)")
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
        .onAppear {
            // Connect the download progress
            if let progress = speechTranscriber.downloadProgress {
                Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
                    if progress.isFinished {
                        timer.invalidate()
                        downloadProgress = 100.0
                    } else {
                        downloadProgress = progress.fractionCompleted * 100.0
                    }
                }
            }

            // Auto-start recording if there's no existing transcript
            if !memo.isDone && speechTranscriber.finalizedTranscript.utf8.isEmpty
                && speechTranscriber.volatileTranscript.utf8.isEmpty
            {
                isRecording = true
            }
        }
        #if os(iOS)
            .sheet(isPresented: $showingSettings) {
                SettingsView(settings: settings)
            }
        #endif
        .sheet(isPresented: $showingSummary) {
            NavigationView {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("AI-Generated Summary")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text(generatedSummary)
                            .font(.body)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding()
                }
                .navigationTitle(memo.title)
                #if os(iOS)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showingSummary = false
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                #endif
            }
        }
    }

    // MARK: - Toolbar Groups

    @ViewBuilder
    private var playbackControlsGroup: some View {
        if memo.isDone {
            Button {
                handlePlayButtonTap()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.headline)
                        .symbolRenderingMode(.monochrome)
                        .foregroundStyle(.blue)

                    Text(isPlaying ? "Pause" : "Play")
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                }
            }
        }
    }

    @ViewBuilder
    private var recordingControlsGroup: some View {
        Button {
            handleRecordingButtonTap()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: isRecording ? "stop.fill" : "record.circle")
                    .font(.headline)
                    .symbolRenderingMode(.monochrome)
                    .foregroundStyle(isRecording ? .red : .primary)

                Text(isRecording ? "Stop" : "Record")
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundStyle(isRecording ? .red : .primary)
            }
        }
        .disabled(memo.isDone)
    }

    @ViewBuilder
    private var aiControlsGroup: some View {
        if memo.isDone {
            Button {
                handleAIEnhanceButtonTap()
            } label: {
                HStack(spacing: 8) {
                    if isGenerating {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "sparkles")
                            .font(.headline)
                            .symbolRenderingMode(.monochrome)
                            .foregroundStyle(.purple)
                    }
                    Text("Enhance")
                        .font(.headline)
                        .fontWeight(.medium)
                }
            }
            .disabled(memo.text.characters.isEmpty || isGenerating)
        }
    }

    @ViewBuilder
    var liveRecordingView: some View {
        ScrollView {
            VStack(alignment: .leading) {

                if speechTranscriber.finalizedTranscript.utf8.isEmpty
                    && speechTranscriber.volatileTranscript.utf8.isEmpty
                {
                    VStack(spacing: 20) {
                        // Recording indicator with glass effect
                        VStack(spacing: 12) {
                            Image(systemName: "mic.fill")
                                .font(.system(size: 48))
                                .foregroundStyle(.red)
                                .symbolEffect(.pulse, isActive: isRecording)

                            Text("Listening...")
                                .font(.title2)
                                .fontWeight(.medium)
                                .foregroundStyle(.primary)

                            Text("Start speaking into the microphone")
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.vertical, 32)
                        .padding(.horizontal, 24)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                } else {
                    VStack(alignment: .leading, spacing: 16) {
                        // Live transcript with glass container
                        Text(
                            speechTranscriber.finalizedTranscript
                                + speechTranscriber.volatileTranscript
                        )
                        .font(.body)
                        .lineSpacing(4)
                        .padding(20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                Spacer()
            }
        }
        .scrollEdgeEffectStyle(.soft, for: .all)
    }

    @ViewBuilder
    var playbackView: some View {
        textScrollView(attributedString: memo.textBrokenUpByParagraphs())
            .frame(maxWidth: .infinity, alignment: .center)
            .scrollEdgeEffectStyle(.soft, for: .all)
    }

    private var progressView: some View {
        ProgressView(value: downloadProgress, total: 100)
            .progressViewStyle(LinearProgressViewStyle())
            .opacity(downloadProgress > 0 && downloadProgress < 100 ? 1 : 0)
            .animation(.easeInOut(duration: 0.3), value: downloadProgress)
    }
}
