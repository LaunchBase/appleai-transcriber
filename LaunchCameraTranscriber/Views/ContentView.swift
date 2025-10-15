//
//  ContentView.swift
//  LaunchCameraTranscriber
//
//  Created by Safra Soymat on 08/10/2025.
//

import SwiftUI
import Speech

struct ContentView: View {
    @State private var showLiveTranscription = false
    @State private var showRecordingTranscription = false
    
    var body: some View {
        VStack(spacing: 32) {
            if showLiveTranscription {
                LiveTranscribeView()
            } else if showRecordingTranscription {
                RecordingTranscribeView()
            } else {
                mainMenu
            }
        }
        .frame(minWidth: 600, minHeight: 400)
        .padding()
    }
    
    // MARK: - Main Menu
    var mainMenu: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Text("LaunchCamera Transcriber")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
            
            Text("Choose how you’d like to transcribe")
                .font(.title3)
                .foregroundStyle(.secondary)
            
            HStack(spacing: 24) {
                Button {
                    showRecordingTranscription = true
                } label: {
                    Label("Transcribe a Recording", systemImage: "waveform")
                        .frame(width: 200, height: 50)
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                
                Button {
                    showLiveTranscription = true
                } label: {
                    Label("Live Transcription", systemImage: "mic.fill")
                        .frame(width: 200, height: 50)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            }
            
            Spacer()
        }
    }
}
