# Apple Intelligence Speech Transcriber

**Apple Intelligence Speech Transcriber** is a **macOS prototype app** that demonstrates Apple’s speech intelligence frameworks for recording, playing back, and transcribing audio and video files. It provides **live transcription**, line-by-line transcript display, and playback highlighting for improved readability and interaction.

---
## Requirements

- **macOS 26+ (Tahoe)** or later.
- **Xcode 26+**.
- Microphone access permissions enabled.

---

## Features

### Live Transcription
- Record audio directly from the microphone.
- Transcribe in real-time with live updates.
- Highlight words during playback.
- Replay recordings with synced word-level highlights.

### File Transcription
- Upload audio or video files (`wav`, `m4a`, `mp3`, `mp4`) for transcription.
- Transcripts are split **sentence by sentence**, preserving punctuation.
- Shows progress indicator while transcription is ongoing.

---

## Installation

1. Clone the repository

2. Open LaunchCameraTranscriber.xcodeproj in Xcode.

3. Build and run the app on your Mac.

--- 

## Usage

### Live Transcription

1. Open the app.

2. Press Start Recording to capture audio.

3. Press Stop Recording when finished. The transcript appears in real-time.

4. Press Play to replay the recording with word-level highlighting.

### File Transcription

1. Press Select Audio/Video File.

2. Choose a supported media file.

3. Wait for transcription to complete.

4. The transcript appears line by line, preserving punctuation.

---

### Dependencies

- SwiftUI – UI components.

- AVFoundation – Audio recording and playback.

- Speech – Apple speech recognition framework.
