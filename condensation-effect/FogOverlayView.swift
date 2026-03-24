//
//  FogOverlayView.swift
//  condensation-effect
//
//  Created by Pavel Korostelev on 24.03.2026.
//

import SwiftUI

struct FogOverlayView: View {
    let wipeTrail: WipeTrail
    let refogDate: Date
    let touchLocation: CGPoint?
    let onTouchChanged: (CGPoint) -> Void
    let onTouchEnded: () -> Void

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                fogAppearance(in: geometry.size)
                    .overlay {
                        wetEdgeOverlay
                    }
                    .overlay {
                        wipeMask
                            .blendMode(.destinationOut)
                    }
                    .compositingGroup()

                if let touchLocation {
                    Circle()
                        .fill(.white.opacity(0.9))
                        .frame(width: 18, height: 18)
                        .overlay {
                            Circle()
                                .stroke(.white.opacity(0.4), lineWidth: 8)
                        }
                        .shadow(color: .white.opacity(0.35), radius: 14)
                        .position(touchLocation)
                }

                Rectangle()
                    .fill(.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0, coordinateSpace: .local)
                            .onChanged { value in
                                let clampedLocation = CGPoint(
                                    x: min(max(value.location.x, 0), geometry.size.width),
                                    y: min(max(value.location.y, 0), geometry.size.height)
                                )
                                onTouchChanged(clampedLocation)
                            }
                            .onEnded { _ in
                                onTouchEnded()
                            }
                    )
            }
        }
        .ignoresSafeArea()
    }

    private var wetEdgeOverlay: some View {
        Canvas { context, _ in
            guard let firstStamp = wipeTrail.stamps.first else { return }

            context.addFilter(.blur(radius: 10))

            if wipeTrail.stamps.count > 1 {
                for (startStamp, endStamp) in zip(wipeTrail.stamps, wipeTrail.stamps.dropFirst()) {
                    let segmentStrength = min(
                        wipeTrail.strength(for: startStamp, at: refogDate),
                        wipeTrail.strength(for: endStamp, at: refogDate)
                    )
                    guard segmentStrength > 0 else { continue }

                    var path = Path()
                    path.move(to: startStamp.location)
                    path.addLine(to: endStamp.location)

                    context.stroke(
                        path,
                        with: .color(.white.opacity(0.14 * Double(segmentStrength))),
                        style: StrokeStyle(
                            lineWidth: (firstStamp.radius * 2) + 10,
                            lineCap: .round,
                            lineJoin: .round
                        )
                    )
                }
            }

            for stamp in wipeTrail.stamps {
                let strength = wipeTrail.strength(for: stamp, at: refogDate)
                guard strength > 0 else { continue }

                let rect = CGRect(
                    x: stamp.location.x - stamp.radius - 5,
                    y: stamp.location.y - stamp.radius - 5,
                    width: (stamp.radius * 2) + 10,
                    height: (stamp.radius * 2) + 10
                )
                context.fill(
                    Path(ellipseIn: rect),
                    with: .color(.white.opacity(0.12 * Double(strength)))
                )
            }
        }
    }

    private var wipeMask: some View {
        Canvas { context, _ in
            guard let firstStamp = wipeTrail.stamps.first else { return }

            context.addFilter(.blur(radius: 14))

            if wipeTrail.stamps.count > 1 {
                for (startStamp, endStamp) in zip(wipeTrail.stamps, wipeTrail.stamps.dropFirst()) {
                    let segmentStrength = min(
                        wipeTrail.strength(for: startStamp, at: refogDate),
                        wipeTrail.strength(for: endStamp, at: refogDate)
                    )
                    guard segmentStrength > 0 else { continue }

                    var path = Path()
                    path.move(to: startStamp.location)
                    path.addLine(to: endStamp.location)

                    context.stroke(
                        path,
                        with: .color(.black.opacity(Double(segmentStrength))),
                        style: StrokeStyle(
                            lineWidth: firstStamp.radius * 2,
                            lineCap: .round,
                            lineJoin: .round
                        )
                    )
                }
            }

            for stamp in wipeTrail.stamps {
                let strength = wipeTrail.strength(for: stamp, at: refogDate)
                guard strength > 0 else { continue }

                let rect = CGRect(
                    x: stamp.location.x - stamp.radius,
                    y: stamp.location.y - stamp.radius,
                    width: stamp.radius * 2,
                    height: stamp.radius * 2
                )
                context.fill(Path(ellipseIn: rect), with: .color(.black.opacity(Double(strength))))
            }
        }
    }

    private func fogAppearance(in size: CGSize) -> some View {
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
        .blur(radius: 8)
        .colorEffect(
            ShaderLibrary.organicFog(.float2(size))
        )
    }
}

struct FogOverlayView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            FogOverlayView(
                wipeTrail: {
                    var trail = WipeTrail()
                    trail.appendStamp(at: CGPoint(x: 120, y: 220))
                    trail.appendStamp(at: CGPoint(x: 160, y: 260))
                    trail.appendStamp(at: CGPoint(x: 210, y: 300))
                    return trail
                }(),
                refogDate: Date(),
                touchLocation: CGPoint(x: 160, y: 280),
                onTouchChanged: { _ in },
                onTouchEnded: { }
            )
        }
    }
}
