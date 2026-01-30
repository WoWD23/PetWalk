//
//  PetProfile.swift
//  PetWalk
//
//  Created by User on 2026/01/30.
//

import Foundation

struct PetProfile: Codable, Equatable {
    // MARK: - Hardware (Physiological)
    var breed: String = ""
    var gender: PetGender = .unknown
    var birthday: Date = Date()
    
    // MARK: - Software (Personality)
    var personality: PetPersonality = .default
    
    // MARK: - Voice (AI Tone)
    var voiceStyle: PetVoiceStyle = .silly
    
    // MARK: - Helpers
    var ageDetails: String {
        let ageComponents = Calendar.current.dateComponents([.year, .month], from: birthday, to: Date())
        let years = ageComponents.year ?? 0
        let months = ageComponents.month ?? 0
        
        if years > 0 {
            return "\(years)岁\(months)个月"
        } else {
            return "\(months)个月"
        }
    }
    
    var ageGroup: PetAgeGroup {
        let years = Calendar.current.dateComponents([.year], from: birthday, to: Date()).year ?? 0
        if years < 1 { return .puppy }
        if years >= 8 { return .senior }
        return .adult
    }
}

enum PetGender: String, Codable, CaseIterable, Identifiable {
    case male = "公"
    case female = "母"
    case unknown = "保密"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .male: return "♂"
        case .female: return "♀"
        case .unknown: return "?"
        }
    }
}

enum PetAgeGroup: String {
    case puppy = "幼犬"   // < 1 year
    case adult = "成犬"   // 1 - 7 years
    case senior = "老犬"  // > 7 years
    
    var description: String {
        switch self {
        case .puppy: return "好奇、精力过剩、爱咬东西"
        case .adult: return "稳重、守护、最佳伙伴"
        case .senior: return "慢悠悠、怀旧、容易累"
        }
    }
}

struct PetPersonality: Codable, Equatable {
    // 0.0 - 1.0 scale
    var energyLevel: Double = 0.5   // Lazy <-> Hyper
    var socialLevel: Double = 0.5   // Shy <-> Friendly
    var obedienceLevel: Double = 0.5 // Stubborn <-> Obedient
    var foodieLevel: Double = 0.5   // Picky <-> Foodie
    var tags: [String] = []         // "Destruction Captain", etc.
    
    static let `default` = PetPersonality()
    
    // Helper to get descriptive text for prompt
    var traitsDescription: String {
        var traits = [String]()
        
        // Energy
        if energyLevel < 0.3 { traits.append("懒狗(Couch Potato)") }
        else if energyLevel > 0.7 { traits.append("精力旺盛(High Energy)") }
        
        // Social
        if socialLevel < 0.3 { traits.append("社恐(Shy)") }
        else if socialLevel > 0.7 { traits.append("社牛(Friendly)") }
        
        // Obedience
        if obedienceLevel < 0.3 { traits.append("非常有主见/叛逆(Stubborn)") }
        else if obedienceLevel > 0.7 { traits.append("非常听话(Obedient)") }
        
        // Foodie
        if foodieLevel < 0.3 { traits.append("挑食(Picky)") }
        else if foodieLevel > 0.7 { traits.append("贪吃(Foodie)") }
        
        if !tags.isEmpty {
            traits.append(contentsOf: tags)
        }
        
        return traits.joined(separator: ", ")
    }
}

enum PetVoiceStyle: String, Codable, CaseIterable, Identifiable {
    case silly = "傻白甜"
    case tsundere = "傲娇毒舌"
    case philosophical = "哲学诗意"
    case grumpy = "暴躁老哥"
    
    var id: String { rawValue }
    
    var description: String {
        switch self {
        case .silly: return "充满Emoji，开心，单纯"
        case .tsundere: return "嫌弃主人，自恋，偶尔配合"
        case .philosophical: return "深沉，思考狗生，文艺"
        case .grumpy: return "全是感叹号，冲动，爱挑事"
        }
    }
    
    var example: String {
        switch self {
        case .silly: return "哇！今天的草地好绿呀！开心开心！🐶✨"
        case .tsundere: return "愚蠢的人类又带我走这条路...不过看在罐头的份上，勉强配合一下吧。"
        case .philosophical: return "每一根电线杆，都是城市孤独的图腾。我留下的不是气味，是记忆。"
        case .grumpy: return "那个泰迪敢瞪我？！别拉我！我要过去跟它单挑！！😡"
        }
    }
    
    // Prompt instruction for the AI
    var promptInstruction: String {
        switch self {
        case .silly: return "语气要像个傻白甜，多用Emoji，非常乐观开心，单纯可爱。"
        case .tsundere: return "语气要傲娇毒舌，有点嫌弃主人但又离不开，自恋。"
        case .philosophical: return "语气要深沉诗意，喜欢思考狗生哲理，用词文艺。"
        case .grumpy: return "语气要暴躁冲动，全是感叹号，看谁都不爽，容易激动。"
        }
    }
}
