import SwiftUI

@main
struct TiYanGuanApp: App {
    @StateObject private var store = RecordStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}