# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Swift Scribe is a privacy-first, AI-enhanced transcription application built exclusively for iOS 26/macOS 26+ using Apple's latest frameworks:

- **SpeechAnalyzer & SpeechTranscriber** - Real-time speech recognition with on-device processing
- **Foundation Models** - On-device AI for text generation, summarization, and enhancement
- **SwiftData** - Data persistence for memos and transcripts
- **SwiftUI** - Modern UI with rich text editing capabilities

## System Requirements

- **iOS 26 Beta or macOS 26 Beta** (REQUIRED - will not work on earlier versions)
- **Xcode Beta** with Swift 6.2+ toolchain
- **Apple Developer Account** with beta access
- **Microphone permissions** for speech input

## Build and Development Commands

### Opening the Project
```bash
open SlipboxScribe.xcodeproj
```

### Build Configuration
- The project uses Xcode's standard build system
- Build using Xcode Beta with Swift 6.2+ toolchain
- Deployment targets: iOS 26.0 and macOS 26.0
- Uses `Configuration/SampleCode.xcconfig` for build settings

### No Package Manager Dependencies
This project does not use Swift Package Manager, CocoaPods, or Carthage. All dependencies are Apple's first-party frameworks available in iOS 26/macOS 26.

## Code Architecture

### Core Structure
```
Scribe/
├── Audio/                    # Audio capture and processing
│   └── Recorder.swift       # AVAudioEngine-based recording
├── Transcription/           # Speech recognition pipeline  
│   └── Transcription.swift  # SpeechTranscriber integration
├── Models/                  # Data models and persistence
│   ├── MemoModel.swift     # SwiftData memo model with AI features
│   └── AppSettings.swift   # App configuration and themes
├── Views/                   # SwiftUI interface components
│   ├── ContentView.swift   # Main app interface
│   ├── SettingsView.swift  # App settings and preferences
│   └── TranscriptView.swift # Rich text transcript display
├── Helpers/                 # Utility classes and extensions
│   ├── FoundationModelsHelper.swift # AI text generation wrapper
│   ├── BufferConversion.swift       # Audio format conversion
│   └── Helpers.swift               # General utilities
└── ScribeApp.swift         # Main app entry point
```

### Key Components

#### Audio Pipeline (`Audio/Recorder.swift`)
- Uses `AVAudioEngine` for real-time audio capture
- Integrates with `SpokenWordTranscriber` for continuous transcription
- Handles microphone permissions and audio session management

#### Speech Recognition (`Transcription/Transcription.swift`)
- `SpokenWordTranscriber` class manages `SpeechAnalyzer` and `SpeechTranscriber`
- Supports real-time transcription with volatile and final results
- Handles model downloading and locale management
- Uses `BufferConverter` for audio format compatibility

#### AI Integration (`Models/MemoModel.swift` + `Helpers/FoundationModelsHelper.swift`)
- `Memo` model includes AI-generated titles and summaries using Foundation Models
- `FoundationModelsHelper` provides session management and error handling
- Supports structured output generation and context window recovery

#### Data Persistence
- Uses SwiftData for memo storage and management
- `Memo` model supports rich text with `AttributedString`
- Includes metadata like creation date, duration, and AI enhancements

## Development Guidelines

### Swift Language Features
- Built with Swift 6.2+ and uses modern concurrency (async/await)
- Extensive use of `@Observable` for state management
- SwiftData for Core Data replacement
- AttributedString for rich text handling

### AI and Speech Integration
- Foundation Models require iOS 26/macOS 26 for on-device processing
- SpeechTranscriber handles multiple locales with automatic model downloading
- Error handling for unsupported locales and network issues
- Session recovery for context window limitations

### UI Patterns
- SwiftUI-based with support for both iOS and macOS
- Rich text editing with AttributedString
- Settings integration using macOS Settings scene
- Color scheme management with system/light/dark options

## File Naming Conventions
- Swift files use PascalCase
- Main app entry point: `ScribeApp.swift`
- Models end with "Model": `MemoModel.swift`, `AppSettings.swift`
- Views end with "View": `ContentView.swift`, `SettingsView.swift`
- Helpers grouped in `Helpers/` directory with descriptive names

## Important Notes

### Framework Dependencies
All major functionality depends on iOS 26/macOS 26 frameworks:
- `Speech` framework for SpeechAnalyzer/SpeechTranscriber
- `FoundationModels` for on-device AI
- These are NOT available in iOS 25 or earlier

### Error Handling
- `TranscriptionError` enum for speech recognition errors
- `FoundationModelsError` enum for AI generation errors
- Proper async/await error propagation throughout

### Privacy and Permissions
- Requires microphone permissions (`NSMicrophoneUsageDescription`)
- All processing happens on-device (no network requests for AI)
- App Sandbox enabled with minimal permissions