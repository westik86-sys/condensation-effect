//
//  FogOverlayView.swift
//  condensation-effect
//
//  Created by Pavel Korostelev on 24.03.2026.
//

import SwiftUI

struct FogOverlayView: View {
    var body: some View {
        Rectangle()
            .fill(.white.opacity(0.08))
            .overlay {
                RoundedRectangle(cornerRadius: 28)
                    .stroke(.white.opacity(0.18), lineWidth: 1)
                    .padding(24)
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)
    }
}

struct FogOverlayView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            FogOverlayView()
        }
    }
}
