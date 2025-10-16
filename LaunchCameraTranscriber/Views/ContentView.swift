import SwiftUI
import Speech

struct ContentView: View {
    @State private var showLiveTranscription = false
    @State private var showRecordingTranscription = false
    
    var body: some View {
        ZStack {
            // MARK: Background Color
            Color("mp-purple")
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                if showLiveTranscription {
                    LiveTranscribeView {
                        showLiveTranscription = false
                    }
                } else if showRecordingTranscription {
                    RecordingTranscribeView {
                        showRecordingTranscription = false
                    }
                } else {
                    mainMenu
                }
            }
            .frame(minWidth: 600, minHeight: 500)
            .padding(.horizontal, 60)
            .padding(.vertical, 40)
        }
    }
    
    // MARK: Main Menu
    var mainMenu: some View {
        VStack(spacing: 36) {
            Spacer()
            
            // MARK: Logo
            Image("habitatlearn_logo")
                .resizable()
                .scaledToFit()
                .frame(width: 160)
                .padding(.bottom, 10)
                .shadow(radius: 6)
            
            // MARK: Title
            VStack(spacing: 8) {
                // Title uses PP Woodland Bold
                Text("Apple Intelligence Speech Transcriber")
                    .font(.custom("PPWoodland-Bold", size: 34))
                    .foregroundColor(.white)

                // Subtitle uses standard system font
                Text("Empowering learners through accessible AI transcription.")
                    .font(.custom("Manrope", size: 18))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            // MARK: Buttons
            HStack(spacing: 24) {
                TranscribeButton(
                    title: "Transcribe a Recording",
                    systemImage: "waveform",
                    action: { showRecordingTranscription = true }
                )
                
                TranscribeButton(
                    title: "Live Transcription",
                    systemImage: "mic.fill",
                    action: { showLiveTranscription = true }
                )
            }
            .padding(.top, 10)
            
            Spacer()
            
            // MARK: Footer
            VStack(spacing: 4) {
                Text("Powered by Habitat Learn")
                    .font(.custom("Manrope", size: 12))
                    .foregroundColor(.white.opacity(0.7))
                
                Text("© \(Calendar.current.component(.year, from: Date())) Habitat Learn Inc. All rights reserved.")
                    .font(.custom("Manrope", size: 10))
                    .foregroundColor(.white.opacity(0.4))
            }
        }
    }
}

// MARK: Custom Button for macOS
struct TranscribeButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.title2.weight(.medium))
                Text(title)
                    .font(.custom("Manrope", size: 16))
            }
            .frame(width: 240, height: 56)
            .background(
                RoundedRectangle(cornerRadius: 18)
                .fill(Color("gainsboro"))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
            .foregroundColor(.white)
            .shadow(color: .black.opacity(0.3), radius: isHovering ? 10 : 6, x: 0, y: 3)
            .scaleEffect(isHovering ? 1.03 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isHovering)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            self.isHovering = hovering
        }
    }
}

#Preview {
    ContentView()
}
