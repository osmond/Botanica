# Botanica

SwiftUI iOS plant care app for tracking plants, logging care, managing reminders, and optional OpenAI-powered identification and coaching.

## Features
- Today dashboard: due/overdue care summary, upcoming schedule, multi-care logging.
- My Plants: grid/list views, search/filter/grouping, plant detail with quick actions, care history, reminders, and photo management.
- AI Hub (optional OpenAI key): plant identification, AI coach chat, care assistant plans/diagnosis, health vision analysis, AI placeholder images for missing photos.
- Insights: care focus, attention flags, and seasonal guidance.
- Data and settings: JSON import/export, notification controls, theme, AI settings.

## Requirements
- Xcode 15+
- iOS 17+
- Swift 5.9
- SwiftData enabled
- Optional: OpenAI API key (set in app under Settings > AI Settings)

## Setup
1) Clone the repo and open `Botanica.xcodeproj` in Xcode.
2) Select the `Botanica` scheme and a simulator/device.
3) Build/Run (Cmd+R).
4) Optional: Settings > AI Settings > add your OpenAI API key.

## Data Seeding (Dev)
On first launch, if there are zero plants, the app seeds sample data from the embedded Blossom summary in `Services/DevBlossomSeedData.swift` via `Services/DevBlossomSeeder.swift`. Remove or gate this for production builds.

## Running Tests
```bash
xcodebuild -scheme Botanica -destination 'platform=iOS Simulator,name=iPhone 15' test
```
Adjust the destination to match your available simulator.

## Project Structure
- `Views/` UI screens and components
- `ViewModels/` screen view models and coordinators
- `Services/` app services (AI, notifications, import/export, seeding)
- `Core/` theme, app services wiring, utilities
- `Utils/` shared helpers (LoadState, performance helpers)
- `Models/` SwiftData models and list types
- `BotanicaTests/` unit tests

## Notable Settings and Toggles
- AI Settings: set OpenAI key, toggle AI placeholders for plant photos, reset coach suggestions.
- Notifications: permission handling, enable/disable per app, refresh schedule.
- My Plants: view mode, sort/group, filters persist via AppStorage.
- Import/Export: JSON flows with shared LoadState UI.

## Release
- Latest tag: `v1.2.0` (see `CHANGELOG.md`).

## Badges
![Platform](https://img.shields.io/badge/platform-iOS-lightgrey)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![SwiftUI](https://img.shields.io/badge/SwiftUI-%E2%9C%93-blue)
![SwiftData](https://img.shields.io/badge/SwiftData-%E2%9C%93-green)
![AI](https://img.shields.io/badge/AI-OpenAI-brightgreen)

## Screenshots
(suggested captures)
- Today dashboard with care summary
- My Plants grid/list with filters
- Plant Detail with quick actions and care history
- AI Plant Coach or Care Assistant
- Health Vision analysis
