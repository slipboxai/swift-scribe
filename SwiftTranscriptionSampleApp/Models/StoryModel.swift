/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Story data model.
*/

import Foundation
import AVFoundation
import FoundationModels

@Observable
class Story: Identifiable {
    typealias StartTime = CMTime
    
    let id: UUID
    var title: String
    var text: AttributedString
    var url: URL?
    var isDone: Bool
    
    init(title: String, text: AttributedString, url: URL? = nil, isDone: Bool = false) {
        self.title = title
        self.text = text
        self.url = url
        self.isDone = isDone
        self.id = UUID()
    }
    
    func suggestedTitle() async throws -> String? {
        guard SystemLanguageModel.default.isAvailable else { return nil }
        let session = LanguageModelSession(model: SystemLanguageModel.default)
        let answer = try await session.respond(to: "Here is a children's story. Can you please return your very best suggested title for it, with no other text? The title should be descriptive of the story and include the main character's name. Story: \(text.characters)")
        return answer.content.trimmingCharacters(in: .punctuationCharacters)
    }
}

extension Story {
    static func blank() -> Story {
        return .init(title: "New Story", text: AttributedString(""))
    }
    
    func storyBrokenUpByLines() -> AttributedString {
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
