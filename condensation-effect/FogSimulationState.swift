//
//  FogSimulationState.swift
//  condensation-effect
//
//  Created by Pavel Korostelev on 24.03.2026.
//

import CoreGraphics
import Foundation
import simd

struct FogSimulationState {
    private let width = 160
    private let height = 320

    private(set) var wipeInfluence: [Float]
    private(set) var wetEdge: [Float]
    private(set) var wipeMaskImage: CGImage?
    private(set) var wetEdgeImage: CGImage?

    private var lastTouchPoint: SIMD2<Float>?

    init() {
        let pixelCount = width * height
        wipeInfluence = Array(repeating: 0, count: pixelCount)
        wetEdge = Array(repeating: 0, count: pixelCount)
    }

    mutating func applyTouch(at location: CGPoint, in size: CGSize, isContinuation: Bool) {
        guard size.width > 0, size.height > 0 else { return }

        let normalizedPoint = SIMD2<Float>(
            Float(location.x / size.width),
            Float(location.y / size.height)
        )

        if isContinuation, let previousPoint = lastTouchPoint {
            stampSegment(from: previousPoint, to: normalizedPoint)
        } else {
            stamp(at: normalizedPoint)
        }

        lastTouchPoint = normalizedPoint
        rebuildImages()
    }

    mutating func endInteraction() {
        lastTouchPoint = nil
    }

    mutating func advance(by deltaTime: TimeInterval) {
        guard deltaTime > 0 else { return }

        let wipeDecay = Float(deltaTime / 12.0)
        let wetEdgeDecay = Float(deltaTime / 6.0)
        var hasChanges = false

        for index in wipeInfluence.indices {
            let nextWipeValue = max(0, wipeInfluence[index] - wipeDecay)
            let nextWetEdgeValue = max(0, wetEdge[index] - wetEdgeDecay)

            hasChanges = hasChanges || nextWipeValue != wipeInfluence[index] || nextWetEdgeValue != wetEdge[index]
            wipeInfluence[index] = nextWipeValue
            wetEdge[index] = nextWetEdgeValue
        }

        if hasChanges {
            rebuildImages()
        }
    }

    private mutating func stampSegment(from start: SIMD2<Float>, to end: SIMD2<Float>) {
        let delta = end - start
        let distance = simd_length(delta)
        let stepCount = max(1, Int(ceil(distance * 220)))

        for step in 0...stepCount {
            let progress = Float(step) / Float(stepCount)
            let point = start + (delta * progress)
            stamp(at: point)
        }
    }

    private mutating func stamp(at normalizedPoint: SIMD2<Float>) {
        let clampedPoint = SIMD2<Float>(
            min(max(normalizedPoint.x, 0), 1),
            min(max(normalizedPoint.y, 0), 1)
        )

        let centerX = Int(clampedPoint.x * Float(width - 1))
        let centerY = Int(clampedPoint.y * Float(height - 1))

        let brushRadius: Float = 9
        let outerRadius = brushRadius * 1.55
        let edgeCenter = brushRadius * 1.08
        let edgeWidth = brushRadius * 0.38

        let minX = max(0, Int(floor(Float(centerX) - outerRadius)))
        let maxX = min(width - 1, Int(ceil(Float(centerX) + outerRadius)))
        let minY = max(0, Int(floor(Float(centerY) - outerRadius)))
        let maxY = min(height - 1, Int(ceil(Float(centerY) + outerRadius)))

        for y in minY...maxY {
            for x in minX...maxX {
                let dx = Float(x - centerX)
                let dy = Float(y - centerY)
                let distance = sqrt((dx * dx) + (dy * dy))
                let index = (y * width) + x

                if distance <= brushRadius {
                    let normalizedDistance = 1 - (distance / brushRadius)
                    let softness = normalizedDistance * normalizedDistance * (3 - (2 * normalizedDistance))
                    wipeInfluence[index] = max(wipeInfluence[index], softness * 0.88)
                }

                if distance <= outerRadius {
                    let ringDistance = abs(distance - edgeCenter)
                    let ringStrength = max(0, 1 - (ringDistance / edgeWidth))
                    let softenedRing = ringStrength * ringStrength * (3 - (2 * ringStrength))
                    wetEdge[index] = max(wetEdge[index], softenedRing * 0.14)
                }
            }
        }
    }

    private mutating func rebuildImages() {
        wipeMaskImage = makeImage(from: wipeInfluence, rgb: (0, 0, 0))
        wetEdgeImage = makeImage(from: wetEdge, rgb: (255, 255, 255))
    }

    private func makeImage(from field: [Float], rgb: (UInt8, UInt8, UInt8)) -> CGImage? {
        var pixels = [UInt8]()
        pixels.reserveCapacity(field.count * 4)

        for value in field {
            let alpha = UInt8(min(max(value, 0), 1) * 255)
            pixels.append(rgb.0)
            pixels.append(rgb.1)
            pixels.append(rgb.2)
            pixels.append(alpha)
        }

        let data = Data(pixels)
        guard let provider = CGDataProvider(data: data as CFData) else {
            return nil
        }

        return CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
            provider: provider,
            decode: nil,
            shouldInterpolate: true,
            intent: .defaultIntent
        )
    }
}
