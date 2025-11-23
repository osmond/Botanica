# Changelog

## v1.2.0 - 2025-11-23
- Refined MyPlantsView by extracting reusable sections and simplifying the main body.
- Added shared load/error handling via `LoadState` and `LoadStateView` across AI, analytics, import/export, and health vision flows with retries.
- Introduced AI placeholder image pipeline (PlantImageService) and wired async thumbnails into AI coach header and plant components.
- Added new app services (OpenAIClient, Notification, Analytics) and view models (MainTabCoordinator, AnalyticsViewModel, PlantFormViewModel, PlantHealthVisionViewModel); added PlantForm tests.
- Standardized import/export screens and health vision UX around the shared loading/error pattern.
