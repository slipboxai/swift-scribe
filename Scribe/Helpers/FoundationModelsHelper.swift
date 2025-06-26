import Foundation
import FoundationModels

/// A helper class for working with Foundation Models framework
/// Provides convenient methods for text generation, structured output, and session management
class FoundationModelsHelper {

    // MARK: - Session Management

    /// Creates a new session with custom instructions
    /// - Parameter instructions: The system instructions for the session
    /// - Returns: A configured LanguageModelSession
    static func createSession(instructions: String) -> LanguageModelSession {
        return LanguageModelSession(instructions: instructions)
    }

    /// Creates a session with tools
    /// - Parameters:
    ///   - instructions: The system instructions for the session
    ///   - tools: Array of tools to make available to the session
    /// - Returns: A configured LanguageModelSession with tools
    static func createSession<T: Tool>(instructions: String, tools: [T]) -> LanguageModelSession {
        return LanguageModelSession(tools: tools, instructions: instructions)
    }

    // MARK: - Text Generation

    /// Generate text response with automatic error handling
    /// - Parameters:
    ///   - session: The language model session
    ///   - prompt: The user prompt
    ///   - options: Optional generation options for controlling sampling
    /// - Returns: Generated text content
    /// - Throws: FoundationModelsError for handled errors
    static func generateText(
        session: LanguageModelSession,
        prompt: String,
        options: GenerationOptions? = nil
    ) async throws -> String {
        do {
            let response: LanguageModelSession.Response<String>
            if let options = options {
                response = try await session.respond(to: prompt, options: options)
            } else {
                response = try await session.respond(to: prompt)
            }
            return response.content
        } catch LanguageModelSession.GenerationError.exceededContextWindowSize {
            throw FoundationModelsError.contextWindowExceeded
        } catch LanguageModelSession.GenerationError.unsupportedLanguageOrLocale {
            throw FoundationModelsError.unsupportedLanguage
        } catch {
            throw FoundationModelsError.generationFailed(error)
        }
    }

    /// Generate structured output using Generable types
    /// - Parameters:
    ///   - session: The language model session
    ///   - prompt: The user prompt
    ///   - type: The Generable type to generate
    ///   - options: Optional generation options
    /// - Returns: An instance of the specified Generable type
    /// - Throws: FoundationModelsError for handled errors
    static func generateStructured<T: Generable>(
        session: LanguageModelSession,
        prompt: String,
        generating type: T.Type,
        options: GenerationOptions? = nil
    ) async throws -> T {
        do {
            let response: LanguageModelSession.Response<T>
            if let options = options {
                response = try await session.respond(to: prompt, generating: type, options: options)
            } else {
                response = try await session.respond(to: prompt, generating: type)
            }
            return response.content
        } catch LanguageModelSession.GenerationError.exceededContextWindowSize {
            throw FoundationModelsError.contextWindowExceeded
        } catch LanguageModelSession.GenerationError.unsupportedLanguageOrLocale {
            throw FoundationModelsError.unsupportedLanguage
        } catch {
            throw FoundationModelsError.generationFailed(error)
        }
    }

    // MARK: - Session Recovery

    /// Recover from context window exceeded error by creating a new session with condensed transcript
    /// - Parameters:
    ///   - previousSession: The session that exceeded context window
    ///   - keepLastEntries: Number of last entries to keep (default: 1)
    /// - Returns: A new session with condensed transcript
    static func recoverSession(
        from previousSession: LanguageModelSession,
        keepLastEntries: Int = 1
    ) -> LanguageModelSession {
        let transcript = previousSession.transcript
        let allEntries = Array(transcript) 
        var condensedEntries = [Transcript.Entry]()

        // Always keep the first entry (instructions)
        if let firstEntry = allEntries.first {
            condensedEntries.append(firstEntry)

            // Keep the specified number of last entries
            if allEntries.count > 1 {
                let startIndex = max(1, allEntries.count - keepLastEntries)
                let lastEntries = Array(allEntries[startIndex...])
                condensedEntries.append(contentsOf: lastEntries)
            }
        }

        let condensedTranscript = Transcript(entries: condensedEntries)
        return LanguageModelSession(transcript: condensedTranscript)
    }

    // MARK: - Language Support

    /// Check if the current locale is supported by Foundation Models
    /// - Returns: True if the current locale is supported
    static func isCurrentLocaleSupported() -> Bool {
        let supportedLanguages = SystemLanguageModel.default.supportedLanguages
        return supportedLanguages.contains(Locale.current.language)
    }

    /// Get all supported languages
    /// - Returns: Array of supported languages
    static func getSupportedLanguages() -> [Locale.Language] {
        return Array(SystemLanguageModel.default.supportedLanguages)
    }

    // MARK: - Generation Options Helpers

    /// Create generation options for deterministic output
    /// - Returns: GenerationOptions configured for greedy sampling
    static func deterministicOptions() -> GenerationOptions {
        return GenerationOptions(sampling: .greedy)
    }

    /// Create generation options with custom temperature
    /// - Parameter temperature: Temperature value (0.0 for deterministic, higher for more creative)
    /// - Returns: GenerationOptions with specified temperature
    static func temperatureOptions(_ temperature: Double) -> GenerationOptions {
        return GenerationOptions(temperature: temperature)
    }

    // MARK: - Convenience Methods

    /// Simple text generation with automatic session creation and error handling
    /// - Parameters:
    ///   - prompt: The user prompt
    ///   - instructions: System instructions (optional)
    ///   - deterministic: Whether to use deterministic generation (default: false)
    /// - Returns: Generated text
    /// - Throws: FoundationModelsError
    static func quickGenerate(
        prompt: String,
        instructions: String? = nil,
        deterministic: Bool = false
    ) async throws -> String {
        let session = LanguageModelSession(
            instructions: instructions ?? "You are a helpful assistant."
        )

        let options = deterministic ? deterministicOptions() : nil
        return try await generateText(session: session, prompt: prompt, options: options)
    }
}

// MARK: - Error Types

/// Custom error types for Foundation Models operations
enum FoundationModelsError: LocalizedError {
    case contextWindowExceeded
    case unsupportedLanguage
    case generationFailed(any Error)

    var errorDescription: String? {
        switch self {
        case .contextWindowExceeded:
            return "The conversation has become too long. Please start a new session."
        case .unsupportedLanguage:
            return "The current language or locale is not supported by Foundation Models."
        case .generationFailed(let error):
            return "Failed to generate content: \(error.localizedDescription)"
        }
    }
}

// MARK: - Session State Manager

/// Helper class for managing multiple sessions and their state
class FoundationModelsSessionManager {
    private var sessions: [String: LanguageModelSession] = [:]

    /// Get or create a session with the given ID
    /// - Parameters:
    ///   - id: Unique identifier for the session
    ///   - instructions: Instructions for new sessions
    /// - Returns: The session for the given ID
    func getSession(id: String, instructions: String? = nil) -> LanguageModelSession {
        if let existingSession = sessions[id] {
            return existingSession
        }

        let newSession = LanguageModelSession(
            instructions: instructions ?? "You are a helpful assistant."
        )
        sessions[id] = newSession
        return newSession
    }

    /// Remove a session
    /// - Parameter id: The session ID to remove
    func removeSession(id: String) {
        sessions.removeValue(forKey: id)
    }

    /// Handle context window exceeded by creating a new session
    /// - Parameters:
    ///   - id: The session ID
    ///   - keepLastEntries: Number of last entries to keep
    /// - Returns: The new recovered session
    func recoverSession(id: String, keepLastEntries: Int = 1) -> LanguageModelSession? {
        guard let oldSession = sessions[id] else { return nil }

        let newSession = FoundationModelsHelper.recoverSession(
            from: oldSession,
            keepLastEntries: keepLastEntries
        )
        sessions[id] = newSession
        return newSession
    }

    /// Clear all sessions
    func clearAllSessions() {
        sessions.removeAll()
    }

    /// Get the number of active sessions
    var sessionCount: Int {
        return sessions.count
    }
}
