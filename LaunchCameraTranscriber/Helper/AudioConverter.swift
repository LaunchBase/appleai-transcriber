//
//  AudioConverter.swift
//  LaunchCameraTranscriber
//
//  Created by Safra Soymat on 07/10/2025.
//

import Foundation
import AVFoundation

class AudioConverter {
    enum Error: Swift.Error {
        case failedToCreateConverter
        case failedToCreateConverterBuffer
        case conversionFailed(NSError?)
    }
    
    private var converter: AVAudioConverter?
    
    func convertBuffer(_ buffer: AVAudioPCMBuffer, to outputFormat: AVAudioFormat) throws -> AVAudioPCMBuffer {
        let inputFormat = buffer.format
        guard inputFormat != outputFormat else {
            return buffer
        }
        
        if converter == nil || converter?.outputFormat != outputFormat {
            converter = AVAudioConverter(from: inputFormat, to: outputFormat)
            converter?.primeMethod = .none // Sacrifice quality of first samples in order to avoid any timestamp drift from source
        }
        
        guard let converter else {
            throw Error.failedToCreateConverter
        }
        
        let sampleRateRatio = converter.outputFormat.sampleRate / inputFormat.sampleRate
        let scaledInputFrameLength = Double(buffer.frameLength) * sampleRateRatio
        let frameCapacity = AVAudioFrameCount(scaledInputFrameLength.rounded(.up))
        guard let conversionBuffer = AVAudioPCMBuffer(pcmFormat: converter.outputFormat, frameCapacity: frameCapacity) else {
            throw Error.failedToCreateConverterBuffer
        }
        
        var nsError: NSError?
        var bufferProcessed = false
        
        let status = converter.convert(to: conversionBuffer, error: &nsError) {
            packetCount, inputStatusPointer in
            defer { bufferProcessed = true } // This closure can be called multiple times, but it only offers a single buffer.
            inputStatusPointer.pointee = bufferProcessed ? .noDataNow : .haveData
            return bufferProcessed ? nil : buffer
        }
        
        guard status != .error else {
            throw Error.conversionFailed(nsError)
        }
        
        return conversionBuffer
    }
}
