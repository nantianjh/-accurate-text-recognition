import Foundation

enum AppGroupStore {
    static let appGroupId = "group.com.debugpapple.tiyanguan"
    private static let recordsFileName = "records.json"
    private static let maxRecords = 100

    private static var recordsURL: URL? {
        guard let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupId) else {
            return nil
        }
        return container.appendingPathComponent(recordsFileName)
    }

    static func loadRecords() -> [ExtractRecord] {
        guard let url = recordsURL,
              let data = try? Data(contentsOf: url) else {
            return []
        }
        return (try? JSONDecoder().decode([ExtractRecord].self, from: data)) ?? []
    }

    static func save(_ record: ExtractRecord) {
        var records = loadRecords()
        records.insert(record, at: 0)
        if records.count > maxRecords {
            records = Array(records.prefix(maxRecords))
        }
        persist(records)
    }

    static func deleteRecord(id: UUID) {
        var records = loadRecords()
        records.removeAll { $0.id == id }
        persist(records)
    }

    private static func persist(_ records: [ExtractRecord]) {
        guard let url = recordsURL,
              let data = try? JSONEncoder().encode(records) else {
            return
        }
        try? data.write(to: url, options: .atomic)
    }
}