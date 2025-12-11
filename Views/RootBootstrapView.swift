import SwiftUI
import SwiftData

/// Boots the app by seeding initial data before showing content/onboarding.
struct RootBootstrapView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var isSeeded = false
    @State private var loadState: LoadState = .idle
    @State private var lastError: String?

    var body: some View {
        LoadStateView(
            state: loadState,
            retry: { Task { await seedIfNeeded() } },
            loading: { launchLoading }
        ) {
            if hasCompletedOnboarding {
                ContentView()
            } else {
                OnboardingView {
                    hasCompletedOnboarding = true
                }
            }
        }
        .task { await seedIfNeeded() }
    }
    
    private var launchLoading: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Preparing your plants…")
                .foregroundColor(.secondary)
        }
    }
    
    private func seedIfNeeded() async {
        await MainActor.run {
            loadState = .loading
            lastError = nil
        }
        
        await DevBlossomSeeder.seedIfNeeded(context: modelContext)
        await DataMigrationService.migratePotSizeFromNotesIfNeeded(context: modelContext)
        await DataMigrationService.migrateRepotDefaultsIfNeeded(context: modelContext)
        await MainActor.run {
            isSeeded = true
            loadState = .loaded
        }
    }
}
