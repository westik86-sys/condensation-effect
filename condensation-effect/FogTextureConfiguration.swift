//
//  FogTextureConfiguration.swift
//  condensation-effect
//
//  Created by Pavel Korostelev on 24.03.2026.
//

import SwiftUI
import UIKit

struct FogTextureConfiguration {
    let densityTextureName: String?
    let dropletDetailTextureName: String?
    let distortionTextureName: String?

    static let `default` = FogTextureConfiguration(
        densityTextureName: "FogDensityTexture",
        dropletDetailTextureName: "FogDropletDetailTexture",
        distortionTextureName: "FogDistortionTexture"
    )

    func image(named name: String?) -> Image? {
        guard let name, let image = UIImage(named: name) else {
            return nil
        }

        return Image(uiImage: image)
    }
}
