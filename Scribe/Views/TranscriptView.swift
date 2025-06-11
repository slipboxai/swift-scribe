import AVFoundation
import Foundation
import Speech
import SwiftUI

struct TranscriptView: View {
    @Binding var memo: Memo
    @Binding var isRecording: Bool
    @State var isPlaying = false
    @State var isGenerating = false

    @State var recorder: Recorder
    @State var speechTranscriber: SpokenWordTranscriber

    @State var downloadProgress = 0.0

    @State var currentPlaybackTime = 0.0

    @State var timer: Timer?

    // AI enhancement state
    @State var showingEnhancedView = false
    @State var enhancementError: String?
    @State var isEditingSummary = false

    init(memo: Binding<Memo>, isRecording: Binding<Bool>) {
        self._memo = memo
        self._isRecording = isRecording
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
                    if showingEnhancedView && memo.summary != nil {
                        enhancedView
                    } else {
                        playbackView
                    }
                }
            }
            Spacer()
        }
        .padding(20)
        .navigationTitle(memo.title)  // Just use the regular title field
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
                // If restarting recording on an existing memo, reset the transcriber
                if memo.isDone {
                    memo.isDone = false
                    speechTranscriber.reset()
                }
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
            if !memo.isDone && memo.text.characters.isEmpty {
                // Reset transcriber to ensure clean state
                speechTranscriber.reset()
                // Use a small delay to ensure the view is fully loaded
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    isRecording = true
                }
            }
        }
        .alert("Enhancement Error", isPresented: .constant(enhancementError != nil)) {
            Button("OK") {
                enhancementError = nil
            }
        } message: {
            if let error = enhancementError {
                Text(error)
            }
        }
    }

    // MARK: - Enhanced View

    @ViewBuilder
    private var enhancedView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("AI Summary")
                .font(.headline)
                .foregroundStyle(.secondary)

            // Editable TextEditor that takes up full available space
            if let summary = memo.summary {
                TextEditor(
                    text: Binding(
                        get: { memo.summary ?? "" },
                        set: { memo.summary = $0 }
                    )
                )
                .font(.body)
                .scrollContentBackground(.hidden)
                .clipShape(RoundedRectangle(cornerRadius: 12))
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
        if !memo.isDone {
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
        }
    }

    @ViewBuilder
    private var aiControlsGroup: some View {
        if memo.isDone {
            HStack(spacing: 8) {
                // View toggle button (only show if we have AI content)
                if memo.summary != nil {
                    Button {
                        showingEnhancedView.toggle()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: showingEnhancedView ? "doc.plaintext" : "sparkles")
                                .font(.headline)
                                .symbolRenderingMode(.monochrome)
                                .foregroundStyle(showingEnhancedView ? .secondary : Color.purple)

                            Text(showingEnhancedView ? "Transcript" : "Enhanced")
                                .font(.headline)
                                .fontWeight(.medium)
                        }
                    }
                }

                // Enhance/Re-enhance button
                Button {
                    handleAIEnhanceButtonTap()
                } label: {
                    HStack(spacing: 6) {
                        if isGenerating {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .scaleEffect(0.8)
                        } else {
                            Image(
                                systemName: memo.summary != nil ? "arrow.clockwise" : "sparkles"
                            )
                            .font(.headline)
                            .symbolRenderingMode(.monochrome)
                            .foregroundStyle(.purple)
                        }

                        Text(memo.summary != nil ? "Re-enhance" : "Enhance")
                            .font(.headline)
                            .fontWeight(.medium)
                    }
                }
                .disabled(memo.text.characters.isEmpty || isGenerating)
            }
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
        VStack(alignment: .leading, spacing: 16) {
            Text("Transcript")
                .font(.headline)
                .foregroundStyle(.secondary)

            TextEditor(text: .constant(memo.textBrokenUpByParagraphs()))
                .font(.body)
                .scrollContentBackground(.hidden)
                .background(.clear)
                .disabled(true)  // Read-only for now
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .scrollEdgeEffectStyle(.soft, for: .all)
    }

    private var progressView: some View {
        ProgressView(value: downloadProgress, total: 100)
            .progressViewStyle(LinearProgressViewStyle())
            .opacity(downloadProgress > 0 && downloadProgress < 100 ? 1 : 0)
            .animation(.easeInOut(duration: 0.3), value: downloadProgress)
    }
}
