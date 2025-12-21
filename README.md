# Botanica

A SwiftUI iOS app for thoughtful plant care.
Track plants, log care, receive insights, and explore optional AI-assisted identification and coaching.

**Status:** Active development | iOS 17+ | Swift 5.9

## Key Differentiators
- Local-first plant tracking with optional AI assistance.
- Daily care dashboard with summaries and reminders.
- Photo-based identification and health analysis.
- Calm, low-friction UI for long-term use.

## Requirements
- Xcode 15+
- iOS 17+
- Swift 5.9
- SwiftData enabled
- Optional: OpenAI API key (set in app under Settings > AI Settings)

## Quick Start
1) Clone the repo and open `Botanica.xcodeproj` in Xcode.
2) Select the `Botanica` scheme and a simulator/device.
3) Build/Run (Cmd+R).

### Optional AI Setup
1) Open Settings > AI Settings.
2) Add your OpenAI API key.

The app runs fully without an OpenAI key.

## Features
### Daily Use
- Today dashboard: due/overdue care summary, upcoming schedule, multi-care logging.
- My Plants: grid/list views, search/filter/grouping, plant detail with quick actions, care history, reminders, and photo management.
- Photo management and care notes.

### Insights and AI
- AI Hub: identification, AI coach chat, care assistant plans/diagnosis, health vision analysis.
- Seasonal guidance and care focus insights.
- Optional OpenAI integration for AI features.

### Data and Customization
- JSON import/export.
- Notification controls and scheduling.
- Theme and app settings.

## Screenshots
### Core App Views
| My Plants | Plant Detail | Today |
| --- | --- | --- |
| <img src="screenshots/Simulator Screenshot - iPhone 16e - 2025-12-21 at 07.35.48.png" width="240" alt="My Plants" /><br><sub>My Plants overview</sub> | <img src="screenshots/Simulator Screenshot - iPhone 16e - 2025-12-21 at 07.36.21.png" width="240" alt="Plant Detail" /><br><sub>Plant detail and schedule</sub> | <img src="screenshots/Simulator Screenshot - iPhone 16e - 2025-12-21 at 07.37.42.png" width="240" alt="Today" /><br><sub>Today summary</sub> |

### AI and Insights
| AI Hub | Plant Identification | Health Analysis |
| --- | --- | --- |
| <img src="screenshots/Simulator Screenshot - iPhone 16e - 2025-12-21 at 07.36.46.png" width="240" alt="AI Hub" /><br><sub>AI hub and insights</sub> | <img src="screenshots/Simulator Screenshot - iPhone 16e - 2025-12-21 at 07.38.08.png" width="240" alt="Plant Identification" /><br><sub>AI plant identification</sub> | <img src="screenshots/Simulator Screenshot - iPhone 16e - 2025-12-21 at 07.38.58.png" width="240" alt="Health Analysis" /><br><sub>Health analysis entry</sub> |

## Design Philosophy
Botanica aims to be calm, non-gamified, and easy to stick with. Clarity over density, with gentle prompts instead of pressure.

## Project Structure
- `Views/` SwiftUI screens and navigation flows.
- `ViewModels/` State management and business logic.
- `Services/` Persistence, AI services, imports, and seeding.
- `Core/` Theme, app wiring, and utilities.
- `Utils/` Shared helpers and extensions.
- `Models/` SwiftData models and types.
- `BotanicaTests/` Unit tests.

## Data Seeding (Dev)
In DEBUG builds, on first launch with zero plants, the app seeds sample data from the embedded Blossom summary in `Services/DevBlossomSeedData.swift` via `Services/DevBlossomSeeder.swift`.

## Notable Settings and Toggles
- AI Settings: set OpenAI key, toggle AI placeholders for plant photos, reset coach suggestions.
- Notifications: permission handling, enable/disable per app, refresh schedule.
- My Plants: view mode, sort/group, filters persist via AppStorage.
- Import/Export: JSON flows with shared LoadState UI.

## Running Tests
```bash
xcodebuild -scheme Botanica -destination 'platform=iOS Simulator,name=iPhone 15' test
```
Adjust the destination to match your available simulator.

## Roadmap
- [ ] Calendar-based care view
- [ ] Expanded plant diagnostics

## Release
- Latest tag: `v1.2.0` (see `CHANGELOG.md`).

## Badges
![Platform](https://img.shields.io/badge/platform-iOS-lightgrey)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![SwiftUI](https://img.shields.io/badge/SwiftUI-%E2%9C%93-blue)
![SwiftData](https://img.shields.io/badge/SwiftData-%E2%9C%93-green)
![AI](https://img.shields.io/badge/AI-OpenAI-brightgreen)
