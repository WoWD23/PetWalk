//
//  HistoryView.swift
//  PetWalk
//
//  Created by 熊毓敏 on 2025/12/7.
//
import SwiftUI

struct HistoryView: View {
    // 1. 引入数据管理器 (Source of Truth)
    // 这里使用 @StateObject 初始化，确保数据只属于这个 View 的生命周期
    // 如果你希望整个 App 共享同一个数据源，也可以改用 @ObservedObject 并从外部传入
    // 1. 引入数据管理器 (Source of Truth)
    // 改用 @ObservedObject 并使用单例，确保数据同步
    @ObservedObject private var dataManager = DataManager.shared
    
    // 2. 交互状态：用于大图查看器
    @State private var selectedPhoto: String? = nil
    @State private var isPhotoViewerPresented = false
    
    // 统计详情页状态
    @State private var showStatsDetail = false
    @State private var selectedStatsType: StatsType = .distance
    
    // 选中记录以显示详情 (日历/热力图点击)
    @State private var selectedRecord: WalkRecord? = nil
    

    
    // 选中记录以仅显示日记 (日记模式点击)
    @State private var readingDiaryRecord: WalkRecord? = nil
    
    // 多记录选择 (当一天有多次记录时)
    @State private var dailySelection: DailySelection? = nil
    
    // 设置页
    @State private var showSettings = false
    
    // 辅助：加载本地图片
    func loadLocalImage(named name: String) -> UIImage? {
        // 1. 先尝试从 Assets 加载 (兼容旧数据)
        if let assetImage = UIImage(named: name) {
            return assetImage
        }
        
        // 2. 尝试从 Documents 目录加载
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(name)
        if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
            return image
        }
        
        return nil
    }

    var body: some View {
        NavigationView {
            ZStack {
                // 背景色
                Color.appBackground.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // --- 标题栏 ---
                    HStack {
                        Text("足迹")
                            .font(.system(size: 34, weight: .heavy, design: .rounded))
                            .foregroundColor(.appBrown)
                        Spacer()
                        
                        // 设置按钮
                        Button(action: { showSettings = true }) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.appBrown)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10) // 添加小的顶部间距，与其他页面保持一致
                    
                    // --- 滚动内容区 ---
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 25) {
                            
                            // A. 升级版日历卡片 (传入 live data)

                            PhotoCalendarCard(
                                records: dataManager.records,
                                onRecordTap: { records in
                                    if records.count == 1, let first = records.first {
                                        self.selectedRecord = first
                                    } else if records.count > 1 {
                                        self.dailySelection = DailySelection(records: records, isDiaryMode: false)
                                    }
                                },
                                onDiaryTap: { records in
                                    if records.count == 1, let first = records.first {
                                        self.readingDiaryRecord = first
                                    } else if records.count > 1 {
                                        self.dailySelection = DailySelection(records: records, isDiaryMode: true)
                                    }
                                }
                            )
                            
                            // B. 动态统计数据 (实时计算)
                            HStack(spacing: 15) {
                                // 计算总里程
                                let totalDist = dataManager.records.reduce(0) { $0 + $1.distance }
                                Button(action: {
                                    selectedStatsType = .distance
                                    showStatsDetail = true
                                }) {
                                    StatSummaryCard(
                                        title: "总里程",
                                        value: String(format: "%.1f", totalDist),
                                        unit: "km",
                                        icon: "map.fill"
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                // 计算总时长 (分钟转小时)
                                let totalMinutes = dataManager.records.reduce(0) { $0 + $1.duration }
                                let totalHours = Double(totalMinutes) / 60.0
                                Button(action: {
                                    selectedStatsType = .duration
                                    showStatsDetail = true
                                }) {
                                    StatSummaryCard(
                                        title: "总时长",
                                        value: String(format: "%.1f", totalHours),
                                        unit: "小时",
                                        icon: "clock.fill"
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding(.horizontal, 20)
                            
                            // C. 列表标题
                            HStack {
                                Text("近期记录")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundColor(.appBrown)
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 10)
                            
                            // D. 历史记录列表 (倒序排列，最新的在上面)
                            LazyVStack(spacing: 15) {
                                // 注意：WalkRecord 必须遵循 Identifiable，我们在 Model 里已经加了
                                ForEach(dataManager.records) { record in
                                    // 🟢 重点修改：用 NavigationLink 包裹
                                    NavigationLink(destination: WalkDetailView(record: record)) {
                                        WalkRecordCard(record: record)
                                    }
                                    .buttonStyle(PlainButtonStyle()) // 去掉默认的蓝色链接样式
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 100) // 防止被底部 TabBar 遮挡
                        }
                        .padding(.top, 10)
                }
                .sheet(item: $selectedRecord) { record in
                    NavigationView {
                        WalkDetailView(record: record)
                            .navigationBarItems(leading: Button("关闭") {
                                selectedRecord = nil
                            })
                    }
                    }
                }

                .sheet(item: $readingDiaryRecord) { record in
                    DiaryReadingView(record: record)
                }
                .sheet(item: $dailySelection) { selection in
                    NavigationView {
                        DailyRecordListView(selection: selection)
                    }
                }
                
                // --- 全屏大图查看器 (Overlay) ---
                if isPhotoViewerPresented, let photoName = selectedPhoto {
                    ZStack {
                        // 黑色半透明背景
                        Color.black.opacity(0.9).ignoresSafeArea()
                            .onTapGesture {
                                withAnimation { isPhotoViewerPresented = false }
                            }
                        
                        VStack {
                            // 显示图片
                            if let image = loadLocalImage(named: photoName) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxWidth: .infinity)
                                    .cornerRadius(20)
                                    .padding()
                                    .shadow(radius: 20)
                            } else {
                                // 加载失败占位
                                Image(systemName: "photo.badge.exclamationmark")
                                    .font(.system(size: 60))
                                    .foregroundColor(.gray)
                                    .padding()
                            }
                            
                            Text("那天的回忆")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.top, 10)
                        }
                    }
                    .transition(.opacity) // 淡入淡出效果
                    .zIndex(100) // 保证浮在最上层
                }
            }
            .navigationBarHidden(true) // 隐藏系统的 NavigationBar，使用我们自己的 Title
        }
        .fullScreenCover(isPresented: $showStatsDetail) {
            StatsDetailView(type: selectedStatsType)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }
}

// MARK: - 🧩 子组件 (Subviews)

// 0. 日历模式枚举
enum CalendarMode {
    case photo
    case diary
    case heatmap
    
    var title: String {
        switch self {
        case .photo: return "本月独家记忆"
        case .diary: return "狗狗心情日记"
        case .heatmap: return "运动热力图"
        }
    }
    
    var next: CalendarMode {
        switch self {
        case .photo: return .diary
        case .diary: return .heatmap
        case .heatmap: return .photo
        }
    }
}

// 1. 三态日历卡片容器

// 1. 三态日历卡片容器
struct PhotoCalendarCard: View {
    let records: [WalkRecord]
    var onRecordTap: ([WalkRecord]) -> Void
    var onDiaryTap: ([WalkRecord]) -> Void
    

    
    @State private var mode: CalendarMode = .photo
    
    // 辅助：加载本地图片
    func loadLocalImage(named name: String) -> UIImage? {
        if let assetImage = UIImage(named: name) { return assetImage }
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(name)
        if let data = try? Data(contentsOf: url), let image = UIImage(data: data) { return image }
        return nil
    }
    
    // 计算去重后的打卡天数
    var uniqueDaysCount: Int {
        let uniqueDates = Set(records.map { $0.date })
        return uniqueDates.count
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            // Header
            HStack {
                Text(mode.title)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.appBrown)
                
                Spacer()
                
                // 切换按钮
                Button(action: {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        mode = mode.next
                    }
                }) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.appGreenDark)
                        .padding(8)
                        .background(Color.appGreenMain.opacity(0.1))
                        .clipShape(Circle())
                }
                
                Text("已打卡 \(uniqueDaysCount) 天")
                    .font(.caption)
                    .foregroundColor(.appGreenDark)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.appGreenMain.opacity(0.2))
                    .clipShape(Capsule())
            }
            
            // Content Area
            ZStack {
                switch mode {
                case .photo:
                    PhotoGridView(records: records, loadLocalImage: loadLocalImage, onRecordTap: onRecordTap)
                        .transition(.opacity)
                case .diary:
                    DiaryGridView(records: records, onRecordTap: onDiaryTap)
                        .transition(.opacity)
                case .heatmap:
                    HeatmapGridView(records: records, onRecordTap: onRecordTap)
                        .transition(.opacity)
                }
            }
            // 移除 3D 翻转效果，改为淡入淡出，因为是三态切换
            .animation(.easeInOut(duration: 0.3), value: mode)
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        .padding(.horizontal, 20)
    }
}


// 正面：照片网格
struct PhotoGridView: View {
    let records: [WalkRecord]
    let loadLocalImage: (String) -> UIImage?
    let onRecordTap: ([WalkRecord]) -> Void
    
    let columns = Array(repeating: GridItem(.flexible()), count: 7)
    
    func getRecords(for day: Int) -> [WalkRecord] {
        records.filter { $0.day == day }
    }
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(["日", "一", "二", "三", "四", "五", "六"], id: \.self) { day in
                Text(day).font(.system(size: 10, weight: .bold)).foregroundColor(.appBrown.opacity(0.4))
            }
            
            ForEach(1...30, id: \.self) { day in
                let dailyRecords = getRecords(for: day)
                let record = dailyRecords.last // 显示最新的
                
                ZStack {
                    if let record = record {
                        // 有记录
                        if let imageName = record.imageName, !imageName.isEmpty {
                            // 有照片
                            if let uiImage = loadLocalImage(imageName) {
                                Image(uiImage: uiImage).resizable().scaledToFill()
                                    .frame(width: 36, height: 36)
                                    .clipShape(Circle())
                            } else {
                                Color.gray
                                    .frame(width: 36, height: 36)
                                    .clipShape(Circle())
                            }
                        } else {
                            // 无照片，显示图标
                            ZStack {
                                Circle().fill(Color.appGreenMain).frame(height: 36)
                                if let diary = record.aiDiary, !diary.isEmpty {
                                    Image(systemName: "book.closed.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white)
                                } else {
                                    Image(systemName: "pawprint.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        

                    } else {
                        // 无记录
                        Circle().fill(Color.gray.opacity(0.1)).frame(height: 36)
                        Text("\(day)").font(.system(size: 10)).foregroundColor(.gray)
                    }
                }
                .onTapGesture {
                    if !dailyRecords.isEmpty {
                        withAnimation { onRecordTap(dailyRecords) }
                    }
                }
            }
        }
    }
}

// 背面：纯色热力图
struct HeatmapGridView: View {
    let records: [WalkRecord]
    // 增加点击回调
    var onRecordTap: (([WalkRecord]) -> Void)? = nil
    
    let columns = Array(repeating: GridItem(.flexible()), count: 7)
    
    // 获取某天的总距离
    func getDailyDistance(day: Int) -> Double {
        records.filter { $0.day == day }.reduce(0) { $0 + $1.distance }
    }
    
    // 根据距离返回颜色深度
    func getColor(for distance: Double) -> Color {
        if distance == 0 { return Color.gray.opacity(0.1) }
        if distance < 1.0 { return Color.appGreenMain.opacity(0.3) } // 小遛
        if distance < 3.0 { return Color.appGreenMain.opacity(0.6) } // 中遛
        return Color.appGreenMain // 大遛
    }
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(["日", "一", "二", "三", "四", "五", "六"], id: \.self) { day in
                Text(day).font(.system(size: 10, weight: .bold)).foregroundColor(.appBrown.opacity(0.4))
            }
            
            ForEach(1...30, id: \.self) { day in
                let distance = getDailyDistance(day: day)
                
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(getColor(for: distance))
                        .frame(height: 36)
                    
                    if distance > 0 {
                        Text(String(format: "%.1f", distance))
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(distance > 3.0 ? .white : .appBrown)
                    } else {
                        Text("\(day)").font(.system(size: 10)).foregroundColor(.gray)
                    }
                }
                .onTapGesture {
                    // 找到当天的所有记录并回调
                    let dailyRecords = records.filter { $0.day == day }
                    if !dailyRecords.isEmpty {
                        onRecordTap?(dailyRecords)
                    }
                }
            }
        }
    }
}

// 2. 统计数据小卡片
struct StatSummaryCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.appGreenDark)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                    .foregroundColor(.appBrown)
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(15)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
}

// 3. 历史记录列表项卡片
struct WalkRecordCard: View {
    let record: WalkRecord
    
    var body: some View {
        HStack {
            // 左侧：日期块
            VStack {
                Text(record.date)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.appGreenMain)
                    .cornerRadius(8)
                Text(record.time)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .frame(width: 60)
            
            // 中间：详情
            VStack(alignment: .leading, spacing: 4) {
                Text("\(String(format: "%.1f", record.distance)) km")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.appBrown)
                
                HStack(spacing: 10) {
                    let durationText = record.duration == 0 ? "< 1 分钟" : "\(record.duration) 分钟"
                    Label(durationText, systemImage: "timer")
                    
                    // 如果有照片，显示个小图标提示
                    if let img = record.imageName, !img.isEmpty {
                        Label("有照片", systemImage: "photo.fill")
                            .foregroundColor(.orange)
                    }
                    if let diary = record.aiDiary, !diary.isEmpty {
                        Label("有日记", systemImage: "book.closed.fill")
                            .foregroundColor(.appBrown)
                    }
                }
                .font(.caption2)
                .foregroundColor(.gray)
            }
            
            Spacer()
            
            // 右侧：心情图标
            ZStack {
                Circle()
                    .fill(Color.appBackground)
                    .frame(width: 44, height: 44)
                
                Image(systemName: record.mood == "happy" ? "face.smiling.fill" : "zzz")
                    .foregroundColor(record.mood == "happy" ? .orange : .blue)
                    .font(.system(size: 24))
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
    }
}

// 新增：日记模式网格
struct DiaryGridView: View {
    let records: [WalkRecord]
    var onRecordTap: (([WalkRecord]) -> Void)? = nil
    
    let columns = Array(repeating: GridItem(.flexible()), count: 7)
    
    func getRecords(for day: Int) -> [WalkRecord] {
        records.filter { $0.day == day }
    }
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(["日", "一", "二", "三", "四", "五", "六"], id: \.self) { day in
                Text(day).font(.system(size: 10, weight: .bold)).foregroundColor(.appBrown.opacity(0.4))
            }
            
            ForEach(1...30, id: \.self) { day in
                let dailyRecords = getRecords(for: day)
                let hasDiary = dailyRecords.contains { $0.aiDiary != nil && !$0.aiDiary!.isEmpty }
                
                ZStack {
                    if hasDiary {
                        // 有日记
                        // 根据日记数量决定颜色深浅：数量越多颜色越深
                        let opacity = min(0.1 + Double(dailyRecords.count - 1) * 0.15, 0.5)
                        Circle()
                            .fill(Color.appBrown.opacity(opacity))
                            .frame(height: 36)
                        
                        Image(systemName: "book.closed.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.appBrown)
                    } else if !dailyRecords.isEmpty {
                        // 有记录但没日记
                         Circle()
                            .fill(Color.gray.opacity(0.1))
                            .frame(height: 36)
                        Image(systemName: "pawprint.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.gray.opacity(0.5))
                    } else {
                        // 无记录
                        Circle().fill(Color.gray.opacity(0.05)).frame(height: 36)
                        Text("\(day)").font(.system(size: 10)).foregroundColor(.gray.opacity(0.5))
                    }
                }
                .onTapGesture {
                    if hasDiary {
                        onRecordTap?(dailyRecords)
                    }
                }
            }
        }
    }
}

// 辅助结构：多记录选择
struct DailySelection: Identifiable {
    let id = UUID()
    let records: [WalkRecord]
    let isDiaryMode: Bool
}

// 新增：每日记录清单（当一天多次遛狗时）
struct DailyRecordListView: View {
    let selection: DailySelection
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        List {
            ForEach(selection.records) { record in
                NavigationLink(destination: destinationView(for: record)) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(record.time)
                                .font(.headline)
                                .foregroundColor(.appBrown)
                            Text("\(String(format: "%.1f", record.distance)) km • \(record.duration) min")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        if let diary = record.aiDiary, !diary.isEmpty {
                            Image(systemName: "book.closed.fill")
                                .foregroundColor(.appBrown)
                        } else {
                            Image(systemName: "pawprint.fill")
                                .foregroundColor(.gray.opacity(0.5))
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle(selection.isDiaryMode ? "选择日记" : "选择记录")
        .navigationBarItems(trailing: Button("关闭") {
            presentationMode.wrappedValue.dismiss()
        })
    }
    
    @ViewBuilder
    func destinationView(for record: WalkRecord) -> some View {
        if selection.isDiaryMode {
            DiaryReadingView(record: record)
        } else {
            WalkDetailView(record: record)
        }
    }
}

// 新增：专注日记阅读视图
struct DiaryReadingView: View {
    let record: WalkRecord
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            VStack {
                // Header
                HStack {
                    Spacer()
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                    .padding()
                }
                
                ScrollView {
                    VStack(spacing: 20) {
                        Text(record.date)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        Text("🐶 狗狗日记")
                            .font(.title2)
                            .bold()
                            .foregroundColor(.appBrown)
                        
                        if let diary = record.aiDiary {
                            Text(diary)
                                .font(.system(.body, design: .serif))
                                .lineSpacing(8)
                                .foregroundColor(.primary)
                                .padding(30)
                                .background(Color.white)
                                .cornerRadius(20)
                                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
                        } else {
                            Text("这天没有写日记哦")
                                .italic()
                                .foregroundColor(.gray)
                        }
                    }
                    .padding()
                    .padding(.bottom, 50)
                }
            }
        }
    }
}

// 预览
#Preview {
    HistoryView()
}
