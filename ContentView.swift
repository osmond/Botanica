import SwiftUI
import SwiftData

/// Main content view - now uses the complete tab-based navigation
struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    var body: some View {
        MainTabView()
            .task {
                await DevBlossomSeeder.seedIfNeeded(context: modelContext)
            }
    }
}

#Preview {
    ContentView()
        .modelContainer(MockDataGenerator.previewContainer())
}
