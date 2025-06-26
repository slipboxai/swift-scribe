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

    // Recording timer state
    @State var recordingStartTime: Date?
    @State var recordingDuration: TimeInterval = 0
    @State var recordingTimer: Timer?

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
        // Show enhanced view by default if summary exists
        showingEnhancedView = memo.summary.wrappedValue != nil
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Main content
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

                // Add padding at bottom for floating buttons
                #if os(iOS)
                    Spacer().frame(height: 100)
                #else
                    Spacer()
                #endif
            }
            #if os(macOS)
                .padding(20)
            #endif

            // Floating buttons at the bottom for iOS
            #if os(iOS)
                VStack {
                    Spacer()

                    bottomButtonBar
                }
                .ignoresSafeArea(.keyboard)
            #endif
        }
        .navigationTitle(memo.title)
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(isRecording)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 2) {
                        Text(memo.title)
                        .font(.headline)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .frame(maxWidth: 200)

                        if memo.isDone {
                            Text(memo.createdAt.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        #endif
        .toolbar {
            #if os(macOS)
                Group {
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
                }
            #endif
        }
        .onChange(of: isRecording) { oldValue, newValue in
            guard newValue != oldValue else { return }
            print("DEBUG [TranscriptView]: Recording state changed from \(oldValue) to \(newValue)")

            if newValue == true {
                print("DEBUG [TranscriptView]: Initiating recording start")
                // Start recording timer
                recordingStartTime = Date()
                recordingDuration = 0
                recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                    Task { @MainActor in
                        if let startTime = recordingStartTime {
                            recordingDuration = Date().timeIntervalSince(startTime)
                        }
                    }
                }

                // If restarting recording on an existing memo, reset the transcriber
                if memo.isDone {
                    memo.isDone = false
                    speechTranscriber.reset()
                    print("DEBUG [TranscriptView]: Reset transcriber for existing memo")
                }
                Task {
                    do {
                        try await recorder.record()
                        print("DEBUG [TranscriptView]: Recording started successfully")
                    } catch let error as TranscriptionError {
                        print(
                            "DEBUG [TranscriptView]: Recording failed with TranscriptionError: \(error.descriptionString)"
                        )
                        await MainActor.run {
                            isRecording = false
                            enhancementError = "Recording failed: \(error.descriptionString)"
                        }
                    } catch {
                        print("DEBUG [TranscriptView]: Recording failed with error: \(error)")
                        await MainActor.run {
                            isRecording = false
                            enhancementError = "Recording failed: \(error.localizedDescription)"
                        }
                    }
                }
            } else {
                print("DEBUG [TranscriptView]: Initiating recording stop")
                // Stop recording timer
                recordingTimer?.invalidate()
                recordingTimer = nil
                recordingStartTime = nil
                recordingDuration = 0

                Task {
                    do {
                        try await recorder.stopRecording()
                        print("DEBUG [TranscriptView]: Recording stopped successfully")
                        // Generate title and summary after recording stops
                        await generateTitleIfNeeded()
                        await generateAIEnhancements()
                    } catch {
                        print("DEBUG [TranscriptView]: Error stopping recording: \(error)")
                        await MainActor.run {
                            enhancementError =
                                "Error stopping recording: \(error.localizedDescription)"
                        }
                    }
                }
            }
        }
        .onChange(of: isPlaying) {
            handlePlayback()
        }
        .onAppear {
            // Connect the download progress
            if let progress = speechTranscriber.downloadProgress {
                let timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                    Task { @MainActor in
                        if progress.isFinished {
                            downloadProgress = 100.0
                        } else {
                            downloadProgress = progress.fractionCompleted * 100.0
                        }
                    }
                }

                // Store timer reference for cleanup
                Task { @MainActor in
                    // Auto-invalidate when progress is finished
                    while !progress.isFinished && timer.isValid {
                        try? await Task.sleep(nanoseconds: 500_000_000)  // 0.5 seconds
                    }
                    timer.invalidate()
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
        .onDisappear {
            // Clean up timers
            timer?.invalidate()
            timer = nil
            recordingTimer?.invalidate()
            recordingTimer = nil
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

    // MARK: - Bottom Button Bar for iOS

    #if os(iOS)
        @ViewBuilder
        private var bottomButtonBar: some View {
            HStack(spacing: 16) {
                // Recording/Stop button - always visible when recording
                if !memo.isDone {
                    recordButtonLarge
                } else {
                    // View toggle button (only show if summary exists)
                    if memo.summary != nil {
                        viewToggleButtonCompact
                    }

                    Spacer()

                    // AI enhance button
                    enhanceButtonCompact
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.clear)
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }

        @ViewBuilder
        private var recordButtonLarge: some View {
            Button {
                handleRecordingButtonTap()
            } label: {
                HStack(spacing: 12) {
                    Label(
                        isRecording ? "Stop Recording" : "Start Recording",
                        systemImage: isRecording ? "stop.circle.fill" : "record.circle.fill"
                    )
                    .font(.headline)
                    .fontWeight(.semibold)

                    if isRecording {
                        Text(formatDuration(recordingDuration))
                            .font(.headline)
                            .fontWeight(.semibold)
                            .monospacedDigit()
                    }
                }
            }
            .buttonStyle(.glass)
            .controlSize(.extraLarge)
            .tint(isRecording ? .red : Color(red: 0.36, green: 0.69, blue: 0.55))  // Green for start, red for stop
        }

        @ViewBuilder
        private var viewToggleButtonCompact: some View {
            Button {
                withAnimation(.smooth(duration: 0.3)) {
                    showingEnhancedView.toggle()
                }
            } label: {
                Label(
                    showingEnhancedView ? "Transcript" : "Summary",
                    systemImage: showingEnhancedView ? "doc.plaintext" : "sparkles"
                )
                .font(.body)
                .fontWeight(.medium)
            }
            .buttonStyle(.glass)
            .controlSize(.large)
            .tint(showingEnhancedView ? .gray : SpokenWordTranscriber.green)
        }

        @ViewBuilder
        private var enhanceButtonCompact: some View {
            Button {
                handleAIEnhanceButtonTap()
            } label: {
                if isGenerating {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Label(
                        memo.summary != nil ? "Re-summarize" : "Summarize with AI",
                        systemImage: memo.summary != nil ? "arrow.clockwise" : "sparkles"
                    )
                    .font(.body)
                    .fontWeight(.medium)
                }
            }
            .buttonStyle(.glass)
            .controlSize(.large)
            .tint(SpokenWordTranscriber.green)
            .disabled(memo.text.characters.isEmpty || isGenerating)
        }
    #endif

    // MARK: - Enhanced View

    @ViewBuilder
    private var enhancedView: some View {
        VStack(alignment: .leading, spacing: 0) {
            #if os(iOS)
                // Simplified header for iOS
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.body)
                        .foregroundStyle(SpokenWordTranscriber.green)

                    Text("AI Summary")
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            #endif

            #if os(macOS)
                // Header section with better spacing
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 12) {
                        Image(systemName: "sparkles")
                            .font(.title2)
                            .foregroundStyle(SpokenWordTranscriber.green)
                            .symbolRenderingMode(.monochrome)

                        Text("AI Enhanced Summary")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)

                        Spacer()
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
            #endif

            // Enhanced content area with better formatting
            Group {
                if let summary = memo.summary, !String(summary.characters).isEmpty {
                    ScrollView {
                        Text(summary)
                            .font(.body)
                            .lineSpacing(6)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            #if os(iOS)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                            #else
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                            #endif
                            .textSelection(.enabled)
                    }
                    #if os(macOS)
                        .padding(.horizontal, 16)
                    #endif
                    .scrollEdgeEffectStyle(.soft, for: .all)
                } else {
                    // Improved loading state
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.2)
                            .foregroundStyle(SpokenWordTranscriber.green)

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
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        #if os(macOS)
            .background(.background.secondary.opacity(0.3))
        #endif
    }

    // MARK: - Individual Toolbar Buttons

    @ViewBuilder
    private var playButton: some View {
        Button {
            handlePlayButtonTap()
        } label: {
            Label(
                isPlaying ? "Pause" : "Play",
                systemImage: isPlaying ? "pause.fill" : "play.fill"
            )
        }
        .buttonStyle(.glass)
    }

    @ViewBuilder
    private var recordButton: some View {
        Button {
            handleRecordingButtonTap()
        } label: {
            HStack(spacing: 8) {
                Label(
                    isRecording ? "Stop" : "Record",
                    systemImage: isRecording ? "stop.fill" : "record.circle"
                )

                if isRecording {
                    Text(formatDuration(recordingDuration))
                        .font(.body)
                        .monospacedDigit()
                }
            }
        }
        .tint(isRecording ? .red : Color(red: 0.36, green: 0.69, blue: 0.55))
    }

    @ViewBuilder
    private var viewToggleButton: some View {
        Button {
            withAnimation(.smooth(duration: 0.3)) {
                showingEnhancedView.toggle()
            }
        } label: {
            Label(
                showingEnhancedView ? "Transcript" : "Summary",
                systemImage: showingEnhancedView
                    ? "doc.plaintext.fill" : "sparkles.rectangle.stack.fill"
            )
        }
        .buttonStyle(.glass)
    }

    @ViewBuilder
    private var enhanceButton: some View {
        Button {
            handleAIEnhanceButtonTap()
        } label: {
            if isGenerating {
                ProgressView()
                    .controlSize(.small)
            } else {
                Label(
                    memo.summary != nil ? "Re-enhance" : "Enhance",
                    systemImage: memo.summary != nil ? "arrow.clockwise" : "sparkles"
                )
            }
        }
        .buttonStyle(.glass)
        .tint(SpokenWordTranscriber.green)
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

                            // Recording timer
                            Text(formatDuration(recordingDuration))
                                .font(.system(size: 32, weight: .medium, design: .monospaced))
                                .foregroundStyle(.primary)

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
                    #if os(iOS)
                        .padding(.top, 40)
                    #else
                        .padding()
                    #endif
                } else {
                    VStack(alignment: .leading, spacing: 16) {
                        // Live transcript with glass container
                        Text(
                            speechTranscriber.finalizedTranscript
                                + speechTranscriber.volatileTranscript
                        )
                        .font(.body)
                        .lineSpacing(4)
                        #if os(iOS)
                            .padding(.horizontal, 20)
                            .padding(.top, 12)
                        #else
                            .padding(20)
                        #endif
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
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                #if os(macOS)
                    Text("Transcript")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 12)
                #endif

                Text(memo.textBrokenUpByParagraphs())
                    .font(.body)
                    .lineSpacing(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    #if os(iOS)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    #else
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                    #endif
                    .textSelection(.enabled)
            }
        }
        .scrollEdgeEffectStyle(.soft, for: .all)
    }

    private var progressView: some View {
        ProgressView(value: downloadProgress, total: 100)
            .progressViewStyle(LinearProgressViewStyle())
            .opacity(downloadProgress > 0 && downloadProgress < 100 ? 1 : 0)
            .animation(.easeInOut(duration: 0.3), value: downloadProgress)
    }
}

// MARK: - TranscriptView Extension

extension TranscriptView {

    // Format duration for display
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    func handlePlayback() {
        guard memo.url != nil else {
            return
        }

        if isPlaying {
            Task {
                await recorder.playRecording()
            }
            timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
                Task { @MainActor in
                    currentPlaybackTime = recorder.playerNode?.currentTime ?? 0.0
                }
            }
        } else {
            Task {
                await recorder.stopPlaying()
            }
            currentPlaybackTime = 0.0
            timer = nil
        }
    }

    func handleRecordingButtonTap() {
        print("DEBUG [TranscriptView]: Recording button tapped - current state: \(isRecording)")
        isRecording.toggle()
        print("DEBUG [TranscriptView]: Recording state toggled to: \(isRecording)")
    }

    func handlePlayButtonTap() {
        isPlaying.toggle()
    }

    func handleAIEnhanceButtonTap() {
        Task {
            await generateAIEnhancements()
        }
    }

    @MainActor
    private func generateAIEnhancements() async {
        isGenerating = true
        enhancementError = nil

        do {
            try await memo.generateAIEnhancements()
            // Automatically show the enhanced view after successful generation
            withAnimation(.smooth(duration: 0.3)) {
                showingEnhancedView = true
            }
        } catch let error as FoundationModelsError {
            enhancementError = error.localizedDescription
        } catch {
            enhancementError = "Failed to generate AI enhancements: \(error.localizedDescription)"
        }

        isGenerating = false
    }

    @MainActor
    private func generateTitleIfNeeded() async {
        // Only generate title if we have content and the current title is generic
        guard !memo.text.characters.isEmpty,
            memo.title == "New Memo" || memo.title.isEmpty
        else {
            return
        }

        do {
            let suggestedTitle = try await memo.suggestedTitle() ?? memo.title
            memo.title = suggestedTitle
        } catch {
            print("Error generating title: \(error)")
            // Keep the existing title if generation fails
        }
    }

    @ViewBuilder func textScrollView(attributedString: AttributedString) -> some View {
        ScrollView {
            VStack(alignment: .leading) {
                textWithHighlighting(attributedString: attributedString)
                Spacer()
            }
        }
    }

    func attributedStringWithCurrentValueHighlighted(attributedString: AttributedString)
        -> AttributedString
    {
        var copy = attributedString
        copy.runs.forEach { run in
            if shouldBeHighlighted(attributedStringRun: run) {
                let range = run.range
                copy[range].backgroundColor = .mint.opacity(0.2)
            }
        }
        return copy
    }

    func shouldBeHighlighted(attributedStringRun: AttributedString.Runs.Run) -> Bool {
        guard isPlaying else { return false }
        let start = attributedStringRun.audioTimeRange?.start.seconds
        let end = attributedStringRun.audioTimeRange?.end.seconds
        guard let start, let end else {
            return false
        }

        if end < currentPlaybackTime { return false }

        if start < currentPlaybackTime, currentPlaybackTime < end {
            return true
        }

        return false
    }

    @ViewBuilder func textWithHighlighting(attributedString: AttributedString) -> some View {
        Group {
            Text(attributedStringWithCurrentValueHighlighted(attributedString: attributedString))
                .font(.body)
        }
    }
}
