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
    }

    func suggestedTitle() async throws -> String? {
        guard SystemLanguageModel.default.isAvailable else { return nil }
        let session = LanguageModelSession(model: SystemLanguageModel.default)
        let answer = try await session.respond(
            to:
                "Here is a transcribed voice memo. Can you please return your very best suggested title for it, with no other text? The title should be descriptive and concise. Transcription: \(text.characters)"
        )
        return answer.content.trimmingCharacters(in: .punctuationCharacters)
    }

    func summarize(using template: String) async throws -> String? {
        guard SystemLanguageModel.default.isAvailable else { return nil }
        let session = LanguageModelSession(model: SystemLanguageModel.default)
        let answer = try await session.respond(
            to:
                "Please summarize the following transcribed voice memo using this format/template: \(template)\n\nTranscription: \(text.characters)"
        )
        return answer.content
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
