//
//  ContentView.swift
//  condensation-effect
//
//  Created by Pavel Korostelev on 24.03.2026.
//

import Combine
import SwiftUI

struct ContentView: View {
    @State private var wipeTrail = WipeTrail()
    @State private var currentTouchLocation: CGPoint?
    @State private var refogDate = Date()
    @State private var isTrackingTouch = false

    private let refogTimer = Timer.publish(every: 0.2, on: .main, in: .common).autoconnect()

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

            FogOverlayView(
                wipeTrail: wipeTrail,
                refogDate: refogDate,
                touchLocation: currentTouchLocation,
                onTouchChanged: { location in
                    wipeTrail.appendStamp(at: location, isContinuation: isTrackingTouch)
                    currentTouchLocation = location
                    isTrackingTouch = true
                },
                onTouchEnded: {
                    currentTouchLocation = nil
                    isTrackingTouch = false
                }
            )
        }
        .onReceive(refogTimer) { date in
            refogDate = date
            wipeTrail.removeExpiredStamps(at: date)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
