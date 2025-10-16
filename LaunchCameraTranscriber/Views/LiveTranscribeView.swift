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
            
            // MARK: Description / Instructions
            Text("Press 'Start Recording' to record your lecture. Once finished, press 'Stop Recording'. You can replay the recording using 'Play'. The transcription will appear below in real-time.")
                .font(.custom("Manrope", size: 14))
                .foregroundColor(.white.opacity(0.8))
                .padding(.top, 4)
                .padding(.bottom, 12)
                .frame(maxWidth: .infinity)
            
            // MARK: Controls
            HStack(spacing: 24) {
                SolidButton(
                    title: isRecording ? "Stop Recording" : "Start Recording",
                    systemImage: isRecording ? "stop.circle.fill" : "record.circle",
                    bgColor: isRecording ? Color(.burntsienna) : Color(.seaGreen),
                    textColor: .white,
                    action: handleRecordingButtonTap
                )
                
                SolidButton(
                    title: isPlaying ? "Stop" : "Play",
                    systemImage: isPlaying ? "stop.fill" : "play.fill",
                    bgColor: isPlaying ? Color(.burntsienna) : .white,
                    textColor: isPlaying ? .white : .black,
                    action: handlePlayButtonTap,
                    isDisabled: isRecording
                )
            }
            .padding(.bottom, 10)
            
            // MARK: Transcript ScrollView
            if let speechTranscriber {
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(splitTranscriptionIntoLines(speechTranscriber.finalizedTranscript + speechTranscriber.volatileTranscript), id: \.self) { line in
                            Text(attributedStringWithCurrentValueHighlighted(line))
                                .font(.custom("Manrope", size: 16))
                                .foregroundColor(.white)
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
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
    func attributedStringWithCurrentValueHighlighted(_ attributedString: AttributedString) -> AttributedString {
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
}
