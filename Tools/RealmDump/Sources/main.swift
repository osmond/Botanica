import Foundation
import RealmSwift

@main
struct App {
    static func main() async {
        let args = CommandLine.arguments
        let path = args.count > 1 ? args[1] : "./default.realm"
        let url = URL(fileURLWithPath: path)
        guard FileManager.default.fileExists(atPath: url.path) else {
            fputs("Realm file not found at \(url.path)\n", stderr)
            exit(2)
        }

        var config = Realm.Configuration()
        config.fileURL = url
        config.readOnly = true

        do {
            let realm = try Realm(configuration: config)
            let schema = realm.schema
            print("Opened Realm: \(url.path)")
            print("Schema versions: user=\(try schemaVersionAtURL(url))")
            print("Object types (\(schema.objectSchema.count)):")
            for obj in schema.objectSchema {
                print("- \(obj.className) (props: \(obj.properties.map{ $0.name }.joined(separator: ", "))) ")
            }

            print("\nSummary counts:")
            for obj in schema.objectSchema {
                let results = realm.dynamicObjects(obj.className)
                print("- \(obj.className): \(results.count)")
            }

            print("\nSample records (up to 5 per type):")
            for obj in schema.objectSchema {
                let results = realm.dynamicObjects(obj.className)
                let sample = results.prefix(5)
                guard !sample.isEmpty else { continue }
                print("\nType: \(obj.className)")
                for (idx, item) in sample.enumerated() {
                    var dict: [String: Any] = [:]
                    for prop in obj.properties {
                        let key = prop.name
                        let value = item[key]
                        // Render RealmOptional and ObjectId etc. safely
                        if let val = value as? CustomStringConvertible {
                            dict[key] = val.description
                        } else if value == nil {
                            dict[key] = NSNull()
                        } else {
                            dict[key] = String(describing: value)
                        }
                    }
                    // Pretty print one line JSON-ish
                    if let data = try? JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted, .sortedKeys]),
                       let text = String(data: data, encoding: .utf8) {
                        print("  [\(idx)] \n\(text)")
                    } else {
                        print("  [\(idx)] \(dict)")
                    }
                }
            }

        } catch {
            fputs("Failed to open Realm: \(error)\n", stderr)
            exit(1)
        }
    }
}

