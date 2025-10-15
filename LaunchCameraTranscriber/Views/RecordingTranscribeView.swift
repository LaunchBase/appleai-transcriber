//
//  RecordingTranscribeView.swift
//  LaunchCameraTranscriber
//
//  Created by Safra Soymat on 08/10/2025.
//

import SwiftUI
import AVFoundation

struct RecordingTranscribeView: View {
    @State private var lecture = Lecture.create()
    @State private var transcript: String = ""
    @State private var isTranscribing: Bool = false

    var body: some View {
        VStack(spacing: 20) {
            // Select file button
            Button("Select Audio/Video File") { selectFileAndTranscribe() }
                .buttonStyle(.borderedProminent)
                .disabled(isTranscribing)

            // Loading spinner while transcribing
            if isTranscribing {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(2)
                    .padding()
            }

            // Transcript scroll view (shown when transcription finishes)
            if !transcript.isEmpty {
                ScrollView {
                    Text(transcript)
                        .font(.title3)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
                .background(Color(NSColor.textBackgroundColor))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.3))
                )
            }

            Spacer()
        }
        .padding()
    }

    private func selectFileAndTranscribe() {
        let panel = NSOpenPanel()
        panel.allowedFileTypes = ["wav", "m4a", "mp3", "mp4"]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        if panel.runModal() == .OK, let url = panel.url {
            Task {
                await transcribeFile(url)
            }
        }
    }

    private func transcribeFile(_ url: URL) async {
        isTranscribing = true
        transcript = ""

        let lectureBinding = Binding.constant(lecture)
        let transcriber = LectureTranscriber(lecture: lectureBinding)

        do {
            try await transcriber.transcribeFile(url: url) { volatile, finalized, _ in
                Task { @MainActor in
                    // Update transcript in real-time
                    transcript = String(finalized.characters) + String(volatile.characters)
                }
            }

            // Done
            await MainActor.run {
                isTranscribing = false
            }
        } catch {
            await MainActor.run {
                transcript = "❌ Transcription failed: \(error.localizedDescription)"
                isTranscribing = false
            }
        }
    }
}

extension LectureTranscriber {

    /// Transcribe any supported audio/video file and provide live updates via closure
    func transcribeFile(
        url: URL,
        chunkSeconds: Double = 30,
        onUpdate: @escaping (_ volatile: AttributedString, _ finalized: AttributedString, _ progress: Double) -> Void
    ) async throws {
        
        // Prepare transcriber
        try await setup()
        
        let audioFile = try AVAudioFile(forReading: url)
        let format = audioFile.processingFormat
        let bufferCapacity = AVAudioFrameCount(format.sampleRate * chunkSeconds)
        
        // Stream audio in chunks
        while audioFile.framePosition < audioFile.length {
            guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: bufferCapacity) else { break }
            try audioFile.read(into: buffer)
            if buffer.frameLength == 0 { break }
            
            try await streamAudioToTranscriber(buffer)
            
            // Progress callback
            let progress = Double(audioFile.framePosition) / Double(audioFile.length)
            onUpdate(volatileTranscript, finalizedTranscript, progress)
        }
        
        try await finishTranscribing()
        onUpdate(volatileTranscript, finalizedTranscript, 1.0)
    }
}
