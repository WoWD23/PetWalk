//
//  AchievementDetailView.swift
//  PetWalk
//
//  Created by Cursor AI on 2026/1/28.
//

import SwiftUI

/// 成就详情视图
struct AchievementDetailView: View {
    let achievement: Achievement
    let isUnlocked: Bool
    let progress: (current: Int, target: Int)
    
    @ObservedObject var gameCenter = GameCenterManager.shared
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 成就图标和状态
                achievementHeader
                
                // 成就描述
                achievementDescription
                
                // 稀有度卡片
                rarityCard
                
                // 进度条
                if !isUnlocked {
                    progressSection
                }
                
                // 首杀榜（已解锁的成就）
                if isUnlocked {
                    hallOfFameSection
                }
                
                // 奖励信息
                rewardSection
            }
            .padding()
        }
        .navigationTitle("成就详情")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - 成就头部
    
    private var achievementHeader: some View {
        VStack(spacing: 16) {
            // 图标
            ZStack {
                Circle()
                    .fill(
                        isUnlocked ?
                        LinearGradient(
                            colors: [achievement.category.color.opacity(0.8), achievement.category.color],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.4)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                
                Image(systemName: isUnlocked ? achievement.iconSymbol : "lock.fill")
                    .font(.system(size: 40))
                    .foregroundColor(isUnlocked ? .white : .gray)
            }
            
            // 名称
            VStack(spacing: 4) {
                HStack(spacing: 8) {
                    Text(achievement.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    // 隐藏成就标志
                    if achievement.isSecret {
                        Image(systemName: "eye.slash.fill")
                            .font(.caption)
                            .foregroundColor(.purple)
                    }
                }
                
                Text(achievement.category.title)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            // 状态
            HStack(spacing: 8) {
                Image(systemName: isUnlocked ? "checkmark.seal.fill" : "clock.fill")
                    .foregroundColor(isUnlocked ? .green : .orange)
                Text(isUnlocked ? "已解锁" : "进行中")
                    .font(.subheadline)
                    .foregroundColor(isUnlocked ? .green : .orange)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isUnlocked ? Color.green.opacity(0.1) : Color.orange.opacity(0.1))
            )
        }
    }
    
    // MARK: - 成就描述
    
    private var achievementDescription: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("描述")
                .font(.headline)
            
            Text(achievement.description)
                .font(.body)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
    
    // MARK: - 稀有度卡片
    
    private var rarityCard: some View {
        VStack(spacing: 12) {
            HStack {
                Text("稀有度")
                    .font(.headline)
                Spacer()
                
                // 稀有度标签
                HStack(spacing: 4) {
                    Image(systemName: rarityIcon)
                        .font(.caption)
                    Text(achievement.rarity.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(achievement.rarity.color.opacity(0.2))
                )
                .foregroundColor(achievement.rarity.color)
            }
            
            // 全球解锁率
            VStack(spacing: 8) {
                HStack {
                    Text("全球解锁率")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Spacer()
                    Text(String(format: "%.1f%%", unlockPercentage))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(achievement.rarity.color)
                }
                
                // 进度条
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(achievement.rarity.color)
                            .frame(width: geometry.size.width * CGFloat(unlockPercentage / 100.0), height: 8)
                    }
                }
                .frame(height: 8)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(achievement.rarity.color.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var rarityIcon: String {
        switch achievement.rarity {
        case .common: return "star"
        case .rare: return "star.fill"
        case .epic: return "star.leadinghalf.filled"
        case .legendary: return "sparkles"
        }
    }
    
    private var unlockPercentage: Double {
        // 从 Game Center 获取真实数据，或使用估算值
        if let gameCenterID = achievement.gameCenterID {
            return gameCenter.achievementRarities[gameCenterID] ?? estimatedPercentage
        }
        return estimatedPercentage
    }
    
    private var estimatedPercentage: Double {
        switch achievement.rarity {
        case .common: return 55.0
        case .rare: return 15.0
        case .epic: return 5.0
        case .legendary: return 0.5
        }
    }
    
    // MARK: - 进度条
    
    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("进度")
                .font(.headline)
            
            VStack(spacing: 8) {
                HStack {
                    Text("\(progress.current)")
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text("/ \(progress.target)")
                        .font(.title3)
                        .foregroundColor(.gray)
                    Spacer()
                    Text(String(format: "%.0f%%", Double(progress.current) / Double(max(1, progress.target)) * 100))
                        .font(.caption)
                        .foregroundColor(.appGreenMain)
                }
                
                // 进度条
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 12)
                        
                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    colors: [.appGreenMain, .appGreenDark],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(
                                width: geometry.size.width * CGFloat(min(1.0, Double(progress.current) / Double(max(1, progress.target)))),
                                height: 12
                            )
                    }
                }
                .frame(height: 12)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
    
    // MARK: - 首杀榜
    
    private var hallOfFameSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "crown.fill")
                    .foregroundColor(.yellow)
                Text("首杀榜")
                    .font(.headline)
            }
            
            // 首杀信息（需要后端支持）
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("首位达成者")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("暂无数据")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("达成时间")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("-")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.top, 4)
            
            Divider()
            
            // 提示信息
            Text("首杀榜记录每个成就的首位达成者，快去挑战新成就吧！")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.yellow.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - 奖励信息
    
    private var rewardSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("奖励")
                .font(.headline)
            
            HStack {
                Image(systemName: "pawprint.fill")
                    .font(.title2)
                    .foregroundColor(.appBrown)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(achievement.rewardBones) 骨头币")
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text(isUnlocked ? "已领取" : "完成后领取")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                if isUnlocked {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.appBrown.opacity(0.1))
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - 成就列表视图
struct AchievementListView: View {
    @State private var selectedCategory: AchievementCategory?
    @State private var showOnlyUnlocked = false
    @State private var selectedAchievement: Achievement?
    
    private let userData = DataManager.shared.userData
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 筛选器
                filterBar
                
                // 成就列表
                achievementList
            }
            .navigationTitle("成就")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: LeaderboardView()) {
                        Image(systemName: "chart.bar.fill")
                    }
                }
            }
        }
        .sheet(item: $selectedAchievement) { achievement in
            NavigationView {
                AchievementDetailView(
                    achievement: achievement,
                    isUnlocked: userData.isAchievementUnlocked(achievement.id),
                    progress: AchievementManager.shared.getProgress(for: achievement, userData: userData)
                )
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("关闭") {
                            selectedAchievement = nil
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - 筛选器
    
    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // 全部
                FilterChip(
                    title: "全部",
                    isSelected: selectedCategory == nil,
                    color: .appGreenMain
                ) {
                    selectedCategory = nil
                }
                
                // 各类别
                ForEach(AchievementCategory.allCases, id: \.self) { category in
                    FilterChip(
                        title: category.title,
                        icon: category.iconSymbol,
                        isSelected: selectedCategory == category,
                        color: category.color
                    ) {
                        selectedCategory = category
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .background(Color(.systemBackground))
    }
    
    // MARK: - 成就列表
    
    private var achievementList: some View {
        let achievements = filteredAchievements
        
        return ScrollView {
            LazyVStack(spacing: 12) {
                // 统计卡片
                statsCard
                
                // 成就列表
                ForEach(achievements) { achievement in
                    AchievementRow(
                        achievement: achievement,
                        isUnlocked: userData.isAchievementUnlocked(achievement.id),
                        progress: AchievementManager.shared.getProgressPercentage(for: achievement, userData: userData)
                    )
                    .onTapGesture {
                        // 隐藏成就如果未解锁，不显示详情
                        if !achievement.isSecret || userData.isAchievementUnlocked(achievement.id) {
                            selectedAchievement = achievement
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    private var filteredAchievements: [Achievement] {
        Achievement.allAchievements.filter { achievement in
            // 类别筛选
            if let category = selectedCategory, achievement.category != category {
                return false
            }
            
            // 隐藏成就处理：如果是隐藏成就且未解锁，显示为"???"
            // 但仍然在列表中显示
            return true
        }
    }
    
    // MARK: - 统计卡片
    
    private var statsCard: some View {
        let total = Achievement.allAchievements.count
        let unlocked = userData.unlockedAchievements.count
        
        return HStack(spacing: 20) {
            VStack(spacing: 4) {
                Text("\(unlocked)")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.appGreenMain)
                Text("已解锁")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Divider()
                .frame(height: 40)
            
            VStack(spacing: 4) {
                Text("\(total)")
                    .font(.title)
                    .fontWeight(.bold)
                Text("总成就")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Divider()
                .frame(height: 40)
            
            VStack(spacing: 4) {
                Text(String(format: "%.0f%%", Double(unlocked) / Double(max(1, total)) * 100))
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
                Text("完成度")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - 筛选标签
struct FilterChip: View {
    let title: String
    var icon: String? = nil
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.caption)
                }
                Text(title)
                    .font(.caption)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(isSelected ? color.opacity(0.2) : Color.gray.opacity(0.1))
            )
            .foregroundColor(isSelected ? color : .gray)
        }
    }
}

// MARK: - 成就行
struct AchievementRow: View {
    let achievement: Achievement
    let isUnlocked: Bool
    let progress: Double
    
    private var isHiddenAndLocked: Bool {
        achievement.isSecret && !isUnlocked
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // 图标
            ZStack {
                Circle()
                    .fill(isUnlocked ? achievement.category.color.opacity(0.2) : Color.gray.opacity(0.1))
                    .frame(width: 50, height: 50)
                
                Image(systemName: isHiddenAndLocked ? "questionmark" : achievement.iconSymbol)
                    .font(.system(size: 22))
                    .foregroundColor(isUnlocked ? achievement.category.color : .gray)
            }
            
            // 信息
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(isHiddenAndLocked ? "???" : achievement.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    // 稀有度标签
                    if !isHiddenAndLocked && achievement.rarity != .common {
                        Text(achievement.rarity.displayName)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(achievement.rarity.color.opacity(0.2))
                            )
                            .foregroundColor(achievement.rarity.color)
                    }
                }
                
                Text(isHiddenAndLocked ? "隐藏成就" : achievement.description)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(1)
                
                // 进度条（未解锁时显示）
                if !isUnlocked && !isHiddenAndLocked {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 4)
                            
                            RoundedRectangle(cornerRadius: 2)
                                .fill(achievement.category.color)
                                .frame(width: geometry.size.width * CGFloat(progress), height: 4)
                        }
                    }
                    .frame(height: 4)
                }
            }
            
            Spacer()
            
            // 状态/奖励
            VStack(alignment: .trailing, spacing: 4) {
                if isUnlocked {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                } else {
                    HStack(spacing: 2) {
                        Image(systemName: "pawprint.fill")
                            .font(.caption)
                        Text("\(achievement.rewardBones)")
                            .font(.caption)
                    }
                    .foregroundColor(.appBrown)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isUnlocked ? Color.green.opacity(0.3) : Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

#Preview {
    AchievementListView()
}
