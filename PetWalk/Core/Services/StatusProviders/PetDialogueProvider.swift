//
//  PetDialogueProvider.swift
//  PetWalk
//
//  Created by Cursor AI on 2025/12/8.
//

import Foundation

struct MoodDialogueConfig {
    let text: String
}

class PetDialogueProvider {
    // 未来参数可扩展：weather: WeatherType, season: Season, ...
    static func getConfig(for mood: PetMood) -> MoodDialogueConfig {
        let text: String
        switch mood {
        case .excited: text = "刚才玩得好开心！\n还要去吗？"
        case .happy: text = "今天天气不错，\n去公园吗？"
        case .expecting: text = "好久没出门了...\n我想出去玩"
        case .depressed: text = "主人是不是\n不爱我了..."
        }
        return MoodDialogueConfig(text: text)
    }
}

