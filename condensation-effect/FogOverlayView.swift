//
//  FogOverlayView.swift
//  condensation-effect
//
//  Created by Pavel Korostelev on 24.03.2026.
//

import SwiftUI

struct FogOverlayView: View {
    private let textureConfiguration = FogTextureConfiguration.default

    let simulationState: FogSimulationState
    let touchLocation: CGPoint?
    let onTouchChanged: (CGPoint, CGSize) -> Void
    let onTouchEnded: () -> Void

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                fogAppearance(in: geometry.size)
                    .overlay {
                        wetEdgeOverlay
                    }
                    .overlay {
                        flowOverlay
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
                                onTouchChanged(clampedLocation, geometry.size)
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
        Group {
            if let wetEdgeImage = simulationState.wetEdgeImage {
                Image(decorative: wetEdgeImage, scale: 1)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFill()
                    .blur(radius: 8)
                    .blendMode(.screen)
            }
        }
    }

    private var flowOverlay: some View {
        Group {
            if let flowImage = simulationState.flowImage {
                Image(decorative: flowImage, scale: 1)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFill()
                    .blur(radius: 2)
                    .opacity(0.12)
                    .blendMode(.softLight)
            }
        }
    }

    private var wipeMask: some View {
        Group {
            if let wipeMaskImage = simulationState.wipeMaskImage {
                Image(decorative: wipeMaskImage, scale: 1)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFill()
                    .blur(radius: 12)
            }
        }
    }

    private func fogAppearance(in size: CGSize) -> some View {
        ZStack {
            Rectangle()
                .fill(.regularMaterial)

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
            simulationTextureOverlay
        }
        .overlay {
            Rectangle()
                .fill(.white.opacity(0.05))
        }
        .overlay {
            fogTextureOverlay
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
        .distortionEffect(
            ShaderLibrary.moistureRefraction(.float2(size)),
            maxSampleOffset: CGSize(width: 2, height: 2)
        )
        .colorEffect(
            ShaderLibrary.organicFog(.float2(size))
        )
    }

    @ViewBuilder
    private var simulationTextureOverlay: some View {
        if let condensationImage = simulationState.condensationImage {
            Image(decorative: condensationImage, scale: 1)
                .resizable()
                .interpolation(.none)
                .scaledToFill()
                .opacity(0.10)
                .blendMode(.multiply)
        }

        if let heightImage = simulationState.heightImage {
            Image(decorative: heightImage, scale: 1)
                .resizable()
                .interpolation(.none)
                .scaledToFill()
                .opacity(0.04)
                .blendMode(.softLight)
        }
    }

    @ViewBuilder
    private var fogTextureOverlay: some View {
        if let densityTexture = textureConfiguration.image(named: textureConfiguration.densityTextureName) {
            densityTexture
                .resizable()
                .scaledToFill()
                .opacity(0.08)
                .blendMode(.multiply)
        }

        if let dropletTexture = textureConfiguration.image(named: textureConfiguration.dropletDetailTextureName) {
            dropletTexture
                .resizable(resizingMode: .tile)
                .opacity(0.04)
                .blendMode(.overlay)
        }

        if let distortionTexture = textureConfiguration.image(named: textureConfiguration.distortionTextureName) {
            distortionTexture
                .resizable()
                .scaledToFill()
                .opacity(0.03)
                .blendMode(.softLight)
        }
    }
}

struct FogOverlayView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            FogOverlayView(
                simulationState: {
                    var state = FogSimulationState()
                    let previewSize = CGSize(width: 320, height: 640)
                    state.applyTouch(at: CGPoint(x: 120, y: 220), in: previewSize, isContinuation: false)
                    state.applyTouch(at: CGPoint(x: 160, y: 260), in: previewSize, isContinuation: true)
                    state.applyTouch(at: CGPoint(x: 210, y: 300), in: previewSize, isContinuation: true)
                    return state
                }(),
                touchLocation: CGPoint(x: 160, y: 280),
                onTouchChanged: { _, _ in },
                onTouchEnded: { }
            )
        }
    }
}
