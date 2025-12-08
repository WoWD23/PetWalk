//
//  InventoryView.swift
//  PetWalk
//
//  Created by Cursor AI on 2025/12/8.
//

import SwiftUI

struct InventoryView: View {
    @ObservedObject var dataManager = DataManager.shared
    
    // 所有的物品列表 (用于渲染网格)
    let allItems = TreasureItem.allItems
    
    // 选中的物品用于弹窗
    @State private var selectedItem: TreasureItem?
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // 物品网格
                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(allItems) { item in
                                let count = dataManager.userData.inventory[item.id] ?? 0
                                let isUnlocked = count > 0
                                
                                Button(action: {
                                    if isUnlocked {
                                        selectedItem = item
                                    }
                                }) {
                                    VStack(spacing: 10) {
                                        ZStack {
                                            Circle()
                                                .fill(isUnlocked ? Color.white : Color.gray.opacity(0.1))
                                                .frame(width: 80, height: 80)
                                                .shadow(color: isUnlocked ? item.rarity.color.opacity(0.3) : .clear, radius: 8)
                                            
                                            Image(systemName: item.iconName)
                                                .font(.system(size: 36))
                                                .foregroundColor(isUnlocked ? item.rarity.color : .gray)
                                        }
                                        
                                        Text(isUnlocked ? item.name : "???")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundColor(isUnlocked ? .appBrown : .gray)
                                        
                                        if isUnlocked {
                                            Text("x\(count)")
                                                .font(.caption2)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                }
                                .disabled(!isUnlocked)
                            }
                        }
                        .padding()
                    }
                }
                .navigationTitle("收藏柜")
            }
            .sheet(item: $selectedItem) { item in
                ItemDetailView(item: item)
                    .presentationDetents([.fraction(0.4)])
            }
        }
    }
}

// 物品详情弹窗
struct ItemDetailView: View {
    let item: TreasureItem
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image(systemName: item.iconName)
                    .font(.system(size: 80))
                    .foregroundColor(item.rarity.color)
                    .padding()
                    .background(
                        Circle()
                            .fill(Color.white)
                            .shadow(color: item.rarity.color.opacity(0.3), radius: 20)
                    )
                
                VStack(spacing: 5) {
                    Text(item.name)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.appBrown)
                    
                    Text(item.rarity.title)
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(item.rarity.color.opacity(0.2))
                        .foregroundColor(item.rarity.color)
                        .cornerRadius(8)
                }
                
                Text(item.description)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.gray)
                    .padding(.horizontal)
                
                Spacer()
            }
            .padding(.top, 40)
        }
    }
}

