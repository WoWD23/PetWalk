//
//  PetAnimationProvider.swift
//  PetWalk
//
//  Created by Cursor AI on 2025/12/8.
//

import SwiftUI

struct MoodAnimationConfig {
    let bounceHeight: CGFloat
    let scaleY: CGFloat
    let offsetY: CGFloat
    let rotationAngle: Double
    let timing: Animation
}

class PetAnimationProvider {
    static func getConfig(for mood: PetMood) -> MoodAnimationConfig {
        switch mood {
        case .excited:
            return MoodAnimationConfig(
                bounceHeight: -15, scaleY: 1.0, offsetY: 0, rotationAngle: 0,
                timing: .easeInOut(duration: 0.3).repeatForever(autoreverses: true)
            )
        case .happy:
            return MoodAnimationConfig(
                bounceHeight: -5, scaleY: 1.0, offsetY: 0, rotationAngle: 0,
                timing: .easeInOut(duration: 1.5).repeatForever(autoreverses: true)
            )
        case .expecting:
            return MoodAnimationConfig(
                bounceHeight: 0, scaleY: 1.0, offsetY: 0, rotationAngle: -10,
                timing: .spring(response: 0.5, dampingFraction: 0.5)
            )
        case .depressed:
            return MoodAnimationConfig(
                bounceHeight: 0, scaleY: 0.8, offsetY: 15, rotationAngle: 0,
                timing: .spring(response: 0.6, dampingFraction: 0.6)
            )
        }
    }
}

