import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var store: RecordStore
    @State private var copiedID: UUID?

    var body: some View {
        NavigationStack {
            Group {
                if store.records.isEmpty {
                    ContentUnavailableView(
                        "暂无记录",
                        systemImage: "tray",
                        description: Text("分享或选择图片后，提取结果会显示在这里")
                    )
                } else {
                    list
                }
            }
            .navigationTitle("历史")
            .onAppear { store.refresh() }
        }
    }

    private var list: some View {
        List {
            ForEach(store.records) { record in
                row(for: record)
            }
            .onDelete { offsets in
                for index in offsets where index < store.records.count {
                    store.delete(store.records[index])
                }
            }
        }
    }

    private func row(for record: ExtractRecord) -> some View {
        Button {
            guard let keyword = record.keyword else { return }
            UIPasteboard.general.string = keyword
            copiedID = record.id
            Task {
                try? await Task.sleep(nanoseconds: 1_200_000_000)
                if copiedID == record.id {
                    copiedID = nil
                }
            }
        } label: {
            HStack(spacing: 12) {
                thumbnail(for: record)
                VStack(alignment: .leading, spacing: 4) {
                    Text(record.keyword ?? "未匹配到关键词")
                        .font(.headline)
                        .lineLimit(2)
                        .foregroundStyle(record.keyword == nil ? AnyShapeStyle(.secondary) : AnyShapeStyle(.primary))
                    Text(record.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if copiedID == record.id {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else if record.keyword != nil {
                    Image(systemName: "doc.on.doc")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .tint(.primary)
    }

    @ViewBuilder
    private func thumbnail(for record: ExtractRecord) -> some View {
        if let data = record.thumbnailData, let thumb = UIImage(data: data) {
            Image(uiImage: thumb)
                .resizable()
                .scaledToFill()
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        } else {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.tertiarySystemBackground))
                .frame(width: 44, height: 44)
                .overlay {
                    Image(systemName: "photo")
                        .foregroundStyle(.secondary)
                }
        }
    }
}