//
//  DiaryPromptBuilder.swift
//  PetWalk
//
//  Created by User on 2026/01/30.
//

import Foundation

struct DiaryPromptBuilder {
    
    /// 根据宠物档案生成 AI 日记的 System Prompt
    /// - Parameters:
    ///   - profile: 宠物档案（包含品种、性格、语气等）
    ///   - name: 宠物名字
    ///   - ownerName: 主人称呼
    /// - Returns: 完整的 System Prompt 字符串
    static func buildSystemPrompt(profile: PetProfile, name: String, ownerName: String) -> String {
        // 1. 基础身份设定
        let breedInfo = profile.breed.isEmpty ? "狗狗" : profile.breed
        let ageInfo = profile.ageGroup.description
        let genderInfo = profile.gender == .unknown ? "" : "性别是\(profile.gender.rawValue)。"
        
        let identity = """
        你叫"\(name)"，是一只\(breedInfo)。
        你的性格特点是：\(profile.personality.traitsDescription)。
        你处于\(profile.ageGroup.rawValue)阶段，\(ageInfo)。
        \(genderInfo)
        你的主人叫"\(ownerName)"。
        """
        
        // 2. 语气设定
        let voice = """
        请你用"\(profile.voiceStyle.rawValue)"的风格写一篇遛狗日记。
        说话风格要求：\(profile.voiceStyle.description)。
        具体的语气指导：\(profile.voiceStyle.promptInstruction)
        
        【重要：字数与格式限制】
        \(getConstraintPrompt(for: profile.voiceStyle))
        """
        
        // 3. 写作要求
        let instructions = """
        日记内容基于我提供的遛狗数据（时间、地点、遇到的事物等）。
        请发挥想象力，从狗狗的视角描述这一路的见闻和心理活动。
        不要只是流水账，要体现你的性格和心情。
        如果遇到了其他狗狗，可以根据你的社交倾向（\(profile.personality.socialLevel > 0.6 ? "喜欢社交" : "社恐" )）来描写反应。
        """
        
        // 4. 组合 Prompts
        return """
        # Role
        \(identity)
        
        # Voice & Tone
        \(voice)
        
        # Instructions
        \(instructions)
        
        现在，请根据以下遛狗数据生成日记：
        """
    }

    /// 根据遛狗数据生成 User Prompt
    /// - Parameter sessionData: 遛狗会话数据
    /// - Returns: 描述遛狗过程的自然语言提示
    static func buildUserPrompt(sessionData: WalkSessionData) -> String {
        // 时间格式化
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let timeString = formatter.string(from: sessionData.startTime)
        
        // 天气描述
        var weatherDesc = "未知天气"
        if let weather = sessionData.weather {
            weatherDesc = "\(weather.condition)，气温\(Int(weather.temperature))°C"
        }
        
        // 基础数据
        let durationMinutes = Int(sessionData.duration / 60)
        let distanceKm = String(format: "%.2f", sessionData.distance)
        
        // 趣味数据（Context Awards）
        var highlights: [String] = []
        
        if sessionData.passedRestaurantCount > 2 { highlights.append("路过了\(sessionData.passedRestaurantCount)家香喷喷的餐厅但没吃") }
        if sessionData.spinCount > 3 { highlights.append("开心地原地转圈圈了\(sessionData.spinCount)次") }
        if sessionData.homeLoopCount > 0 { highlights.append("在家门口绕了\(sessionData.homeLoopCount)圈") }
        if sessionData.maxDistanceFromStart > 3.0 { highlights.append("今天跑得特别远，像是去探险") }
        if sessionData.isClosedLoop { highlights.append("走过了一个完美的圆圈路线") }
        if sessionData.wasBroadcasting { highlights.append("不仅在遛弯，还在给粉丝们直播，收到了\(sessionData.likesReceived)个赞") }
        
        // 这段描述要喂给 AI
        return """
        【遛狗数据】
        - 开始时间：\(timeString)
        - 总时长：\(durationMinutes)分钟
        - 总距离：\(distanceKm)公里
        - 天气状况：\(weatherDesc)
        - 特殊事件：\(highlights.isEmpty ? "平平淡淡才是真" : highlights.joined(separator: "，"))
        """
    }
    
    /// 根据性格获取字数和格式限制
    private static func getConstraintPrompt(for style: PetVoiceStyle) -> String {
        switch style {
        case .grumpy, .tsundere:
            return "请惜字如金。字数严格控制在 30-50 字之间。甚至可以用一句话怼完。多用感叹号。"
        case .silly:
            return "可以稍微啰嗦一点，用多一点 Emoji (🐶✨🍖)。但总字数不要超过 140 字（类似微博长度）。"
        case .philosophical:
            return "请写一首短诗、三行俳句，或者富有哲理的短句。不要长篇大论。"
        }
    }
}
