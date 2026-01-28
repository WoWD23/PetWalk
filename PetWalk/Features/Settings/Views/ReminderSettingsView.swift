//
//  ReminderSettingsView.swift
//  PetWalk
//
//  Created by Cursor AI on 2026/1/28.
//

import SwiftUI

/// 提醒设置视图
struct ReminderSettingsView: View {
    @ObservedObject var dataManager = DataManager.shared
    @ObservedObject var notificationManager = NotificationManager.shared
    @Environment(\.dismiss) var dismiss
    
    @State private var reminderEnabled: Bool = false
    @State private var reminderTime: Date = Date()
    @State private var showingTimePicker = false
    @State private var showPermissionAlert = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // 权限状态卡片
                        permissionCard
                        
                        // 每日提醒设置
                        dailyReminderCard
                        
                        // 通知预览
                        if reminderEnabled {
                            notificationPreviewCard
                        }
                        
                        // 说明文字
                        infoSection
                    }
                    .padding()
                }
            }
            .navigationTitle("遛狗提醒")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        saveSettings()
                        dismiss()
                    }
                    .foregroundColor(.appGreenMain)
                }
            }
            .onAppear {
                loadSettings()
            }
            .alert("需要通知权限", isPresented: $showPermissionAlert) {
                Button("去设置") {
                    notificationManager.openSettings()
                }
                Button("取消", role: .cancel) {
                    reminderEnabled = false
                }
            } message: {
                Text("请在设置中开启通知权限，以便接收遛狗提醒。")
            }
        }
    }
    
    // MARK: - 权限状态卡片
    
    private var permissionCard: some View {
        HStack(spacing: 15) {
            ZStack {
                Circle()
                    .fill(notificationManager.isAuthorized ? Color.green.opacity(0.15) : Color.orange.opacity(0.15))
                    .frame(width: 50, height: 50)
                
                Image(systemName: notificationManager.isAuthorized ? "bell.badge.fill" : "bell.slash.fill")
                    .font(.system(size: 22))
                    .foregroundColor(notificationManager.isAuthorized ? .green : .orange)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("通知权限")
                    .font(.headline)
                    .foregroundColor(.appBrown)
                
                Text(notificationManager.isAuthorized ? "已开启" : "未开启")
                    .font(.caption)
                    .foregroundColor(notificationManager.isAuthorized ? .green : .orange)
            }
            
            Spacer()
            
            if !notificationManager.isAuthorized {
                Button("开启") {
                    Task {
                        let granted = await notificationManager.requestAuthorization()
                        if !granted {
                            showPermissionAlert = true
                        }
                    }
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.appGreenMain)
                .clipShape(Capsule())
            }
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
    
    // MARK: - 每日提醒卡片
    
    private var dailyReminderCard: some View {
        VStack(spacing: 0) {
            // 开关
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("每日遛狗提醒")
                        .font(.headline)
                        .foregroundColor(.appBrown)
                    
                    Text("每天在设定时间提醒你遛狗")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Toggle("", isOn: $reminderEnabled)
                    .labelsHidden()
                    .tint(.appGreenMain)
                    .onChange(of: reminderEnabled) { oldValue, newValue in
                        if newValue && !notificationManager.isAuthorized {
                            Task {
                                let granted = await notificationManager.requestAuthorization()
                                if !granted {
                                    reminderEnabled = false
                                    showPermissionAlert = true
                                }
                            }
                        }
                    }
            }
            .padding()
            
            if reminderEnabled {
                Divider()
                    .padding(.horizontal)
                
                // 时间选择
                HStack {
                    Text("提醒时间")
                        .font(.subheadline)
                        .foregroundColor(.appBrown)
                    
                    Spacer()
                    
                    DatePicker(
                        "",
                        selection: $reminderTime,
                        displayedComponents: .hourAndMinute
                    )
                    .labelsHidden()
                    .datePickerStyle(.compact)
                }
                .padding()
            }
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
    
    // MARK: - 通知预览卡片
    
    private var notificationPreviewCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("通知预览")
                .font(.headline)
                .foregroundColor(.appBrown)
            
            // 模拟通知
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 10) {
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.appGreenMain)
                        .frame(width: 40, height: 40)
                        .background(Color.appGreenMain.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text("PetWalk 遛狗提醒")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Spacer()
                            Text(formatTime(reminderTime))
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        Text("汪！该带我出去遛弯啦～ 🐕")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
    
    // MARK: - 说明文字
    
    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("关于提醒")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.gray)
            
            Text("• 每天会在设定时间发送一条遛狗提醒\n• 通知文案会随机变化，增加趣味性\n• 如果当天已经遛过狗，仍会收到提醒\n• 你可以随时在这里关闭提醒")
                .font(.caption)
                .foregroundColor(.gray.opacity(0.8))
                .lineSpacing(4)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - 辅助方法
    
    private func loadSettings() {
        reminderEnabled = dataManager.userData.dailyReminderEnabled
        reminderTime = dataManager.userData.dailyReminderTime
    }
    
    private func saveSettings() {
        Task {
            await notificationManager.updateDailyReminder(
                enabled: reminderEnabled,
                time: reminderTime
            )
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - 设置主页面（包含所有设置项入口）
struct SettingsView: View {
    @ObservedObject var dataManager = DataManager.shared
    @Environment(\.dismiss) var dismiss
    
    @State private var showReminderSettings = false
    @State private var showAbout = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                
                List {
                    // 通知设置
                    Section {
                        Button {
                            showReminderSettings = true
                        } label: {
                            SettingsRow(
                                icon: "bell.fill",
                                iconColor: .orange,
                                title: "遛狗提醒",
                                subtitle: dataManager.userData.dailyReminderEnabled ? "已开启" : "未开启"
                            )
                        }
                    } header: {
                        Text("通知")
                    }
                    
                    // 数据管理
                    Section {
                        SettingsRow(
                            icon: "icloud.fill",
                            iconColor: .blue,
                            title: "数据同步",
                            subtitle: "iCloud"
                        )
                        
                        SettingsRow(
                            icon: "square.and.arrow.up.fill",
                            iconColor: .green,
                            title: "导出数据",
                            subtitle: ""
                        )
                    } header: {
                        Text("数据")
                    }
                    
                    // 关于
                    Section {
                        SettingsRow(
                            icon: "info.circle.fill",
                            iconColor: .gray,
                            title: "关于 PetWalk",
                            subtitle: "版本 1.0.0"
                        )
                        
                        SettingsRow(
                            icon: "star.fill",
                            iconColor: .yellow,
                            title: "给我们评分",
                            subtitle: ""
                        )
                    } header: {
                        Text("关于")
                    }
                }
                .listStyle(.insetGrouped)
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { dismiss() }
                        .foregroundColor(.appGreenMain)
                }
            }
            .sheet(isPresented: $showReminderSettings) {
                ReminderSettingsView()
            }
        }
    }
}

// MARK: - 设置行组件
struct SettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(iconColor)
                .frame(width: 30, height: 30)
                .background(iconColor.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            
            Text(title)
                .foregroundColor(.primary)
            
            Spacer()
            
            if !subtitle.isEmpty {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.gray.opacity(0.5))
        }
        .contentShape(Rectangle())
    }
}

#Preview {
    ReminderSettingsView()
}
