import Foundation
import UIKit

struct ExtractRecord: Codable, Identifiable, Equatable {
    let id: UUID
    let keyword: String?
    let fullText: String
    let date: Date
    let thumbnailData: Data?

    init(keyword: String?, fullText: String, thumbnailData: Data? = nil) {
        self.id = UUID()
        self.keyword = keyword
        self.fullText = fullText
        self.date = Date()
        self.thumbnailData = thumbnailData
    }

    static func makeThumbnail(from image: UIImage, maxDimension: CGFloat = 160) -> Data? {
        let size = image.size
        let longest = max(size.width, size.height)
        guard longest > 0 else { return nil }
        if longest <= maxDimension {
            return image.jpegData(compressionQuality: 0.6)
        }
        let ratio = maxDimension / longest
        let targetSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        let thumb = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
        return thumb.jpegData(compressionQuality: 0.6)
    }
}