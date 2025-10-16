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
    var onBack: () -> Void
    
    @State var lecture: Lecture = Lecture.create()
    @State var isRecording = false
    @State var isPlaying = false

    @State private var recorder: AudioRecorder!
    @State private var speechTranscriber: LectureTranscriber!

    @State var currentPlaybackTime = 0.0
    @State var timer: Timer?

    var body: some View {
        VStack(spacing: 20) {
            
            // MARK: Top Bar with Back Button
            HStack {
                BackButton(action: onBack)
                Spacer()
            }

            // MARK: Title
            Text("Live Transcription")
                .font(.custom("PPWoodland-Bold", size: 28))
                .foregroundColor(.white)
                .padding(.top, 8)
            
            // MARK: Control Buttons
            HStack(spacing: 24) {
                // Recording Button
                SolidButton(
                    title: isRecording ? "Stop Recording" : "Start Recording",
                    systemImage: isRecording ? "stop.circle.fill" : "record.circle",
                    bgColor: isRecording ? .red : .green, // use bgColor
                    action: handleRecordingButtonTap
                )
                
                // Play Button (disabled while recording)
                SolidButton(
                    title: isPlaying ? "Stop" : "Play",
                    systemImage: isPlaying ? "stop.fill" : "play.fill",
                    bgColor: .blue, // must match struct param name
                    action: handlePlayButtonTap,
                    isDisabled: isRecording // disables while recording
                )
            }

            .padding(.bottom, 10)

            // MARK: Transcript ScrollView
            // MARK: Transcript ScrollView
            if let speechTranscriber {
                ScrollView {
                    VStack(alignment: .leading, spacing: 6) { // spacing between lines
                        let fullTranscript = speechTranscriber.finalizedTranscript + speechTranscriber.volatileTranscript
                        let lines = splitAttributedStringIntoLines(fullTranscript)

                        ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                            Text(line)
                                .font(.custom("Manrope", size: 16))
                                .foregroundColor(.white)
                                .lineSpacing(4)
                                .textSelection(.enabled)
                        }
                    }
                    .padding()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color("gainsboro"))
                .cornerRadius(18)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
            }
            Spacer()
        }
        .padding()
        .background(Color("mp-purple").ignoresSafeArea())
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

    // MARK: Playback / Recording
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

    // MARK: Text Highlighting
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
            .font(.custom("Manrope", size: 16))
            .foregroundColor(.black)
            .textSelection(.enabled)
    }
}

// MARK: Back Button
struct BackButton: View {
    var title: String = "Back"
    var systemImage: String = "chevron.left"
    var action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                Text(title)
                    .font(.custom("PPWoodland-Bold", size: 14))
            }
            .padding(8)
            .frame(minWidth: 80)
            .background(Color.white)
            .foregroundColor(.black)
            .cornerRadius(12)
            .shadow(color: .black.opacity(isHovering ? 0.3 : 0.2), radius: isHovering ? 8 : 6, x: 0, y: 3)
            .scaleEffect(isHovering ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isHovering)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            self.isHovering = hovering
        }
    }
}

// MARK: Solid Button with optional disabled state
struct SolidButton: View {
    let title: String
    let systemImage: String
    let bgColor: Color
    let action: () -> Void
    var isDisabled: Bool = false   // NEW
    
    @State private var isHovering = false

    var body: some View {
        Button(action: {
            if !isDisabled {
                action()
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                Text(title)
                    .font(.custom("Manrope", size: 16))
            }
            .padding()
            .frame(width: 200, height: 50)
            .background(isDisabled ? Color.gray : bgColor)
            .foregroundColor(.white.opacity(isDisabled ? 0.7 : 1.0))
            .cornerRadius(18)
            .shadow(color: .black.opacity(isHovering ? 0.3 : 0.2), radius: isHovering ? 8 : 6, x: 0, y: 3)
            .scaleEffect(isHovering && !isDisabled ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isHovering)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            self.isHovering = hovering
        }
        .disabled(isDisabled)
    }
}
