//
//  PetOverlayProvider.swift
//  PetWalk
//
//  Created by Cursor AI on 2025/12/8.
//

import SwiftUI

struct MoodOverlayConfig {
    let emoji: String?
    let offset: CGSize
    let animation: Animation?
    
    // 动画目标状态 (默认无变化)
    var scaleTarget: CGFloat = 1.0
    var offsetYTarget: CGFloat = 0
    var opacityTarget: Double = 1.0
}

class PetOverlayProvider {
    static func getConfig(for mood: PetMood) -> MoodOverlayConfig {
        // TODO: 节日判断逻辑 (e.g. if isChristmas { ... })
        
        switch mood {
        case .excited:
            return MoodOverlayConfig(
                emoji: "✨",
                offset: CGSize(width: 40, height: -40),
                animation: .easeInOut(duration: 0.5).repeatForever(),
                scaleTarget: 1.3
            )
        case .happy:
            return MoodOverlayConfig(
                emoji: "🎵",
                offset: CGSize(width: 40, height: -40),
                animation: .easeInOut(duration: 1.0).repeatForever(),
                scaleTarget: 1.3
            )
        case .expecting:
            return MoodOverlayConfig(
                emoji: "❔",
                offset: CGSize(width: 30, height: -50),
                animation: nil
            )
        case .depressed:
            return MoodOverlayConfig(
                emoji: "💧",
                offset: CGSize(width: 20, height: -20),
                animation: .linear(duration: 1.5).repeatForever(autoreverses: false),
                scaleTarget: 1.0,
                offsetYTarget: 40,  // 向下流
                opacityTarget: 0.0  // 逐渐消失
            )
        }
    }
}
