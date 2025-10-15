//
//  LaunchCameraTranscriberApp.swift
//  LaunchCameraTranscriber
//
//  Created by Safra Soymat on 08/10/2025.
//

import SwiftUI
import CoreText

@main
struct LaunchCameraTranscriberApp: App {
    
    init() {
        registerFont(name: "PPWoodland-Bold", ext: "otf")
        registerFont(name: "PPWoodland-Ultralight", ext: "otf")
        registerFont(name: "Manrope", ext: "ttf")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

func registerFont(name: String, ext: String) {
    if let url = Bundle.main.url(forResource: name, withExtension: ext) {
        CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
    } else {
        print("Failed to load font \(name).\(ext)")
    }
}
