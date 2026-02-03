//
//  PetWalkLiveActivity.swift
//  PetWalk
//
//  Created by Cursor AI Assistant on 2026/01/31.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct PetWalkLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PetWalkAttributes.self) { context in
            // Lock Screen / Banner View
            LockScreenView(state: context.state, petName: context.attributes.petName)
                .activityBackgroundTint(Color.black.opacity(0.85))
                .activitySystemActionForegroundColor(Color.white)
                
        } dynamicIsland: { context in
            DynamicIsland {
                // MARK: - Expanded UI
                
                // Leading: 宠物图标
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 4) {
                        Image(systemName: "pawprint.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.orange)
                    }
                }
                
                // Trailing: 距离
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(String(format: "%.2f", context.state.distance))
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.green)
                        Text("公里")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
                
                // Center: 宠物名
                DynamicIslandExpandedRegion(.center) {
                    Text(context.attributes.petName)
                        .font(.headline)
                        .foregroundColor(.white)
                }
                
                // Bottom: 时长和速度
                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 20) {
                        // 时长
                        HStack(spacing: 4) {
                            Image(systemName: "timer")
                                .foregroundColor(.cyan)
                            Text(formatDuration(context.state.duration))
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.white)
                        }
                        
                        // 速度
                        HStack(spacing: 4) {
                            Image(systemName: "speedometer")
                                .foregroundColor(.yellow)
                            Text(String(format: "%.1f km/h", context.state.currentSpeed))
                                .font(.system(.body, design: .rounded))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.top, 4)
                }
                
            } compactLeading: {
                // MARK: - Compact Leading: 爪印图标
                Image(systemName: "pawprint.fill")
                    .foregroundColor(.orange)
            } compactTrailing: {
                // MARK: - Compact Trailing: 距离
                Text(String(format: "%.1f", context.state.distance))
                    .font(.system(.body, design: .rounded).bold())
                    .foregroundColor(.green)
            } minimal: {
                // MARK: - Minimal: 简单爪印
                Image(systemName: "pawprint.fill")
                    .foregroundColor(.orange)
            }
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - Lock Screen View
private struct LockScreenView: View {
    let state: PetWalkAttributes.ContentState
    let petName: String
    
    var body: some View {
        HStack(spacing: 12) {
            // 左侧：宠物图标
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.3))
                    .frame(width: 50, height: 50)
                Image(systemName: "pawprint.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.orange)
            }
            
            // 中间：宠物名和状态
            VStack(alignment: .leading, spacing: 4) {
                Text(petName)
                    .font(.headline)
                    .foregroundColor(.white)
                Text(state.isMoving ? "遛狗中..." : "已暂停")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // 右侧：距离和时长
            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: "%.2f km", state.distance))
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.green)
                Text(formatDuration(state.duration))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
