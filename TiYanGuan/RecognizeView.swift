import PhotosUI
import SwiftUI

struct RecognizeView: View {
    @EnvironmentObject private var store: RecordStore

    @State private var selectedItem: PhotosPickerItem?
    @State private var image: UIImage?
    @State private var ocrText: String?
    @State private var keyword: String?
    @State private var isProcessing = false
    @State private var message: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    photoPicker
                    if isProcessing {
                        ProgressView("识别中…")
                            .padding()
                    }
                    if let keyword {
                        resultCard(keyword: keyword)
                    }
                    if let message {
                        Text(message)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    if let ocrText {
                        fullTextCard(text: ocrText)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("识别")
            .task(id: selectedItem) {
                await process()
            }
        }
    }

    private var photoPicker: some View {
        PhotosPicker(selection: $selectedItem, matching: .images) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemBackground))
                    .frame(height: 220)
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(8)
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)
                        Text("选择图片识别")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(.horizontal)
        .disabled(isProcessing)
    }

    private func resultCard(keyword: String) -> some View {
        VStack(spacing: 12) {
            Text("提取结果")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(keyword)
                .font(.title2.bold())
                .multilineTextAlignment(.center)
                .textSelection(.enabled)
                .padding(12)
                .frame(maxWidth: .infinity)
                .background(Color(.tertiarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            Button {
                UIPasteboard.general.string = keyword
                message = "已复制到剪贴板"
            } label: {
                Label("复制", systemImage: "doc.on.doc")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.horizontal)
    }

    private func fullTextCard(text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("OCR 全文")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(text)
                .font(.callout)
                .textSelection(.enabled)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }

    private func process() async {
        guard let item = selectedItem else { return }
        isProcessing = true
        keyword = nil
        ocrText = nil
        message = nil
        defer { isProcessing = false }
        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let loaded = UIImage(data: data) else {
                message = "无法读取图片"
                return
            }
            image = loaded
            let text = try await OCRService.recognizeText(in: loaded)
            ocrText = text
            let extracted = TextExtractor.extractKeyword(from: text)
            if let extracted {
                keyword = extracted
                UIPasteboard.general.string = extracted
                store.add(ExtractRecord(
                    keyword: extracted,
                    fullText: text,
                    thumbnailData: ExtractRecord.makeThumbnail(from: loaded)
                ))
                message = "已提取并复制到剪贴板"
            } else {
                message = "未匹配到「输入:…(下拉)」内容"
            }
        } catch {
            message = "识别失败：\(error.localizedDescription)"
        }
    }
}