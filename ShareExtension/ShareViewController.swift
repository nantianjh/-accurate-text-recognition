import UIKit
import UniformTypeIdentifiers

final class ShareViewController: UIViewController {
    private let statusLabel = UILabel()

    override var preferredContentSize: CGSize {
        get { CGSize(width: 420, height: 200) }
        set { super.preferredContentSize = newValue }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        processInput()
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground
        statusLabel.font = .systemFont(ofSize: 17, weight: .medium)
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.text = "识别中…"
        view.addSubview(statusLabel)
        NSLayoutConstraint.activate([
            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statusLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            statusLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24),
            statusLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24)
        ])
    }

    private func processInput() {
        guard let items = extensionContext?.inputItems as? [NSExtensionItem] else {
            finish(withMessage: "无法获取分享内容")
            return
        }
        let providers = items.flatMap { $0.attachments ?? [] }
        guard let imageProvider = providers.first(where: {
            $0.hasItemConformingToTypeIdentifier(UTType.image.identifier)
        }) else {
            finish(withMessage: "未找到图片")
            return
        }
        imageProvider.loadDataRepresentation(
            forTypeIdentifier: UTType.image.identifier
        ) { [weak self] data, _ in
            Task { @MainActor in
                guard let self else { return }
                guard let data, let image = UIImage(data: data) else {
                    self.finish(withMessage: "图片读取失败")
                    return
                }
                await self.handle(image: image)
            }
        }
    }

    @MainActor
    private func handle(image: UIImage) async {
        do {
            let text = try await OCRService.recognizeText(in: image)
            let keyword = TextExtractor.extractKeyword(from: text)
            AppGroupStore.save(ExtractRecord(
                keyword: keyword,
                fullText: text,
                thumbnailData: ExtractRecord.makeThumbnail(from: image)
            ))
            if let keyword {
                UIPasteboard.general.string = keyword
                finish(withMessage: "已提取：\(keyword)\n已复制到剪贴板")
            } else {
                finish(withMessage: "未匹配到「输入:…(下拉)」内容")
            }
        } catch {
            finish(withMessage: "识别失败：\(error.localizedDescription)")
        }
    }

    @MainActor
    private func finish(withMessage message: String) {
        statusLabel.text = message
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) { [weak self] in
            self?.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
        }
    }
}