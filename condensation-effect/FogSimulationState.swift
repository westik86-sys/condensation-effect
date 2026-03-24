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
    private let width = 120
    private let height = 240

    private(set) var condensation: [Float]
    private(set) var heightField: [Float]
    private(set) var wipeInfluence: [Float]
    private(set) var wetEdge: [Float]
    private(set) var flowField: [Float]
    private(set) var condensationImage: CGImage?
    private(set) var heightImage: CGImage?
    private(set) var wipeMaskImage: CGImage?
    private(set) var wetEdgeImage: CGImage?
    private(set) var flowImage: CGImage?

    private var lastTouchPoint: SIMD2<Float>?

    init() {
        let pixelCount = width * height
        condensation = Array(repeating: 1, count: pixelCount)
        heightField = Array(repeating: 0.55, count: pixelCount)
        wipeInfluence = Array(repeating: 0, count: pixelCount)
        wetEdge = Array(repeating: 0, count: pixelCount)
        flowField = Array(repeating: 0, count: pixelCount)
        rebuildImages()
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

        let wipeDecay = Float(deltaTime / 18.0)
        let wetEdgeDecay = Float(deltaTime / 7.5)
        let diffusionRate = Float(deltaTime * 1.6)
        let wetEdgeDiffusionRate = Float(deltaTime * 0.9)
        let depositionRate = Float(deltaTime / 22.0)
        let ambientWetEdgeFloor: Float = 0

        var nextWipeInfluence = wipeInfluence
        var nextWetEdge = wetEdge
        var hasChanges = false

        for y in 0..<height {
            for x in 0..<width {
                let index = (y * width) + x
                let localAverage = neighboringAverage(of: wipeInfluence, x: x, y: y)
                let localWetEdgeAverage = neighboringAverage(of: wetEdge, x: x, y: y)

                let diffusedWipe = wipeInfluence[index] + ((localAverage - wipeInfluence[index]) * diffusionRate)
                let diffusedWetEdge = wetEdge[index] + ((localWetEdgeAverage - wetEdge[index]) * wetEdgeDiffusionRate)

                let nextWipeValue = max(0, diffusedWipe - wipeDecay - depositionRate)
                let nextWetEdgeValue = max(ambientWetEdgeFloor, diffusedWetEdge - wetEdgeDecay)

                hasChanges = hasChanges || nextWipeValue != wipeInfluence[index] || nextWetEdgeValue != wetEdge[index]
                nextWipeInfluence[index] = min(max(nextWipeValue, 0), 1)
                nextWetEdge[index] = min(max(nextWetEdgeValue, 0), 1)
            }
        }

        let flowResult = applyGravityFlow(
            wetEdge: nextWetEdge,
            wipeInfluence: nextWipeInfluence,
            deltaTime: deltaTime
        )
        nextWetEdge = flowResult.wetEdge
        let nextFlowField = flowResult.flowField
        hasChanges = hasChanges || flowResult.didFlow

        if hasChanges {
            wipeInfluence = nextWipeInfluence
            wetEdge = nextWetEdge
            flowField = nextFlowField
            rebuildImages()
        }
    }

    private mutating func stampSegment(from start: SIMD2<Float>, to end: SIMD2<Float>) {
        let delta = end - start
        let distance = simd_length(delta)
        let stepCount = max(1, Int(ceil(distance * 160)))

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
        rebuildDerivedFields()
        condensationImage = makeImage(from: condensation, rgb: (255, 255, 255))
        heightImage = makeImage(from: heightField, rgb: (255, 255, 255))
        wipeMaskImage = makeImage(from: wipeInfluence, rgb: (0, 0, 0))
        wetEdgeImage = makeImage(from: wetEdge, rgb: (255, 255, 255))
        flowImage = makeImage(from: flowField, rgb: (255, 255, 255))
    }

    private func applyGravityFlow(
        wetEdge: [Float],
        wipeInfluence: [Float],
        deltaTime: TimeInterval
    ) -> (wetEdge: [Float], flowField: [Float], didFlow: Bool) {
        var nextWetEdge = wetEdge
        var nextFlowField = flowField.map { $0 * 0.84 }
        var didFlow = false

        let gravityStrength = Float(deltaTime * 0.30)

        for y in stride(from: height - 2, through: 0, by: -1) {
            for x in 0..<width {
                let index = (y * width) + x
                let moisture = nextWetEdge[index] + (wipeInfluence[index] * 0.08)

                guard moisture > 0.05 else { continue }

                let horizontalDrift = driftDirection(forX: x, y: y)
                let targetX = min(max(x + horizontalDrift, 0), width - 1)
                let targetY = min(y + (moisture > 0.11 ? 2 : 1), height - 1)
                let targetIndex = (targetY * width) + targetX

                let transfer = min(
                    nextWetEdge[index] * 0.16,
                    max(0, (moisture - 0.04) * gravityStrength)
                )

                guard transfer > 0.0001 else { continue }

                nextWetEdge[index] = max(0, nextWetEdge[index] - transfer)
                nextWetEdge[targetIndex] = min(1, nextWetEdge[targetIndex] + (transfer * 0.95))
                nextFlowField[targetIndex] = min(1, max(nextFlowField[targetIndex], transfer * 5.8))
                didFlow = true
            }
        }

        return (nextWetEdge, nextFlowField, didFlow)
    }

    private func driftDirection(forX x: Int, y: Int) -> Int {
        let driftSeed = sin((Float(x) * 0.17) + (Float(y) * 0.03))

        if driftSeed > 0.28 {
            return 1
        }

        if driftSeed < -0.28 {
            return -1
        }

        return 0
    }

    private func neighboringAverage(of field: [Float], x: Int, y: Int) -> Float {
        let minX = max(0, x - 1)
        let maxX = min(width - 1, x + 1)
        let minY = max(0, y - 1)
        let maxY = min(height - 1, y + 1)

        var total: Float = 0
        var count: Float = 0

        for sampleY in minY...maxY {
            for sampleX in minX...maxX {
                total += field[(sampleY * width) + sampleX]
                count += 1
            }
        }

        return count > 0 ? (total / count) : 0
    }

    private mutating func rebuildDerivedFields() {
        for index in condensation.indices {
            let fogAmount = min(max(1 - wipeInfluence[index] + (wetEdge[index] * 0.18), 0), 1)
            let surfaceHeight = min(max((fogAmount * 0.52) + (wetEdge[index] * 1.6) + (flowField[index] * 0.55), 0), 1)

            condensation[index] = fogAmount
            heightField[index] = surfaceHeight
        }
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
