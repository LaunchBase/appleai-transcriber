//
//  LectureTranscriber.swift
//  LaunchCameraTranscriber
//
//  Created by Safra Soymat on 07/10/2025.
//

import Foundation
import Speech
import SwiftUI

@Observable
final class LectureTranscriber{
    private var inputSequence: AsyncStream<AnalyzerInput>?
    private var inputBuilder: AsyncStream<AnalyzerInput>.Continuation?
    private var transcriber: SpeechTranscriber?
    private var analyzer: SpeechAnalyzer?
    private var recognizerTask: Task<(), Error>?
    
    // Audio Format
    var analyzerFormat: AVAudioFormat?
    
    var converter = AudioConverter()
    var downloadProgress: Progress?
        
    var lecture: Binding<Lecture>
    
    var volatileTranscript: AttributedString = "" //short prediction
    var finalizedTranscript: AttributedString = "" //final prediction
    
    var locale = Locale(components: .init(languageCode: .english, script: nil, languageRegion: .canada))
    
    init(lecture: Binding<Lecture>) {
        self.lecture = lecture
    }
    
    func setup() async throws {
        
        /*
         
             SpeechTranscriber Class: Creates a general-purpose transcriber.
                    init(locale: Locale,
                         transcriptionOptions: Set<SpeechTranscriber.TranscriptionOption>,
                         reportingOptions: Set<SpeechTranscriber.ReportingOption>,
                         attributeOptions: Set<SpeechTranscriber.ResultAttributeOption>)
                - Configuring transcription
                    - transcriptionOptions = Options relating to the text of the transcription
                        1. etiquetteReplacements = Replaces certain words and phrases with a redacted form.
                    - ReportingOption = Options relating to the transcriber’s result delivery.
                        1. alternativeTranscriptions = Includes alternative transcriptions in addition to the most likely transcription.
                        2. fastResults= Biases the transcriber towards responsiveness, yielding faster but also less accurate results.
                        3. volatileResults = Provides tentative results for an audio range in addition to the finalized result.
                    - ResultAttributeOption = Options relating to the attributes of the transcription.
                        1. audioTimeRange = Includes time-code attributes in a transcription’s attributed string.
                        2. transcriptionConfidence = Includes confidence attributes in a transcription’s attributed string.
         
         */
        
        transcriber = SpeechTranscriber(locale: locale,
                                        transcriptionOptions: [],
                                        reportingOptions: [.volatileResults],
                                        attributeOptions: [.audioTimeRange])
        
        guard let transcriber else{
            throw TranscriptionError.faledToSetupRecognitionStream
        }
        
        // Analyzes spoken audio content in various ways and manages the analysis session.
        analyzer = SpeechAnalyzer(modules: [transcriber])
        
        do{
            try await checkModel(transcriber: transcriber, locale: locale)
        } catch let e as TranscriptionError {
            print(e)
            return
        }
        
        self.analyzerFormat = await SpeechAnalyzer.bestAvailableAudioFormat(compatibleWith: [transcriber])
        
        (inputSequence, inputBuilder) = AsyncStream<AnalyzerInput>.makeStream()
        
        guard let inputSequence else {return}
        
        recognizerTask = Task {
            do{
                for try await case let result in transcriber.results {
                    let text = result.text
                    if result.isFinal {
                        finalizedTranscript += text
                        volatileTranscript = ""
                        updateLectureWithNewTranscript(withFinal: text)

                    } else{
                        volatileTranscript = text
                    }
                }
            } catch {
                print ("Speech recognition failed")
            }
        }
        
        try await analyzer?.start(inputSequence: inputSequence)
    }
    
    func updateLectureWithNewTranscript(withFinal str: AttributedString) {
        lecture.transcript.wrappedValue.append(str)
    }

    
    func streamAudioToTranscriber(_ buffer: AVAudioPCMBuffer) async throws {
        guard let inputBuilder, let analyzerFormat else {
            throw TranscriptionError.invalidAudioDataType
        }
        
        let converted = try self.converter.convertBuffer(buffer, to: analyzerFormat)
        let input = AnalyzerInput(buffer: converted)
        
        inputBuilder.yield(input)
    }
    
    public func finishTranscribing() async throws {
        inputBuilder?.finish()
        try await analyzer?.finalizeAndFinishThroughEndOfInput()
        recognizerTask?.cancel()
        recognizerTask = nil

        // Convert AttributedString to plain String
        let fullTranscript = String(finalizedTranscript.characters) + String(volatileTranscript.characters)

        let transcriptURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath) .appendingPathComponent("transcript.txt")
        
        do {
            try fullTranscript.write(to: transcriptURL, atomically: true, encoding: String.Encoding.utf8)
            print("✅ Transcript saved to \(transcriptURL.path)")
        } catch {
            print("❌ Failed to save transcript: \(error)")
        }
    }
    
    /// Transcribes an audio/video file and provides live updates via closure.
   func transcribeFile(
       url: URL,
       chunkSeconds: Double = 30,
       onUpdate: @escaping (_ volatile: AttributedString, _ finalized: AttributedString, _ progress: Double) -> Void
   ) async throws {
       // Prepare the transcriber
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
           
           // Progress
           let progress = Double(audioFile.framePosition) / Double(audioFile.length)
           onUpdate(volatileTranscript, finalizedTranscript, progress)
       }
       
       // Finish transcription
       try await finishTranscribing()
       
       // Final update
       onUpdate(volatileTranscript, finalizedTranscript, 1.0)
   }
    public func checkModel(transcriber: SpeechTranscriber, locale: Locale) async throws{
        guard await checkSupportedLocale(locale: locale) else {
            throw TranscriptionError.localeNotSupported
        }
        
        if await checkInstalledLocale(locale: locale) {
            print("Your locale is already installed on the device")
            return
        } else{
            print("Downloading your locale to the device")
            try await downloadLocaleForSpeechModel(for: transcriber)
        }
        
    }
    
    // Check if the specified locale is supported by Apple Intelligence
    func checkSupportedLocale(locale: Locale) async -> Bool {
        let supported = await Set(SpeechTranscriber.supportedLocales)
        return supported.map{ $0.identifier(.bcp47)}.contains(locale.identifier(.bcp47))
    }
    
    // Check if the specified locale is installed on the device
    func checkInstalledLocale(locale: Locale) async -> Bool {
        let installed = await Set(SpeechTranscriber.installedLocales)
        return installed.map{ $0.identifier(.bcp47)}.contains(locale.identifier(.bcp47))
    }
    
    // Download the locale model specified in the SpeechTranscriber
    func downloadLocaleForSpeechModel(for module: SpeechTranscriber) async throws {
        if let downloader = try await
            AssetInventory.assetInstallationRequest(supporting: [module]) {
            self.downloadProgress = downloader.progress
            try await downloader.downloadAndInstall()
        }
    }

}
