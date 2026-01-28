//
//  LeaderboardView.swift
//  PetWalk
//
//  Created by Cursor AI on 2026/1/28.
//

import SwiftUI

/// 排行榜视图
struct LeaderboardView: View {
    @ObservedObject var gameCenter = GameCenterManager.shared
    @State private var selectedTab: LeaderboardType = .global
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 标签页选择器
                leaderboardTabPicker
                
                // 排行榜内容
                if gameCenter.isAuthenticated {
                    leaderboardContent
                } else {
                    notAuthenticatedView
                }
            }
            .navigationTitle("排行榜")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        gameCenter.showGameCenter()
                    } label: {
                        Image(systemName: "gamecontroller.fill")
                    }
                }
            }
            .onAppear {
                if !gameCenter.isAuthenticated {
                    gameCenter.authenticate()
                }
            }
        }
    }
    
    // MARK: - 标签页选择器
    
    private var leaderboardTabPicker: some View {
        HStack(spacing: 0) {
            ForEach(LeaderboardType.allCases, id: \.self) { type in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = type
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: type.iconSymbol)
                            .font(.system(size: 20))
                        Text(type.displayName)
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        selectedTab == type ?
                        Color.appGreenMain.opacity(0.2) :
                        Color.clear
                    )
                    .foregroundColor(selectedTab == type ? .appGreenMain : .gray)
                }
            }
        }
        .background(Color.appBackground)
        .overlay(
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 1),
            alignment: .bottom
        )
    }
    
    // MARK: - 排行榜内容
    
    private var leaderboardContent: some View {
        VStack {
            // 当前玩家排名卡片
            if let rank = currentPlayerRank {
                currentPlayerCard(rank: rank)
            }
            
            // 排行榜列表
            if gameCenter.isLoading {
                Spacer()
                ProgressView("加载中...")
                Spacer()
            } else {
                leaderboardList
            }
        }
    }
    
    private var currentPlayerRank: Int? {
        switch selectedTab {
        case .global:
            return gameCenter.currentPlayerGlobalRank
        case .friends:
            return gameCenter.currentPlayerFriendsRank
        case .city:
            return nil
        }
    }
    
    private var currentLeaderboard: [LeaderboardEntry] {
        switch selectedTab {
        case .global:
            return gameCenter.globalLeaderboard
        case .friends:
            return gameCenter.friendsLeaderboard
        case .city:
            return gameCenter.cityLeaderboard
        }
    }
    
    // MARK: - 当前玩家排名卡片
    
    private func currentPlayerCard(rank: Int) -> some View {
        HStack(spacing: 16) {
            // 排名
            Text("#\(rank)")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.appGreenMain)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("我的排名")
                    .font(.caption)
                    .foregroundColor(.gray)
                Text(gameCenter.localPlayer?.displayName ?? "玩家")
                    .font(.headline)
            }
            
            Spacer()
            
            // 里程
            let userData = DataManager.shared.userData
            VStack(alignment: .trailing, spacing: 4) {
                Text("累计里程")
                    .font(.caption)
                    .foregroundColor(.gray)
                Text(String(format: "%.1f km", userData.totalDistance))
                    .font(.headline)
                    .foregroundColor(.appGreenMain)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.appGreenMain.opacity(0.1))
        )
        .padding(.horizontal)
        .padding(.top, 12)
    }
    
    // MARK: - 排行榜列表
    
    private var leaderboardList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                if currentLeaderboard.isEmpty {
                    emptyLeaderboardView
                } else {
                    ForEach(currentLeaderboard) { entry in
                        LeaderboardEntryRow(
                            entry: entry, 
                            showMedal: entry.rank <= 3,
                            showNudgeButton: selectedTab == .friends && !entry.isCurrentPlayer,
                            canNudge: entry.gameCenterID.map { DataManager.shared.userData.canNudgeFriend($0) } ?? true
                        )
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 12)
        }
        .refreshable {
            await gameCenter.loadLeaderboard(type: selectedTab)
        }
    }
    
    private var emptyLeaderboardView: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 50))
                .foregroundColor(.gray.opacity(0.5))
            Text("暂无数据")
                .font(.headline)
                .foregroundColor(.gray)
            Text("完成遛狗后，你的成绩将显示在这里")
                .font(.caption)
                .foregroundColor(.gray.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(.top, 60)
    }
    
    // MARK: - 未认证视图
    
    private var notAuthenticatedView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "gamecontroller.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))
            
            Text("登录 Game Center")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("登录 Game Center 后，你可以查看全球排行榜，\n与好友一较高下！")
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            Button {
                gameCenter.authenticate()
            } label: {
                Text("登录 Game Center")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 14)
                    .background(Color.appGreenMain)
                    .cornerRadius(12)
            }
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - 排行榜条目行
struct LeaderboardEntryRow: View {
    let entry: LeaderboardEntry
    var showMedal: Bool = false
    var showNudgeButton: Bool = false
    var canNudge: Bool = true
    
    @State private var isNudging = false
    @State private var nudgeSent = false
    
    var body: some View {
        HStack(spacing: 12) {
            // 排名
            rankView
            
            // 头像
            avatarView
            
            // 玩家信息
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.playerName)
                    .font(.subheadline)
                    .fontWeight(entry.isCurrentPlayer ? .semibold : .regular)
                    .foregroundColor(entry.isCurrentPlayer ? .appGreenMain : .primary)
                
                if let city = entry.city {
                    Text(city)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            // 催促按钮（好友榜）
            if showNudgeButton {
                nudgeButton
            }
            
            // 分数
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatDistance(entry.score))
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text("累计里程")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(entry.isCurrentPlayer ? Color.appGreenMain.opacity(0.1) : Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(entry.isCurrentPlayer ? Color.appGreenMain : Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
    
    // MARK: - 催促按钮
    private var nudgeButton: some View {
        Button {
            sendNudge()
        } label: {
            HStack(spacing: 4) {
                if isNudging {
                    ProgressView()
                        .scaleEffect(0.7)
                } else if nudgeSent || !canNudge {
                    Image(systemName: "checkmark")
                        .font(.caption)
                } else {
                    Image(systemName: "bell.badge.fill")
                        .font(.caption)
                }
                
                Text(nudgeSent || !canNudge ? "已催" : "催一下")
                    .font(.caption)
            }
            .foregroundColor(nudgeSent || !canNudge ? .gray : .white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(nudgeSent || !canNudge ? Color.gray.opacity(0.3) : Color.orange)
            )
        }
        .disabled(isNudging || nudgeSent || !canNudge)
    }
    
    private func sendNudge() {
        guard let friendId = entry.gameCenterID else { return }
        
        isNudging = true
        
        Task {
            let success = await NotificationManager.shared.sendFriendNudge(
                to: friendId,
                friendName: entry.playerName
            )
            
            await MainActor.run {
                isNudging = false
                if success {
                    nudgeSent = true
                }
            }
        }
    }
    
    private var rankView: some View {
        Group {
            if showMedal {
                medalView
            } else {
                Text("#\(entry.rank)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.gray)
                    .frame(width: 36)
            }
        }
    }
    
    private var medalView: some View {
        ZStack {
            Circle()
                .fill(medalColor)
                .frame(width: 36, height: 36)
            
            Text("\(entry.rank)")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
        }
    }
    
    private var medalColor: Color {
        switch entry.rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return .gray
        }
    }
    
    private var avatarView: some View {
        Group {
            if let image = entry.avatarImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.gray)
                    )
            }
        }
    }
    
    private func formatDistance(_ meters: Int) -> String {
        let km = Double(meters) / 1000.0
        if km >= 1000 {
            return String(format: "%.1fk km", km / 1000)
        } else if km >= 100 {
            return String(format: "%.0f km", km)
        } else {
            return String(format: "%.1f km", km)
        }
    }
}

#Preview {
    LeaderboardView()
}
