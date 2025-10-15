//
//  LiveTranscribeView.swift
//  LaunchCameraTranscriber
//
//  Created by Safra Soymat on 08/10/2025.
//

import SwiftUI
import AVFoundation
import Speech

struct LiveTranscribeView: View {
    @State var lecture: Lecture = Lecture.create()
    @State var isRecording = false
    @State var isPlaying = false

    @State private var recorder: AudioRecorder!
    @State private var speechTranscriber: LectureTranscriber!

    @State var downloadProgress = 0.0
    @State var currentPlaybackTime = 0.0
    @State var timer: Timer?

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // MARK: Buttons
            HStack {
                Button {
                    handleRecordingButtonTap()
                } label: {
                    Label(isRecording ? "Stop Recording" : "Start Recording",
                          systemImage: isRecording ? "stop.circle.fill" : "record.circle")
                        .font(.headline)
                }
                .buttonStyle(.borderedProminent)
                .tint(isRecording ? .red : .green)
                .keyboardShortcut(.space, modifiers: [])

                Button {
                    handlePlayButtonTap()
                } label: {
                    Label(isPlaying ? "Pause" : "Play", systemImage: isPlaying ? "pause.fill" : "play.fill")
                        .font(.headline)
                }
                .buttonStyle(.bordered)
                .tint(.blue)
            }
            .padding(.bottom, 10)

            // MARK: Transcript ScrollView with highlighting
            if let speechTranscriber {
                textScrollView(attributedString: speechTranscriber.finalizedTranscript + speechTranscriber.volatileTranscript)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
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
        .onAppear {
            if speechTranscriber == nil {
                let transcriber = LectureTranscriber(lecture: $lecture)
                let newRecorder = AudioRecorder(transcriber: transcriber, lecture: $lecture)
                speechTranscriber = transcriber
                recorder = newRecorder
            }
        }
        .onChange(of: isPlaying) { _ in
            handlePlayback()
        }
    }

    func handlePlayback() {
        guard lecture.file_url != nil else { return }

        if isPlaying {
            recorder.playRecording()
            timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
                currentPlaybackTime = recorder.playerNode?.currentTime ?? 0.0
            }
        } else {
            recorder.stopPlaying()
            currentPlaybackTime = 0.0
            timer?.invalidate()
            timer = nil
        }
    }

    func handleRecordingButtonTap() {
        if isRecording {
            Task {
                try await recorder.stopRecording()
                isRecording = false
            }
        } else {
            // Reset for new session
            let newTranscriber = LectureTranscriber(lecture: $lecture)
            let newRecorder = AudioRecorder(transcriber: newTranscriber, lecture: $lecture)
            speechTranscriber = newTranscriber
            recorder = newRecorder
            lecture.isDone = false
            lecture.transcript = ""

            Task {
                isRecording = true
                try await recorder.record()
            }
        }
    }

    func handlePlayButtonTap() {
        isPlaying.toggle()
    }

    // MARK: Text ScrollView + Highlighting
    @ViewBuilder
    func textScrollView(attributedString: AttributedString) -> some View {
        ScrollView {
            VStack(alignment: .leading) {
                textWithHighlighting(attributedString: attributedString)
                Spacer()
            }
            .padding()
        }
    }

    func attributedStringWithCurrentValueHighlighted(attributedString: AttributedString) -> AttributedString {
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
        guard let start, let end else { return false }
        return currentPlaybackTime >= start && currentPlaybackTime < end
    }

    @ViewBuilder
    func textWithHighlighting(attributedString: AttributedString) -> some View {
        Text(attributedStringWithCurrentValueHighlighted(attributedString: attributedString))
            .font(.title3)
            .textSelection(.enabled)
    }
}
