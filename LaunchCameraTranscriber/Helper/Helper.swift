//
//  Helper.swift
//  LaunchCameraTranscriber
//
//  Created by Safra Soymat on 08/10/2025.
//

import Foundation
import AVFoundation
import SwiftUI

enum TranscriptionState {
    case transcribing
    case notTranscribing
}

public enum TranscriptionError: Error {
    case cantDownloadModel
    case faledToSetupRecognitionStream
    case invalidAudioDataType
    case localeNotSupported
    
    var descriptionString: String {
        switch self {
        case .cantDownloadModel:
            return "Can't download the model"
        case .faledToSetupRecognitionStream:
            return "Failed to setup recognition stream"
        case .invalidAudioDataType:
            return "Invalid audio data type"
        case .localeNotSupported:
            return "Locale not supported"
        }
    }
}

public enum RecordingState: Equatable {
    case stopped
    case recording
    case paused
}

public enum PlaybackState: Equatable {
    case playing
    case notPlaying
}

public struct AudioData: @unchecked Sendable {
    var buffer: AVAudioPCMBuffer
    var time: AVAudioTime
}

/// Split AttributedString into lines by sentence while preserving attributes
func splitTranscriptionIntoLines(_ attributedString: AttributedString) -> [AttributedString] {
    var lines: [AttributedString] = []
    let string = String(attributedString.characters)

    string.enumerateSubstrings(in: string.startIndex..<string.endIndex, options: .bySentences) { (substring, substringRange, _, _) in
        guard let substring = substring?.trimmingCharacters(in: .whitespacesAndNewlines),
              !substring.isEmpty
        else { return }

        // Map Swift String range to AttributedString range
        if let attrRange = attributedString.range(of: substring, options: .literal, locale: nil) {
            let line = AttributedString(attributedString[attrRange]) // convert AttributedSubstring to AttributedString
            lines.append(line)
        }
    }

    return lines
}


extension AVAudioPlayerNode {
    var currentTime: TimeInterval {
        guard let nodeTime: AVAudioTime = self.lastRenderTime,
              let playerTime: AVAudioTime = self.playerTime(forNodeTime: nodeTime) else { return 0 }
        return Double(playerTime.sampleTime) / playerTime.sampleRate
    }
}
