//
//  UserData.swift
//  PetWalk
//
//  Created by Cursor AI on 2025/12/8.
//

import Foundation

struct UserData: Codable {
    var totalBones: Int = 0          // 骨头币余额
    var inventory: [String: Int] = [:] // 物品清单 [ItemID: Count]
    var lastWalkDate: Date?          // 上次遛狗结束时间，用于计算宠物心情
    
    // 初始化时可以给一点初始资源方便测试
    static let initial = UserData(totalBones: 0, inventory: [:], lastWalkDate: nil)
}

