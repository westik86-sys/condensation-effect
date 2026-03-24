//
//  ContentView.swift
//  condensation-effect
//
//  Created by Pavel Korostelev on 24.03.2026.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack {
            Color(red: 0.10, green: 0.14, blue: 0.18)
                .ignoresSafeArea()

            VStack(spacing: 8) {
                Text("Fogged Glass")
                    .font(.largeTitle.weight(.semibold))
                    .foregroundStyle(.white)

                Text("Prototype base layer")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.75))
            }
            .multilineTextAlignment(.center)

            FogOverlayView()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
