# Swift Scribe - AI-Powered Speech-to-Text Private Transcription App for iOS 26 & macOS 26+

> **Real-time voice transcription, on-device AI processing, and intelligent note-taking exclusively for iOS 26 & macOS 26 and above**

Uses Apple's new Foundation Model Framework and SpeechTranscriber. Requires macOS 26 to run and compile the project. The goal is to demonstrate how easy it is now to build local, AI-first apps.

## 🎯 Overview

**Swift Scribe** is a privacy-first, AI-enhanced transcription application built exclusively for iOS 26/macOS 26+ that transforms spoken words into organized, searchable notes. Using Apple's latest SpeechAnalyzer and SpeechTranscriber frameworks (available only in iOS 26/macOS 26+) combined with on-device Foundation Models, it delivers real-time speech recognition, intelligent content analysis, and advanced text editing capabilities.


![Swift Scribe Demo - AI Speech-to-Text Transcription](Docs/swift-scribe.gif)

![Swift Scribe Demo - AI Speech-to-Text Transcription iOS](Docs/phone-scribe.gif)

## 🛠 Technical Requirements & Specifications

### **System Requirements**
- **iOS 26 Beta or newer** (REQUIRED - will not work on iOS 25 or earlier)
- **macOS 26 Beta or newer** (REQUIRED - will not work on macOS 25 or earlier)  
- **Xcode Beta** with latest Swift 6.2+ toolchain
- **Swift 6.2+** programming language
- **Apple Developer Account** with beta access to iOS 26/macOS 26
- **Microphone permissions** for speech input


## 🚀 Installation & Setup Guide

### **Development Installation**

1. **Clone the repository:**

   ```bash
   git clone https://github.com/seamlesscompute/swift-scribe
   cd swift-scribe
   ```

2. **Open in Xcode Beta:**

   ```bash
   open SwiftScribe.xcodeproj
   ```

3. **Configure deployment targets** for iOS 26 Beta/macOS 26 Beta or newer

4. **Build and run** using Xcode Beta with Swift 6.2+ toolchain

⚠️ **Note**: Ensure your device is running iOS 26+ or macOS 26+ before installation.

## 📋 Use Cases & Applications

**Transform your workflow with AI-powered transcription:**

### **Business & Professional**
- 📊 **Meeting transcription** and automated minute generation
- 📝 **Interview recording** with speaker identification
- 💼 **Business documentation** and report creation
- 🎯 **Sales call analysis** and follow-up automation

### **Healthcare & Medical**
- 🏥 **Medical dictation** and clinical documentation
- 👨‍⚕️ **Patient interview transcription** with medical terminology
- 📋 **Healthcare report generation** and chart notes
- 🔬 **Research interview analysis** and coding

### **Education & Academic**
- 🎓 **Lecture transcription** with chapter segmentation
- 📚 **Study note creation** from audio recordings
- 🔍 **Research interview analysis** with theme identification
- 📖 **Language learning** with pronunciation feedback

### **Legal & Compliance**
- ⚖️ **Court proceeding transcription** with timestamp accuracy
- 📑 **Deposition recording** and legal documentation
- 🏛️ **Legal research** and case note compilation
- 📋 **Compliance documentation** and audit trails

### **Content Creation & Media**
- 🎙️ **Podcast transcription** and show note generation
- 🎬 **Video content scripting** with speaker identification
- ✍️ **Article writing** from voice recordings
- 📺 **Content creation workflows** and production notes

### **Accessibility & Inclusion**
- 🦻 **Real-time captions** for hearing-impaired users
- 🗣️ **Speech accessibility tools** with customizable formatting
- 🌐 **Multi-language accessibility** support
- 🎯 **Assistive technology integration**

## 🏗 Project Architecture & Code Structure

```
Scribe/                     # Core application logic and modules
├── Audio/                  # Audio capture, processing, and management
├── Transcription/         # SpeechAnalyzer and SpeechTranscriber implementation
├── AI/                    # Foundation Models integration and AI processing
├── Views/                 # SwiftUI interface with rich text editing
├── Models/                # Data models for memos, transcription, and AI
├── Storage/               # Local data persistence and model management
└── Extensions/            # Swift extensions and utilities
```

**Key Components:**

- **Audio Engine** - Real-time audio capture and preprocessing
- **Speech Pipeline** - SpeechAnalyzer integration and transcription flow
- **AI Processing** - Foundation Models for content analysis
- **Rich Text System** - AttributedString and advanced formatting
- **Data Layer** - Core Data integration and local storage

## 🗺 Development Roadmap & Future Features

### **Phase 1: Core Enhancement**

- ✅ Real-time speech transcription
- ✅ On-device AI processing
- ✅ Rich text editing
- 🔄 Enhanced accuracy improvements

### **Phase 2: Advanced Features** 

- 🎯 **Speaker diarization** and voice identification
- 🔊 **Output audio tap** for system audio capture
- 🌐 **Enhanced multi-language** support
- 📊 **Advanced analytics** and insights

## 📄 License & Legal

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for complete details.

## 🙏 Acknowledgments & Credits

- **Apple WWDC 2025** sessions on SpeechAnalyzer, Foundation Models, and Rich Text editing
- **Apple Developer Frameworks** - SpeechAnalyzer, Foundation Models, Rich Text Editor

## 🚀 Getting Started with AI Development Tools

**For Cursor & Windsurf IDE users:** Leverage AI agents to explore the comprehensive documentation in the `Docs/` directory, featuring complete WWDC 2025 session transcripts covering:

- 🎤 **SpeechAnalyzer & SpeechTranscriber** API implementation guides
- 🤖 **Foundation Models** framework integration
- ✏️ **Rich Text Editor** advanced capabilities  
- 🔊 **Audio processing** improvements and optimizations

---

**⭐ Star this repo** if you find it useful! | **🔗 Share** with developers interested in AI-powered speech transcription
