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
        showingEnhancedView = memo.summary.wrappedValue != nil
    }

    var body: some View {
        VStack(alignment: .leading) {
            Group {
                if !memo.isDone {
                    liveRecordingView
                } else {
                    if memo.summary != nil && showingEnhancedView {
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
                    // Playback control
                    if memo.isDone {
                        ToolbarItem(placement: .navigationBarLeading) {
                            playButton
                        }
                    }

                    // Recording control
                    if !memo.isDone {
                        ToolbarItem(placement: .principal) {
                            recordButton
                        }
                    }

                    // AI controls
                    if memo.isDone {
                        // View toggle button
                        if memo.summary != nil {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                viewToggleButton
                            }
                        }

                        // Enhance button
                        ToolbarItem(placement: .navigationBarTrailing) {
                            enhanceButton
                        }
                    }
                #else
                    // AI controls
                    if memo.isDone {
                        // Enhance button
                        ToolbarItem {
                            enhanceButton
                        }

                        // View toggle button
                        if memo.summary != nil {
                            ToolbarItem {
                                viewToggleButton
                            }
                        }
                    }

                    ToolbarSpacer(.fixed)

                    // Recording control
                    if !memo.isDone {
                        ToolbarItem {
                            recordButton
                        }
                    }

                    ToolbarSpacer(.fixed)

                    // Playback control
                    if memo.isDone {
                        ToolbarItem {
                            playButton
                        }
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
        VStack(alignment: .leading, spacing: 0) {
            // Header section with better spacing
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.title2)
                        .foregroundStyle(.purple)
                        .symbolRenderingMode(.monochrome)

                    Text("AI Enhanced Summary")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)

                    Spacer()
                }

                Text("Tap to edit and refine")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 16)

            // Enhanced content area with better formatting
            if memo.summary != nil {
                ScrollView {
                    TextEditor(
                        text: Binding(
                            get: {
                                // Format the summary with proper paragraph breaks
                                memo.summary ?? ""
                            },
                            set: { memo.summary = $0 }
                        )
                    )
                    .font(.body)
                    .lineSpacing(6)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .frame(minHeight: 300)
                }
                .padding(.horizontal, 16)
                .scrollEdgeEffectStyle(.soft, for: .all)
            } else {
                // Improved loading state
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.2)
                        .foregroundStyle(.purple)

                    VStack(spacing: 8) {
                        Text("Generating enhanced summary...")
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)

                        Text("This may take a moment")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(.background.secondary.opacity(0.3))
    }

    // MARK: - Individual Toolbar Buttons

    @ViewBuilder
    private var playButton: some View {
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
        .buttonStyle(.glass)
    }

    @ViewBuilder
    private var recordButton: some View {
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

    @ViewBuilder
    private var viewToggleButton: some View {
        Button {
            withAnimation(.smooth(duration: 0.3)) {
                showingEnhancedView.toggle()
            }
        } label: {
            HStack(spacing: 6) {
                Image(
                    systemName: showingEnhancedView
                        ? "sparkles.rectangle.stack.fill" : "doc.plaintext.fill"
                )
                .font(.system(size: 15, weight: .medium))
                .symbolRenderingMode(.monochrome)
                .foregroundStyle(.purple)

                Text(showingEnhancedView ? "Transcript" : "Summary")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
        }
        .buttonStyle(.glass)
    }

    @ViewBuilder
    private var enhanceButton: some View {
        Button {
            handleAIEnhanceButtonTap()
            withAnimation(.smooth(duration: 0.3)) {
                showingEnhancedView = true
            }
        } label: {
            HStack(spacing: 6) {
                if isGenerating {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(.white)
                } else {
                    Image(systemName: memo.summary != nil ? "arrow.clockwise" : "sparkles")
                        .font(.system(size: 15, weight: .medium))
                        .symbolRenderingMode(.monochrome)
                        .foregroundStyle(.purple)
                }

                Text(memo.summary != nil ? "Re-enhance" : "Enhance")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
        }
        .buttonStyle(.glass)
        .disabled(memo.text.characters.isEmpty || isGenerating)
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

            ScrollView {
                Text(memo.textBrokenUpByParagraphs())
                    .font(.body)
                    .lineSpacing(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .textSelection(.enabled)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private var progressView: some View {
        ProgressView(value: downloadProgress, total: 100)
            .progressViewStyle(LinearProgressViewStyle())
            .opacity(downloadProgress > 0 && downloadProgress < 100 ? 1 : 0)
            .animation(.easeInOut(duration: 0.3), value: downloadProgress)
    }
}
