import Foundation
import SwiftUI
import SwiftData

/// View model that computes analytics summaries off the main thread.
@MainActor
final class AnalyticsViewModel: ObservableObject, ViewModel {
    @Published var loadState: LoadState = .idle
    @Published var snapshot: AnalyticsSnapshot?
    
    private let service: AnalyticsService
    
    init(service: AnalyticsService = AppServices().analytics) {
        self.service = service
    }
    
    func refresh(plants: [Plant], careEvents: [CareEvent], range: AnalyticsTimeRange) {
        setLoading()
        Task {
            let result = await service.snapshot(plants: plants, careEvents: careEvents, range: range)
            await MainActor.run {
                snapshot = result
                setLoaded()
            }
        }
    }
    
    /// Returns health delta vs previous range (placeholder until historic baselines are stored)
    func healthDelta(for range: AnalyticsTimeRange) -> Double? {
        // Without historical snapshot storage, return nil for now.
        return nil
    }
    
    // Placeholder for future filter state if analytics adds drill-down interactions.
}
