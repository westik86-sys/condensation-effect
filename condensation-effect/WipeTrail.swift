//
//  WipeTrail.swift
//  condensation-effect
//
//  Created by Pavel Korostelev on 24.03.2026.
//

import CoreGraphics
import Foundation

struct WipeStamp: Identifiable {
    let id = UUID()
    let location: CGPoint
    let radius: CGFloat
}

struct WipeTrail {
    private(set) var stamps: [WipeStamp] = []

    mutating func appendStamp(at location: CGPoint, radius: CGFloat = 24, minimumSpacing: CGFloat = 12) {
        if let lastStamp = stamps.last {
            let deltaX = location.x - lastStamp.location.x
            let deltaY = location.y - lastStamp.location.y
            let distance = sqrt((deltaX * deltaX) + (deltaY * deltaY))

            guard distance >= minimumSpacing else { return }
        }

        stamps.append(WipeStamp(location: location, radius: radius))
    }
}
