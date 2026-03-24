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
    let createdAt: Date
}

struct WipeTrail {
    private(set) var stamps: [WipeStamp] = []
    let refogDuration: TimeInterval = 12

    mutating func appendStamp(at location: CGPoint, radius: CGFloat = 24, minimumSpacing: CGFloat = 12) {
        if let lastStamp = stamps.last {
            let deltaX = location.x - lastStamp.location.x
            let deltaY = location.y - lastStamp.location.y
            let distance = sqrt((deltaX * deltaX) + (deltaY * deltaY))

            guard distance >= minimumSpacing else { return }
        }

        stamps.append(WipeStamp(location: location, radius: radius, createdAt: Date()))
    }

    mutating func removeExpiredStamps(at date: Date = Date()) {
        let refogDuration = refogDuration
        stamps.removeAll { stamp in
            let elapsed = date.timeIntervalSince(stamp.createdAt)
            let progress = min(max(elapsed / refogDuration, 0), 1)
            return (1 - progress) <= 0
        }
    }

    func strength(for stamp: WipeStamp, at date: Date = Date()) -> CGFloat {
        let elapsed = date.timeIntervalSince(stamp.createdAt)
        let progress = min(max(elapsed / refogDuration, 0), 1)
        return 1 - progress
    }
}
