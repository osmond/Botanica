# CLAUDE.md — Botanica

## Project Overview

Botanica is a SwiftUI iOS app for thoughtful plant care management. It tracks plants, logs care events, manages reminders, and offers optional AI-powered identification and coaching via the OpenAI API. The app is local-first — it works fully offline without an API key.

**Stack:** Swift 5.9, SwiftUI, SwiftData, iOS 17+, Xcode 15+
**Third-party dependencies:** None (pure Apple frameworks)
**External API:** OpenAI (optional, for plant identification and coaching)

## Build & Run

```bash
# Build
xcodebuild -scheme Botanica -destination 'platform=iOS Simulator,name=iPhone 15' build

# Run tests
xcodebuild -scheme Botanica -destination 'platform=iOS Simulator,name=iPhone 15' test
```

The Xcode project is `Botanica.xcodeproj`. There is no SPM Package.swift or CocoaPods — open the `.xcodeproj` directly.

## Project Structure

```
Botanica/
├── BotanicaApp.swift          # @main entry point, SwiftData container setup
├── ContentView.swift          # Root content view
├── SecureStorage.swift        # Keychain wrapper (shared at top level)
├── Info.plist                 # Privacy permissions (camera, photos, location)
├── Assets.xcassets/           # Colors, app icons
├── Core/
│   ├── Theme/BotanicaTheme.swift   # Design system (colors, typography, spacing)
│   ├── Imaging/ImageCache.swift    # Image caching
│   ├── Utilities/                  # ErrorMessageFormatter, HapticManager, SecureStorage
│   └── AppServices.swift           # Service container with Environment injection
├── Models/
│   ├── DataModels.swift            # SwiftData @Model classes (Plant, CareEvent, Reminder, Photo, CarePlan)
│   ├── ModelExtensions.swift       # Computed properties and care calculations
│   ├── PlantListTypes.swift        # Sort/group/filter enums for plant lists
│   └── MockDataGenerator.swift     # Preview data
├── ViewModels/
│   ├── MainTabCoordinator.swift    # Tab navigation state
│   ├── PlantFormViewModel.swift    # Add/edit plant form logic
│   ├── PlantDetailViewModel.swift  # Plant detail state
│   └── PlantHealthVisionViewModel.swift
├── Views/
│   ├── MainTabView.swift           # Tab bar (Today, My Plants, AI, Settings)
│   ├── MyPlantsView.swift          # Plant collection with search/filter/sort
│   ├── PlantDetailView.swift       # Individual plant detail
│   ├── AddPlantView.swift          # Multi-section plant form
│   ├── EditPlantView.swift         # Edit existing plant
│   ├── AI/                         # AIHubView, coach, identification, health vision
│   └── Settings/                   # Settings screens, import/export, notifications
├── Services/
│   ├── OpenAIClient.swift          # Lightweight OpenAI API wrapper
│   ├── OpenAIConfig.swift          # API key storage (Keychain), model selection
│   ├── AIService.swift             # Plant identification via Vision API
│   ├── AIPlantCoach.swift          # AI coaching conversations
│   ├── PlantHealthVisionAnalyzer.swift  # Photo-based health analysis
│   ├── CareCalculator.swift        # Weather-adjusted care recommendations
│   ├── NotificationManager.swift   # Local notification scheduling
│   ├── NotificationService.swift   # Notification service layer
│   ├── WeatherService.swift        # Weather-based care adjustments
│   ├── DataImportService.swift     # JSON import with auto-detection
│   ├── DataExportService.swift     # Versioned JSON export
│   ├── DataMigrationService.swift  # Schema migrations
│   ├── AutoBackupService.swift     # Automatic backups
│   ├── DevBlossomSeeder.swift      # First-launch sample data seeding (DEBUG)
│   └── DevBlossomSeedData.swift    # Embedded sample plant data
├── Utils/
│   ├── LoadState.swift             # LoadState enum + ViewModel protocol
│   ├── AnimationPerformance.swift  # Animation optimization
│   └── PerformanceOptimization.swift
├── BotanicaTests/
│   ├── PlantFormViewModelTests.swift
│   ├── DataModelTests.swift
│   ├── CareCalculatorTests.swift
│   ├── ErrorMessageFormatterTests.swift
│   └── ImageCacheTests.swift
└── Tools/                          # Developer utilities (RealmDump)
```

## Architecture

**Pattern:** MVVM (Model-View-ViewModel) with SwiftUI and SwiftData.

### Data Layer
- **SwiftData** `@Model` classes in `Models/DataModels.swift` — `Plant`, `CareEvent`, `Reminder`, `Photo`, `CarePlan`
- Relationships use `@Relationship(deleteRule: .cascade)` — deleting a plant cascades to its photos, events, reminders, and care plan
- Array properties use `@Attribute(.transformable(by:))` with registered `ModelTransformers`
- `ModelTransformers.register()` is called in `BotanicaApp.init()` before any data access

### Service Layer
- `AppServices` is a singleton service container injected via SwiftUI `@Environment(\.appServices)`
- Contains `OpenAIClient` and `NotificationService`
- AI services (AIService, AIPlantCoach, PlantHealthVisionAnalyzer) are instantiated where needed, not centralized

### View Layer
- Large views are decomposed into section-specific sub-views (e.g., `AddPlantBasicInfoSection`, `AddPlantCareRequirementsSection`)
- Navigation: 4-tab `MainTabView` → `NavigationStack` within each tab → sheet modals for add/edit flows
- Tabs: Today (sun.max), My Plants (leaf.fill), AI (sparkles), Settings (gearshape.fill)

### State Management
- `@StateObject` / `@ObservedObject` for ViewModels
- `@Query` for SwiftData database reads
- `@AppStorage` for persistent user preferences (view mode, sort, theme)
- `@Environment(\.modelContext)` for database writes
- `LoadState` enum (`.idle`, `.loading`, `.loaded`, `.failed(String)`) standardizes async UI state across all views

## Key Conventions

### Naming
- **Types:** PascalCase (`PlantFormViewModel`, `CareCalculator`)
- **Properties/methods:** camelCase (`wateringFrequency`, `setLoading()`)
- **Files:** Match the primary type they contain (`PlantDetailView.swift` contains `PlantDetailView`)
- **Enums:** PascalCase type, camelCase cases (`CareType.watering`, `LightLevel.medium`)

### Code Organization
- Use `// MARK: -` comments to organize sections within files
- Doc comments (`///`) on public types and non-obvious methods
- `@MainActor` on ViewModels and UI-facing classes
- `nonisolated` on protocol conformance methods that run off main thread

### Error Handling
- Custom error types conforming to `LocalizedError`
- `ErrorMessageFormatter` converts errors to user-friendly strings
- `LoadState.failed(String)` for propagating errors to UI
- `LoadStateView` provides a reusable loading/error/retry pattern

### Security
- API keys stored in Keychain via `SecureStorage` — never in UserDefaults or plain text
- `OpenAIConfig` handles migration from UserDefaults to Keychain for older installs
- No third-party analytics or tracking

### Theme
- All colors, typography, spacing, and corner radii defined in `BotanicaTheme` (`Core/Theme/BotanicaTheme.swift`)
- Use `BotanicaTheme.Colors.*`, `BotanicaTheme.Typography.*`, `BotanicaTheme.Spacing.*` — do not hardcode style values
- Dynamic light/dark mode colors throughout

### Testing
- XCTest framework with `@testable import Botanica`
- SwiftData in-memory containers for test isolation (`isStoredInMemoryOnly: true`)
- `@MainActor` on test classes that touch SwiftUI/SwiftData
- `setUp()` / `tearDown()` pattern with explicit nil-out in tearDown
- Tests live in `BotanicaTests/` — named `*Tests.swift`

### Data Seeding
- In DEBUG builds, `DevBlossomSeeder` seeds sample plants on first launch when the store is empty
- Uses embedded data from `DevBlossomSeedData.swift`, not external JSON files
- Prevents duplication by checking existing plant count

## SwiftData Model Relationships

```
Plant (root entity)
├── photos: [Photo]         (cascade delete)
├── careEvents: [CareEvent] (cascade delete)
├── reminders: [Reminder]   (cascade delete)
└── carePlan: CarePlan?     (cascade delete)
```

## Common Patterns

### Adding a New View
1. Create a SwiftUI view in `Views/`
2. If it needs async state, create a ViewModel in `ViewModels/` conforming to the `ViewModel` protocol
3. Use `LoadStateView` for loading/error states
4. Access data via `@Query` or `@Environment(\.modelContext)`
5. Use `BotanicaTheme` for all styling

### Adding a New Service
1. Create in `Services/`
2. If it should be app-wide, add it to `AppServices` and inject via Environment
3. Use `@MainActor` for anything touching UI state

### Adding a New Model Property
1. Add the property to the `@Model` class in `DataModels.swift`
2. If it's an array of value types, register a transformer in `ModelTransformers`
3. Update `DataImportService` and `DataExportService` if the field should be importable/exportable
4. Update related ViewModels and Views

## Privacy Permissions (Info.plist)

- `NSCameraUsageDescription` — Plant photos and AI identification
- `NSPhotoLibraryUsageDescription` — Select plant images
- `NSPhotoLibraryAddUsageDescription` — Save plant photos
- `NSLocationWhenInUseUsageDescription` — Weather-based care tips

## Version

- Current: v1.2.0 (2025-11-23)
- See `CHANGELOG.md` for history
