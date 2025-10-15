//
//  Lecture.swift
//  LaunchCameraTranscriber
//
//  Created by Safra Soymat on 08/10/2025.
//

import Foundation
import AVFoundation
import FoundationModels

@Observable
class Lecture: Identifiable {
    typealias StartTime = CMTime
    
    let id: UUID
    var transcript: AttributedString
    var file_url: URL?
    var isDone: Bool
    
    init(transcript: AttributedString, file_url: URL? = nil, isDone: Bool = false) {
        self.transcript = transcript
        self.file_url = file_url
        self.isDone = isDone
        self.id = UUID()
    }
    
}

extension Lecture {
    static func create() -> Lecture {
        return .init(transcript: AttributedString(""))
    }
    
    func lectureByLine() -> AttributedString {
        print(String(transcript.characters))
        if file_url == nil {
            print("File url is not specified")
            return transcript
        } else {
            var final = AttributedString("")
            var working = AttributedString("")
            let copy = transcript
            copy.runs.forEach { run in
                if copy[run.range].characters.contains(".") {
                    working.append(copy[run.range])
                    final.append(working)
                    final.append(AttributedString("\n\n"))
                    working = AttributedString("")
                } else {
                    if working.characters.isEmpty {
                        let newTranscript = copy[run.range].characters
                        let attributes = run.attributes
                        let trimmed = newTranscript.trimmingPrefix(" ")
                        let newAttributed = AttributedString(trimmed, attributes: attributes)
                        working.append(newAttributed)
                    } else {
                        working.append(copy[run.range])
                    }
                }
            }
            
            if final.characters.isEmpty {
                return working
            }
            
            return final
        }
    }
}

extension Lecture: Equatable {
    static func == (lhs: Lecture, rhs: Lecture) -> Bool {
        lhs.id == rhs.id
    }
}

extension Lecture: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

