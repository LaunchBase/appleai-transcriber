//
//  Button.swift
//  LaunchCameraTranscriber
//
//  Created by Safra Soymat on 16/10/2025.
//

import SwiftUI

// MARK: Back Button
struct BackButton: View {
    var title: String = "Back"
    var systemImage: String = "chevron.left"
    var action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                Text(title)
                    .font(.custom("Manrope", size: 14))
            }
            .padding(8)
            .frame(minWidth: 80)
            .background(Color.white)
            .foregroundColor(.black)
            .cornerRadius(12)
            .shadow(color: .black.opacity(isHovering ? 0.3 : 0.2), radius: isHovering ? 8 : 6, x: 0, y: 3)
            .scaleEffect(isHovering ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isHovering)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            self.isHovering = hovering
        }
    }
}

// MARK: Solid Button with optional disabled state
struct SolidButton: View {
    let title: String
    let systemImage: String
    let bgColor: Color
    let textColor: Color
    let action: () -> Void
    var isDisabled: Bool = false
    
    @State private var isHovering = false

    var body: some View {
        Button(action: {
            if !isDisabled {
                action()
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                Text(title)
                    .font(.custom("Manrope", size: 16))
            }
            .padding()
            .frame(width: 200, height: 50)
            .background(isDisabled ? Color.gray : bgColor)
            .foregroundColor(textColor.opacity(isDisabled ? 0.7 : 1.0))
            .cornerRadius(18)
            .shadow(color: .black.opacity(isHovering ? 0.3 : 0.2), radius: isHovering ? 8 : 6, x: 0, y: 3)
            .scaleEffect(isHovering && !isDisabled ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isHovering)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            self.isHovering = hovering
        }
        .disabled(isDisabled)
    }
}

