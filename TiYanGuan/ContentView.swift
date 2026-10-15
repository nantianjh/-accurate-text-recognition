import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            RecognizeView()
                .tabItem { Label("识别", systemImage: "doc.text.viewfinder") }
            HistoryView()
                .tabItem { Label("历史", systemImage: "clock.arrow.circlepath") }
        }
    }
}