import SwiftUI
import SwiftData

/// Boots the app by seeding initial data before showing content/onboarding.
struct RootBootstrapView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var isSeeded = false

    var body: some View {
        Group {
            if isSeeded {
                if hasCompletedOnboarding {
                    ContentView()
                } else {
                    OnboardingView {
                        hasCompletedOnboarding = true
                    }
                }
            } else {
                // Lightweight launch screen while seeding
                VStack(spacing: 16) {
                    ProgressView()
                    Text("Preparing your plants…")
                        .foregroundColor(.secondary)
                }
            }
        }
        .task {
            await DevBlossomSeeder.seedIfNeeded(context: modelContext)
            await DataMigrationService.migratePotSizeFromNotesIfNeeded(context: modelContext)
            await MainActor.run { isSeeded = true }
        }
    }
}
