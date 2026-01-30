//
//  OnboardingView.swift
//  PetWalk
//
//  Created by Cursor AI on 2026/1/29.
//

import SwiftUI

struct OnboardingView: View {
    // Callback when onboarding is complete
    var onComplete: () -> Void
    
    var body: some View {
        // Use the new Pet Profile Setup flow
        PetProfileSetupView(onComplete: onComplete)
    }
}

#Preview {
    OnboardingView(onComplete: {})
}
