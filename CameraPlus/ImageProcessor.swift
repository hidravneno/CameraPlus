
import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins

final class ImageProcessor {
    private let context = CIContext(options: nil)

    func apply(filter: FilterOption, intensity: Double, to image: UIImage) -> UIImage {
        guard filter != .original else { return image }
        guard let ciInput = CIImage(image: image) else { return image }

        let output: CIImage?
        switch filter {
        case .noir:
            let noir = CIFilter.photoEffectNoir()
            noir.inputImage = ciInput
            output = noir.outputImage

        case .sepia:
            let sepia = CIFilter.sepiaTone()
            sepia.inputImage = ciInput
            sepia.intensity = Float(intensity) // 0…1
            output = sepia.outputImage

        case .bloom:
            let bloom = CIFilter.bloom()
            bloom.inputImage = ciInput
            bloom.intensity = Float(intensity) // 0…1
            // Map intensity → radius (subtle 0…20)
            bloom.radius = Float(intensity * 20)
            output = bloom.outputImage

        case .vignette:
            let vignette = CIFilter.vignette()
            vignette.inputImage = ciInput
            vignette.intensity = Float(intensity * 2) // stronger range
            vignette.radius = Float(max(1.0, intensity * 4))
            output = vignette.outputImage

        case .colorControls:
            let cc = CIFilter.colorControls()
            cc.inputImage = ciInput
            // Map single slider to multiple params
            // intensity 0…1 → saturation 0.5…1.5, contrast 0.9…1.3, brightness -0.1…0.1
            cc.saturation = Float(0.5 + intensity)
            cc.contrast = Float(0.9 + intensity * 0.4)
            cc.brightness = Float((intensity - 0.5) * 0.2)
            output = cc.outputImage

        case .original:
            output = ciInput
        }

        guard let finalCI = output,
              let cg = context.createCGImage(finalCI, from: finalCI.extent) else {
            return image
        }
        // Preserve original scale & orientation
        return UIImage(cgImage: cg, scale: image.scale, orientation: image.imageOrientation)
    }
}

