//
//  WalkSummaryView.swift
//  PetWalk
//
//  Created by 熊毓敏 on 2025/12/7.
//

import SwiftUI
import PhotosUI

struct WalkSummaryView: View {
    // 输入参数：本次遛狗的数据
    let duration: TimeInterval
    let distance: Double
    let routeCoordinates: [RoutePoint] // 新增：轨迹数据
    
    // 回调：完成保存
    var onFinish: () -> Void
    
    @StateObject private var dataManager = DataManager.shared
    
    // 表单状态
    @State private var mood: String = "happy" // happy, tired, normal
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    
    // 动画
    @State private var isVisible = false
    
    // 游戏化奖励状态
    @State private var earnedBones: Int = 0
    @State private var foundItems: [TreasureItem] = []
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 30) {
                    // 1. 标题
                    Text("遛弯完成！")
                        .font(.system(size: 34, weight: .heavy, design: .rounded))
                        .foregroundColor(.appBrown)
                        .padding(.top, 40)
                    
                    // 2. 成绩卡片
                    HStack(spacing: 20) {
                        StatBox(title: "距离", value: String(format: "%.2f", distance), unit: "km")
                        StatBox(title: "时长", value: formatDuration(duration), unit: "min")
                    }
                    .padding(.horizontal)
                    
                    // 2.5 奖励展示区 (Gamification)
                    VStack(spacing: 15) {
                        Text("本次收获")
                            .font(.headline)
                            .foregroundColor(.appBrown)
                        
                        HStack(spacing: 30) {
                            // 骨头币
                            VStack {
                                Image(systemName: "bone.fill")
                                    .font(.title)
                                    .foregroundColor(.yellow)
                                Text("+\(earnedBones)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.appBrown)
                            }
                            
                            // 掉落物
                            if foundItems.isEmpty {
                                Text("这次没有捡到东西呢...")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            } else {
                                ForEach(foundItems) { item in
                                    VStack {
                                        Image(systemName: item.iconName)
                                            .font(.title)
                                            .foregroundColor(item.rarity.color)
                                        Text(item.name)
                                            .font(.caption)
                                            .foregroundColor(.appBrown)
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(15)
                        .shadow(color: .black.opacity(0.05), radius: 5)
                    }
                    .padding(.horizontal)
                    .transition(.scale)
                    
                    // 3. 心情选择
                    VStack(alignment: .leading, spacing: 15) {
                        Text("狗狗心情如何？")
                            .font(.headline)
                            .foregroundColor(.appBrown)
                        
                        HStack(spacing: 25) {
                            MoodButton(mood: "happy", icon: "face.smiling.fill", color: .orange, selectedMood: $mood)
                            MoodButton(mood: "normal", icon: "pawprint.fill", color: .appGreenMain, selectedMood: $mood)
                            MoodButton(mood: "tired", icon: "zzz", color: .blue, selectedMood: $mood)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                    
                    // 4. 照片记录
                    VStack(alignment: .leading, spacing: 15) {
                        Text("拍张照留念吧")
                            .font(.headline)
                            .foregroundColor(.appBrown)
                        
                        PhotosPicker(selection: $selectedItem, matching: .images) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.white)
                                    .frame(height: 200)
                                    .shadow(color: .black.opacity(0.05), radius: 10)
                                
                                if let image = selectedImage {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(height: 200)
                                        .clipShape(RoundedRectangle(cornerRadius: 20))
                                } else {
                                    VStack(spacing: 10) {
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 40))
                                            .foregroundColor(.appGreenMain)
                                        Text("点击添加照片")
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                        }
                        .onChange(of: selectedItem) { _, newItem in
                            Task {
                                if let data = try? await newItem?.loadTransferable(type: Data.self),
                                   let image = UIImage(data: data) {
                                    self.selectedImage = image
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer(minLength: 50)
                    
                    // 5. 保存按钮
                    Button(action: saveRecord) {
                        Text("保存记录")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.appGreenMain)
                            .clipShape(Capsule())
                            .shadow(color: .appGreenMain.opacity(0.4), radius: 10, y: 5)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
            }
        }
        .onAppear {
            // 计算奖励
            let bones = GameSystem.shared.calculateBones(distanceKm: distance)
            let items = GameSystem.shared.generateDrops(distanceKm: distance)
            
            // 简单动画延迟显示
            withAnimation(.spring().delay(0.5)) {
                self.earnedBones = bones
                self.foundItems = items
            }
        }
    }
    
    // 保存逻辑
    private func saveRecord() {
        // 更新 UserData (累加骨头币和物品)
        var currentUserData = dataManager.userData
        currentUserData.totalBones += earnedBones
        for item in foundItems {
            currentUserData.inventory[item.id, default: 0] += 1
        }
        currentUserData.lastWalkDate = Date()
        dataManager.updateUserData(currentUserData)
        
        // 1. 保存图片到本地
        var imageName: String?
        if let image = selectedImage {
            let fileName = "walk_\(UUID().uuidString).jpg"
            if let data = image.jpegData(compressionQuality: 0.8) {
                let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(fileName)
                try? data.write(to: url)
                imageName = fileName
            }
        }
        
        // 2. 创建记录对象
        let now = Date()
        let calendar = Calendar.current
        let day = calendar.component(.day, from: now)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM月dd日"
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        
        let record = WalkRecord(
            day: day,
            date: dateFormatter.string(from: now),
            time: timeFormatter.string(from: now),
            distance: distance,
            duration: Int(duration / 60),
            mood: mood,
            imageName: imageName,
            route: routeCoordinates, // 保存轨迹
            itemsFound: foundItems.map { $0.id }, // 保存物品ID
            bonesEarned: earnedBones // 保存骨头币
        )
        
        // 3. 存入 DataManager
        dataManager.addRecord(record)
        
        // 4. 关闭页面
        onFinish()
    }
    
    // 辅助格式化
    func formatDuration(_ interval: TimeInterval) -> String {
        return String(format: "%.0f", interval / 60)
    }
}

// 子组件
struct StatBox: View {
    let title: String
    let value: String
    let unit: String
    
    var body: some View {
        VStack(spacing: 5) {
            Text(title).font(.caption).foregroundColor(.gray)
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value).font(.system(size: 30, weight: .bold, design: .rounded)).foregroundColor(.appBrown)
                Text(unit).font(.caption).foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 10)
    }
}

struct MoodButton: View {
    let mood: String
    let icon: String
    let color: Color
    @Binding var selectedMood: String
    
    var isSelected: Bool { selectedMood == mood }
    
    var body: some View {
        Button(action: { selectedMood = mood }) {
            VStack {
                ZStack {
                    Circle()
                        .fill(isSelected ? color : Color.white)
                        .frame(width: 60, height: 60)
                        .shadow(color: isSelected ? color.opacity(0.4) : .black.opacity(0.05), radius: 8)
                    
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(isSelected ? .white : color)
                }
                Text(mood.capitalized)
                    .font(.caption)
                    .foregroundColor(isSelected ? color : .gray)
            }
        }
    }
}

