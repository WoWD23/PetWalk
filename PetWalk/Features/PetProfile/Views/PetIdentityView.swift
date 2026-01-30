//
//  PetIdentityView.swift
//  PetWalk
//
//  Created by User on 2026/01/30.
//

import SwiftUI

struct PetIdentityView: View {
    @Binding var name: String
    @Binding var ownerNickname: String
    @Binding var profile: PetProfile
    
    var body: some View {
        VStack(spacing: 24) {
            Text("第一步：填写基础档案")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.appBrown)
            
            // Name Input
            VStack(alignment: .leading) {
                Text("它的名字")
                    .font(.headline)
                    .foregroundColor(.gray)
                TextField("例如：旺财", text: $name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.bottom, 8)
            }
            
            // Owner Nickname
            VStack(alignment: .leading) {
                Text("它怎么称呼你？")
                    .font(.headline)
                    .foregroundColor(.gray)
                TextField("例如：爸爸、妈妈、长官", text: $ownerNickname)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            // Gender
            VStack(alignment: .leading) {
                Text("性别")
                    .font(.headline)
                    .foregroundColor(.gray)
                
                HStack {
                    ForEach(PetGender.allCases) { gender in
                        Button {
                            withAnimation {
                                profile.gender = gender
                            }
                        } label: {
                            HStack {
                                Text(gender.icon)
                                Text(gender.rawValue)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(profile.gender == gender ? Color.appGreenMain : Color.gray.opacity(0.1))
                            .foregroundColor(profile.gender == gender ? .white : .primary)
                            .cornerRadius(20)
                        }
                    }
                }
            }
            
            // Breed
            VStack(alignment: .leading) {
                Text("品种 (Breed)")
                    .font(.headline)
                    .foregroundColor(.gray)
                TextField("例如：柯基、金毛...", text: $profile.breed)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            // Birthday
            VStack(alignment: .leading) {
                Text("生日/年龄")
                    .font(.headline)
                    .foregroundColor(.gray)
                DatePicker("", selection: $profile.birthday, displayedComponents: .date)
                    .datePickerStyle(CompactDatePickerStyle())
                    .labelsHidden()
                
                Text("当前阶段：\(profile.ageGroup.rawValue) (\(profile.ageGroup.description))")
                    .font(.caption)
                    .foregroundColor(.appBrown)
                    .padding(.top, 4)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(radius: 5)
        .padding()
    }
}
