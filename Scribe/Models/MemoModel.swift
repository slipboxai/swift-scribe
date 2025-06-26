import AVFoundation
import Foundation
import FoundationModels
import SwiftData

@Model
class Memo {
    typealias StartTime = CMTime

    var title: String
    var text: AttributedString
    var url: URL?  // Audio file URL
    var isDone: Bool
    var createdAt: Date
    var duration: TimeInterval?

    // AI-enhanced content - now using AttributedString for rich formatting
    var summary: AttributedString?

    init(
        title: String, text: AttributedString, url: URL? = nil, isDone: Bool = false,
        duration: TimeInterval? = nil
    ) {
        self.title = title
        self.text = text
        self.url = url
        self.isDone = isDone
        self.duration = duration
        self.createdAt = Date()
        self.summary = nil
    }

    /// Generates an AI-enhanced title and summary, storing them persistently
    func generateAIEnhancements() async throws {
        guard SystemLanguageModel.default.isAvailable else {
            throw FoundationModelsError.generationFailed(
                NSError(domain: "Foundation Models not available", code: -1))
        }

        let transcriptText = String(text.characters)
        guard !transcriptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw FoundationModelsError.generationFailed(
                NSError(domain: "No content to enhance", code: -2))
        }

        // Generate enhanced title and summary concurrently
        let titleResult = try? await generateEnhancedTitle(from: transcriptText)
        let summaryResult = try? await generateRichSummary(from: transcriptText)

        // Update the memo with generated content
        self.title = titleResult ?? "New Note"
        self.summary = summaryResult ?? "Something went wrong generating a summary."
    }

    private func generateEnhancedTitle(from text: String) async throws -> String {
        let session = FoundationModelsHelper.createSession(
            instructions: """
                You are an expert at creating clear, descriptive titles for voice memos and transcripts.
                Your task is to create a concise, informative title that captures the main topic or purpose.

                Guidelines:
                - Keep titles between 3-8 words
                - Use title case (capitalize major words)
                - Focus on the main topic or key insight
                - Avoid generic words like memo or recording
                - Be specific and descriptive
                - Do not wrap the title in quotes
                """)

        let prompt =
            "Create a clear, descriptive title for this voice memo transcript (do not include quotes in your response):\n\n\(text)"

        let title = try await FoundationModelsHelper.generateText(
            session: session,
            prompt: prompt,
            options: FoundationModelsHelper.temperatureOptions(0.3)  // Low temperature for consistent titles
        )
        return title.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(
            of: "\"", with: "")
    }

    private func generateRichSummary(from text: String) async throws -> AttributedString {
        let session = FoundationModelsHelper.createSession(
            instructions: """
                You are an expert at creating concise, informative summaries of voice memos and transcripts.
                Your summaries should capture the key points, main topics, and important details.

                Guidelines:
                - Create 2-4 well-structured paragraphs
                - Include key points and important details
                - Mark important concepts or key terms that should be highlighted
                - Output in markdown format
                """)

        let prompt = "Create a comprehensive summary of this voice memo transcript:\n\n\(text)"
        let summaryText = try await FoundationModelsHelper.generateText(
            session: session,
            prompt: prompt,
            options: FoundationModelsHelper.temperatureOptions(0.4)
        )

        // Convert to AttributedString
        return try AttributedString(markdown: summaryText)
    }

    // Legacy method for backward compatibility
    func suggestedTitle() async throws -> String? {
        return try await generateEnhancedTitle(from: String(text.characters))
    }

    // Legacy method for backward compatibility - now returns AttributedString
    func summarize(using template: String) async throws -> AttributedString? {
        return try await generateRichSummary(from: String(text.characters))
    }
}

extension Memo {
    static func blank() -> Memo {
        return .init(title: "New Memo", text: AttributedString(""))
    }

    func textBrokenUpByParagraphs() -> AttributedString {
        print(String(text.characters))
        if url == nil {
            print("url was nil")
            return text
        } else {
            var final = AttributedString("")
            var working = AttributedString("")
            let copy = text
            copy.runs.forEach { run in
                if copy[run.range].characters.contains(".") {
                    working.append(copy[run.range])
                    final.append(working)
                    final.append(AttributedString("\n\n"))
                    working = AttributedString("")
                } else {
                    if working.characters.isEmpty {
                        let newText = copy[run.range].characters
                        let attributes = run.attributes
                        let trimmed = newText.trimmingPrefix(" ")
                        let newAttributed = AttributedString(trimmed, attributes: attributes)
                        working.append(newAttributed)
                    } else {
                        working.append(copy[run.range])
                    }
                }
            }

            if final.characters.isEmpty {
                return working
            }

            return final
        }
    }
}
