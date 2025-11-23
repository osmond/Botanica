# Botanica

SwiftUI plant care app with SwiftData, AI-powered helpers, and rich analytics.

## Features
- My Plants: grid/list with filters, grouping, quick care insights, and AI placeholders for missing photos (toggle in AI Settings).
- Plant Detail: hero photo, quick care actions, care history, reminders, and photo manager.
- AI: coach chat (per-plant history), health vision analysis, plant identification, care assistant tabs.
- Data: import/export flows with shared load/error handling; notifications with permission handling.
- Analytics: collection health, streaks, recommendations, advanced dashboards.

## Requirements
- Xcode 16+
- iOS 17+ (targets iPhone/iPad; tested on iPhone 16 simulator)
- SwiftData enabled
- Optional: OpenAI API key for AI features (set in app UI under AI Settings)

## Setup
1) Clone the repo and open `Botanica.xcodeproj` in Xcode.
2) Select the `Botanica` scheme and a simulator/device (e.g., iPhone 16).
3) Build/Run (⌘R).
4) For AI features: open Settings → AI Settings, add your OpenAI API key, and toggle AI placeholders if desired.

## Running Tests
```bash
xcodebuild -scheme Botanica -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.5' test
```
Adjust the destination to your available simulator/device.

## Project Structure
- `Views/` UI screens and components
- `ViewModels/` screen view models (e.g., PlantForm, PlantDetail, Analytics)
- `Services/` app services (AI, notifications, analytics, image, seeding/import/export)
- `Core/` utilities, theme, app services wiring
- `Utils/` shared helpers (LoadState, image/cache utilities)
- `Models/` SwiftData models and list types
- `BotanicaTests/` unit tests (e.g., PlantFormViewModelTests)

## Notable Settings & Toggles
- AI Settings: set OpenAI key; toggle AI placeholders for plant photos (PlantImageService); clear AI cache.
- Notifications: permission/refresh/clear actions with load/error feedback.
- My Plants: view mode, sort/group, filters persist via AppStorage.
- Import/Export/Photo flows: use shared `LoadStateView` with retry/error messaging.

## Release
- Latest tag: `v1.2.0` (see `CHANGELOG.md`).
