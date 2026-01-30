//
//  PetVoiceView.swift
//  PetWalk
//
//  Created by User on 2026/01/30.
//

import SwiftUI

struct PetVoiceView: View {
    @Binding var voiceStyle: PetVoiceStyle
    
    var body: some View {
        VStack(spacing: 24) {
            Text("第三步：AI 语气包")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.appBrown)
            
            VStack(alignment: .leading, spacing: 16) {
                ForEach(PetVoiceStyle.allCases) { style in
                    voiceCard(style: style)
                }
            }
            
            // Example Preview
            HStack {
                Text("试听效果：")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Spacer()
            }
            Text(voiceStyle.example)
                .font(.body)
                .padding()
                .background(Color.white.opacity(0.8))
                .cornerRadius(12)
                .shadow(radius: 2)
            
            Spacer()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(radius: 5)
        .padding()
    }
    
    private func voiceCard(style: PetVoiceStyle) -> some View {
        Button {
            withAnimation {
                voiceStyle = style
            }
        } label: {
            HStack(spacing: 16) {
                // Radio Button
                Image(systemName: voiceStyle == style ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(voiceStyle == style ? .appGreenMain : .gray)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(style.rawValue)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(style.description)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(2)
                }
                Spacer()
            }
            .padding()
            .background(voiceStyle == style ? Color.appGreenMain.opacity(0.1) : Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(voiceStyle == style ? Color.appGreenMain : Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
    }
}
