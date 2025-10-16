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
    @State private var transcript: AttributedString = ""
    @State private var isTranscribing: Bool = false

    var onBack: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // MARK: Top Bar (always visible)
            HStack {
                BackButton(action: onBack)
                Spacer()
            }
            .padding()
            .background(Color("mp-purple"))
            
            ScrollView {
                VStack(spacing: 32) {
                    // MARK: Header Section
                    VStack(spacing: 8) {
                        Text("Transcribe a Recording")
                            .font(.custom("PPWoodland-Bold", size: 26))
                            .foregroundColor(.white)
                        
                        Text("Upload an audio or video file to generate a transcript.")
                            .font(.custom("Manrope", size: 15))
                            .foregroundColor(.white.opacity(0.85))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .padding(.top, 20)
                    
                    // MARK: File Upload Section
                    VStack(spacing: 20) {
                        TranscribeButton(
                            title: "Select Audio/Video File",
                            systemImage: "waveform",
                            action: selectFileAndTranscribe
                        )
                        .disabled(isTranscribing)
                        .opacity(isTranscribing ? 0.6 : 1.0)

                        if isTranscribing {
                            VStack(spacing: 10) {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(1)
                                    .padding(.bottom, 8)
                                    .padding(.top, 8)
                                Text("Transcribing in progress…")
                                    .font(.custom("Manrope", size: 14))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            .padding(.top, 8)
                        }
                    }
                    .padding(.top, 10)
                    
                    // MARK: Transcript Section
                    if !transcript.characters.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Generated Transcript")
                                .font(.custom("Manrope-SemiBold", size: 18))
                                .foregroundColor(.white.opacity(0.9))
                            
                            ScrollView {
                                VStack(alignment: .leading, spacing: 6) {
                                    ForEach(splitTranscriptionIntoLines(transcript), id: \.self) { line in
                                        Text(line)
                                            .font(.custom("Manrope", size: 16))
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                }
                                .padding()
                                .background(Color("gainsboro"))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                                )
                                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                                .lineSpacing(8)
                            }
                            .frame(minHeight: 300)
                            .padding(.top, 5)
                        }
                        .padding(.horizontal)
                    }
                    
                    Spacer(minLength: 20)
                }
                .padding(.bottom, 30)
            }
            .background(Color("mp-purple").ignoresSafeArea())
        }
    }

    // MARK: File selection
    private func selectFileAndTranscribe() {
        let panel = NSOpenPanel()
        panel.allowedFileTypes = ["wav", "m4a", "mp3", "mp4"]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        if panel.runModal() == .OK, let url = panel.url {
            Task { await transcribeFile(url) }
        }
    }

    // MARK: Transcription
    private func transcribeFile(_ url: URL) async {
        isTranscribing = true
        transcript = ""

        let lectureBinding = Binding.constant(lecture)
        let transcriber = LectureTranscriber(lecture: lectureBinding)

        do {
            try await transcriber.transcribeFile(url: url) { volatile, finalized, _ in
                Task { @MainActor in
                    transcript = finalized + volatile
                }
            }
            await MainActor.run {
                isTranscribing = false
            }
        } catch {
            await MainActor.run {
                transcript = AttributedString("❌ Transcription failed: \(error.localizedDescription)")
                isTranscribing = false
            }
        }
    }
}
