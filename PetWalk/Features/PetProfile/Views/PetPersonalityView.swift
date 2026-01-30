//
//  PetPersonalityView.swift
//  PetWalk
//
//  Created by User on 2026/01/30.
//

import SwiftUI

struct PetPersonalityView: View {
    @Binding var personality: PetPersonality
    
    // Sliders
    var body: some View {
        VStack(spacing: 24) {
            Text("第二步：性格标签系统")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.appBrown)
            
            // Energy
            personalitySlider(
                title: "⚡️ 能量值",
                value: $personality.energyLevel,
                lowText: "懒狗(Couch Potato)",
                highText: "永动机(High Energy)"
            )
            
            // Social
            personalitySlider(
                title: "🤝 社交度",
                value: $personality.socialLevel,
                lowText: "社恐(Shy)",
                highText: "社牛(Friendly)"
            )
            
            // Obedience
            personalitySlider(
                title: "🎓 服从度",
                value: $personality.obedienceLevel,
                lowText: "叛逆(Stubborn)",
                highText: "听话(Obedient)"
            )
            
            // Foodie
            personalitySlider(
                title: "🍗 贪吃度",
                value: $personality.foodieLevel,
                lowText: "挑食(Picky)",
                highText: "饭桶(Foodie)"
            )
            
            // Tags (Optional - can be added later)
            // But let's add a placeholder text if user wants to add custom tags?
            // "还有什么个性特点？" (TextField)
            
            Spacer()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(radius: 5)
        .padding()
    }
    
    private func personalitySlider(title: String, value: Binding<Double>, lowText: String, highText: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.appBrown)
                Spacer()
                // Show current value label briefly? Or just rely on visual position + low/high text
                if value.wrappedValue < 0.3 {
                    Text(lowText.split(separator: "(").first ?? "")
                        .font(.caption)
                        .foregroundColor(.blue)
                } else if value.wrappedValue > 0.7 {
                    Text(highText.split(separator: "(").first ?? "")
                        .font(.caption)
                        .foregroundColor(.green)
                } else {
                    Text("适中")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Slider(value: value, in: 0...1)
                .accentColor(.appBrown)
            
            HStack {
                Text(lowText)
                    .font(.caption2)
                    .foregroundColor(.gray)
                Spacer()
                Text(highText)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
    }
}
