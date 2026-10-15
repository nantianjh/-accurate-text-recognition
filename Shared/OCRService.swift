import UIKit
import Vision

enum OCRError: LocalizedError {
    case invalidImage

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "无法读取图片数据"
        }
    }
}

enum OCRService {
    static func recognizeText(in image: UIImage) async throws -> String {
        guard let cgImage = normalizedCGImage(image) else {
            throw OCRError.invalidImage
        }
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["zh-Hans", "en-US"]
        request.usesLanguageCorrection = true
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        return try await Task.detached(priority: .userInitiated) {
            try handler.perform([request])
            let observations = (request.results as? [VNRecognizedTextObservation]) ?? []
            return observations
                .compactMap { $0.topCandidates(1).first?.string }
                .joined(separator: "\n")
        }.value
    }

    private static func normalizedCGImage(_ image: UIImage) -> CGImage? {
        guard image.imageOrientation == .up else {
            let format = UIGraphicsImageRendererFormat.default()
            format.scale = 1
            let renderer = UIGraphicsImageRenderer(size: image.size, format: format)
            let normalized = renderer.image { _ in
                image.draw(in: CGRect(origin: .zero, size: image.size))
            }
            return normalized.cgImage
        }
        return image.cgImage
    }
}