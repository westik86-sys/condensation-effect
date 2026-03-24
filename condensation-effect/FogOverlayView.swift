//
//  FogOverlayView.swift
//  condensation-effect
//
//  Created by Pavel Korostelev on 24.03.2026.
//

import SwiftUI

struct FogOverlayView: View {
    var body: some View {
        ZStack {
            Rectangle()
                .fill(.white.opacity(0.12))

            LinearGradient(
                colors: [
                    .white.opacity(0.18),
                    .white.opacity(0.08),
                    .white.opacity(0.14)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(.white.opacity(0.16))
                .frame(width: 260, height: 260)
                .blur(radius: 70)
                .offset(x: -110, y: -220)

            Circle()
                .fill(.white.opacity(0.12))
                .frame(width: 340, height: 340)
                .blur(radius: 90)
                .offset(x: 130, y: -40)

            Circle()
                .fill(.white.opacity(0.14))
                .frame(width: 280, height: 280)
                .blur(radius: 80)
                .offset(x: -30, y: 260)
        }
        .overlay {
            LinearGradient(
                colors: [
                    .white.opacity(0.08),
                    .clear,
                    .white.opacity(0.05)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .compositingGroup()
        .blur(radius: 8)
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
