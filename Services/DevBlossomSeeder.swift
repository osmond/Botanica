import Foundation
import SwiftData

/// Development-time seeder to import Blossom JSON into SwiftData once.
enum DevBlossomSeeder {
    private static let flagKey = "dev_seed_blossom_done"

    static func seedIfNeeded(context: ModelContext) async {
        let count = (try? context.fetch(FetchDescriptor<Plant>()).count) ?? 0
        // Always seed if there are zero plants (first run/new install), regardless of flag.
        if count > 0 && UserDefaults.standard.bool(forKey: flagKey) {
            return
        }

        guard let data = DevBlossomSeedData.json.data(using: .utf8) else {
            return
        }

        do {
            let result = try DataImportService.shared.importAutoDetectingData(data, into: context)
            UserDefaults.standard.set(true, forKey: flagKey)
            print("✅ Dev seed imported: plants=\(result.plantsCreated), events=\(result.careEventsCreated)")
        } catch {
            print("⚠️ Dev seed import failed: \(error)")
        }
    }
}
