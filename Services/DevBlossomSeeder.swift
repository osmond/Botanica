import Foundation
import SwiftData

/// Development-time seeder to import Blossom JSON into SwiftData once.
@MainActor
enum DevBlossomSeeder {
    private static let flagKey = "dev_seed_blossom_done"
    private static let customFlagKey = "dev_seed_custom_plants_done"

    static func seedIfNeeded(context: ModelContext) async {
        let count = (try? context.fetch(FetchDescriptor<Plant>()).count) ?? 0
        // Only seed when the store is empty to avoid duplicating user data.
        if count > 0 {
            return
        }

        if let url = Bundle.main.url(forResource: "plants_import", withExtension: "json"),
           let data = try? Data(contentsOf: url) {
            do {
                let result = try DataImportService.shared.importAutoDetectingData(data, into: context)
                UserDefaults.standard.set(true, forKey: customFlagKey)
                print("✅ Custom seed imported: plants=\(result.plantsCreated), events=\(result.careEventsCreated)")
                return
            } catch {
                print("⚠️ Custom seed import failed: \(error)")
                return
            }
        }

#if DEBUG
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
#endif
    }
}
