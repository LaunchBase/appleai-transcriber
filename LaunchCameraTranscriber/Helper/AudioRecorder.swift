//
//  AudioRecorder.swift
//  LaunchCameraTranscriber
//
//  Created by Safra Soymat on 08/10/2025.
//

import Foundation
import AVFoundation
import SwiftUI

class AudioRecorder {
    private var outputContinuation: AsyncStream<AVAudioPCMBuffer>.Continuation? = nil
    private let audioEngine: AVAudioEngine
    private let transcriber: LectureTranscriber
    var playerNode: AVAudioPlayerNode?
    
    var lecture: Binding<Lecture>
    
    var file: AVAudioFile?
    private let file_url: URL

    init(transcriber: LectureTranscriber, lecture: Binding<Lecture>) {
        audioEngine = AVAudioEngine()
        self.transcriber = transcriber
        self.lecture = lecture
        self.file_url = FileManager.default.temporaryDirectory
            .appending(component: UUID().uuidString)
            .appendingPathExtension(for: .wav)
    }
    
    func record() async throws {
        self.lecture.file_url.wrappedValue = file_url
        guard await isAuthorized() else {
            print("user denied mic permission")
            return
        }

        try await transcriber.setup()
                
        for await input in try await audioStream() {
            try await self.transcriber.streamAudioToTranscriber(input)
        }
    }
    
    func stopRecording() async throws {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        
        playerNode?.stop()
        playerNode = nil
        
        lecture.isDone.wrappedValue = true
        try await transcriber.finishTranscribing()
    }
    
    func pauseRecording() {
        audioEngine.pause()
    }
    
    func resumeRecording() throws {
        try audioEngine.start()
    }
    
    private func audioStream() async throws -> AsyncStream<AVAudioPCMBuffer> {
        try setupAudioEngine()
        audioEngine.inputNode.installTap(onBus: 0,
                                         bufferSize: 4096,
                                         format: audioEngine.inputNode.outputFormat(forBus: 0)) { [weak self] (buffer, time) in
            guard let self else { return }
            writeBufferToDisk(buffer: buffer)
            self.outputContinuation?.yield(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        
        return AsyncStream(AVAudioPCMBuffer.self, bufferingPolicy: .unbounded) {
            continuation in
            outputContinuation = continuation
        }
    }
    
    private func setupAudioEngine() throws {
        let inputSettings = audioEngine.inputNode.inputFormat(forBus: 0).settings
        self.file = try AVAudioFile(forWriting: file_url,
                                    settings: inputSettings)
        
        audioEngine.inputNode.removeTap(onBus: 0)
    }
        
    func playRecording() {
        guard let file else {
            return
        }
        
        playerNode = AVAudioPlayerNode()
        guard let playerNode else {
            return
        }
        
        audioEngine.attach(playerNode)
        audioEngine.connect(playerNode,
                            to: audioEngine.outputNode,
                            format: file.processingFormat)
        
        playerNode.scheduleFile(file,
                                at: nil,
                                completionCallbackType: .dataPlayedBack) { _ in
        }
        
        do {
            try audioEngine.start()
            playerNode.play()
        } catch {
            print("error")
        }
    }
    
    func stopPlaying() {
        audioEngine.stop()
    }
}

// Ask for permission to access the microphone.
extension AudioRecorder {
    func isAuthorized() async -> Bool {
        if AVCaptureDevice.authorizationStatus(for: .audio) == .authorized {
            return true
        }
        
        return await AVCaptureDevice.requestAccess(for: .audio)
    }
    
    func writeBufferToDisk(buffer: AVAudioPCMBuffer) {
        do {
            try self.file?.write(from: buffer)
        } catch {
            print("File writing error: \(error)")
        }
    }
}

