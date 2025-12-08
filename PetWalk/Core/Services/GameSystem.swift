//
//  GameSystem.swift
//  PetWalk
//
//  Created by Cursor AI on 2025/12/8.
//

import Foundation

class GameSystem {
    // 单例模式，或者直接作为静态工具类
    static let shared = GameSystem()
    
    // 经济系统：1km = 10 骨头币
    func calculateBones(distanceKm: Double) -> Int {
        // 至少给 1 个币（如果是有效距离）
        if distanceKm < 0.05 { return 0 }
        return max(1, Int(distanceKm * 10))
    }
    
    // 寻宝系统：根据距离判断掉落
    // 距离 > 0.5km 才有几率掉落
    func generateDrops(distanceKm: Double) -> [TreasureItem] {
        guard distanceKm > 0.5 else { return [] }
        
        var foundItems: [TreasureItem] = []
        
        // 基础掉落率：固定尝试一次
        if shouldDrop() {
            if let item = rollItem() {
                foundItems.append(item)
            }
        }
        
        // 长距离奖励：每多 2km 多一次判定机会
        var extraChanceDistance = distanceKm - 0.5
        while extraChanceDistance > 2.0 {
            if shouldDrop() {
                if let item = rollItem() {
                    foundItems.append(item)
                }
            }
            extraChanceDistance -= 2.0
        }
        
        return foundItems
    }
    
    // 判定是否掉落 (比如 60% 几率掉东西)
    private func shouldDrop() -> Bool {
        return Double.random(in: 0...1) < 0.6
    }
    
    // 判定掉落什么物品 (根据 PRD 概率表)
    private func rollItem() -> TreasureItem? {
        let roll = Double.random(in: 0...1)
        var rarity: Rarity
        
        // 概率分布:
        // Common: 50% (0.0 - 0.5)
        // Uncommon: 35% (0.5 - 0.85)
        // Rare: 14% (0.85 - 0.99)
        // Legendary: 1% (0.99 - 1.0)
        
        if roll < 0.5 {
            rarity = .common
        } else if roll < 0.85 {
            rarity = .uncommon
        } else if roll < 0.99 {
            rarity = .rare
        } else {
            rarity = .legendary
        }
        
        // 从对应稀有度的物品池中随机取一个
        // 注意：Legendary 包含 "isMapExclusive" 的物品，这里我们允许掉落所有 legendary
        let pool = TreasureItem.allItems.filter { $0.rarity == rarity }
        return pool.randomElement()
    }
}

