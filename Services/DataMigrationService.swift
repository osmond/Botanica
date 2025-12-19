import Foundation
import SwiftData

/// One-off data migrations and cleanups
@MainActor
enum DataMigrationService {
    /// Pulls pot diameter from notes (e.g. "Pot diameter: 15.2 cm") and stores it in `potSize` (inches).
    /// Cleans the pot height/diameter fragments from notes. Runs once per install.
    static func migratePotSizeFromNotesIfNeeded(context: ModelContext) async {
        let flagKey = "migrated_pot_size_from_notes_v2"
        if UserDefaults.standard.bool(forKey: flagKey) { return }

        let descriptor = FetchDescriptor<Plant>()
        guard let plants = try? context.fetch(descriptor) else { return }

        var updated = 0
        for plant in plants {
            guard !plant.notes.isEmpty else { continue }
            let original = plant.notes
            let (maybeDia, maybeHeight, cleanedNotes) = extractPotDimensionsAndCleanNotes(from: original)
            if let inches = maybeDia {
                // Only set if the detected size is sensible and
                // either potSize appears default or clearly different
                if inches > 0 && (plant.potSize <= 0 || abs(plant.potSize - inches) >= 1) {
                    plant.potSize = inches
                }
            }
            if let h = maybeHeight, h > 0 { plant.potHeight = h }
            if cleanedNotes != original {
                plant.notes = cleanedNotes
            }
            if plant.notes != original || maybeDia != nil || maybeHeight != nil { updated += 1 }
        }

        do { try context.save() } catch { }
        UserDefaults.standard.set(true, forKey: flagKey)
        print("🔁 Pot size migration complete. Updated: \(updated)")
    }

    /// Sets a sensible default repot frequency and last repot date for legacy plants.
    /// Runs once to avoid migration failures when the new attributes are nil.
    static func migrateRepotDefaultsIfNeeded(context: ModelContext) async {
        let flagKey = "migrated_repot_defaults_v1"
        if UserDefaults.standard.bool(forKey: flagKey) { return }

        let descriptor = FetchDescriptor<Plant>()
        guard let plants = try? context.fetch(descriptor) else { return }

        var updated = 0
        for plant in plants {
            var touched = false
            if plant.repotFrequencyMonths == nil {
                plant.repotFrequencyMonths = 12
                touched = true
            }
            if plant.lastRepotted == nil {
                // Anchor to dateAdded so nothing shows overdue immediately
                plant.lastRepotted = plant.dateAdded
                touched = true
            }
            if touched { updated += 1 }
        }

        do { try context.save() } catch { }
        UserDefaults.standard.set(true, forKey: flagKey)
        print("🔁 Repot defaults migration complete. Updated: \(updated)")
    }

    /// Extracts pot diameter and height from notes; returns (diameterInches, heightInches, cleanedNotes)
    private static func extractPotDimensionsAndCleanNotes(from notes: String) -> (Int?, Int?, String) {
        // Example fragments to catch:
        // "Pot diameter: 15.2 cm" | "Pot height: 10.4 cm" | with separators " | "
        var diameterInches: Int?
        var heightInches: Int?
        let patterns = [
            (label: "pot diameter:", assign: { (val: Int) in diameterInches = val }),
            (label: "pot height:", assign: { (val: Int) in heightInches = val }),
        ]

        let lower = notes.lowercased()
        for entry in patterns {
            if let r = lower.range(of: entry.label) {
                let suffix = String(lower[r.upperBound...])
                if let cm = matchFirstCMNumber(in: suffix) {
                    entry.assign(Int((cm / 2.54).rounded()))
                }
            }
        }

        // Clean out pot diameter/height fragments when separated by " | "
        let parts = notes.split(separator: "|", omittingEmptySubsequences: false).map { $0.trimmingCharacters(in: .whitespaces) }
        let filtered = parts.filter { part in
            let l = part.lowercased()
            return !(l.hasPrefix("pot diameter:") || l.hasPrefix("pot height:"))
        }
        let cleaned = filtered.joined(separator: filtered.isEmpty ? "" : " | ")
        return (diameterInches, heightInches, cleaned)
    }
    
    private static func matchFirstCMNumber(in text: String) -> Double? {
        // Look for a number followed by optional space and 'cm'
        let pattern = #"([0-9]+(?:\.[0-9]+)?)\s*cm"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return nil }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        if let m = regex.firstMatch(in: text, options: [], range: range) {
            if let r = Range(m.range(at: 1), in: text) {
                return Double(text[r])
            }
        }
        return nil
    }
}
