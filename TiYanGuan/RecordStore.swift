import Foundation
import SwiftUI

@MainActor
final class RecordStore: ObservableObject {
    @Published private(set) var records: [ExtractRecord] = []

    init() {
        refresh()
    }

    func refresh() {
        records = AppGroupStore.loadRecords()
    }

    func add(_ record: ExtractRecord) {
        AppGroupStore.save(record)
        refresh()
    }

    func delete(_ record: ExtractRecord) {
        AppGroupStore.deleteRecord(id: record.id)
        refresh()
    }
}