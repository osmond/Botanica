import Foundation

/// Common loading states for async view models.
enum LoadState: Equatable {
    case idle
    case loading
    case loaded
    case failed(String)
}

/// Simple protocol for view models to standardize loading/error handling.
@MainActor
protocol ViewModel: ObservableObject {
    var loadState: LoadState { get set }
    
    func setLoading()
    func setLoaded()
    func setFailed(_ message: String)
}

extension ViewModel {
    func setLoading() { loadState = .loading }
    func setLoaded() { loadState = .loaded }
    func setFailed(_ message: String) { loadState = .failed(message) }
}
