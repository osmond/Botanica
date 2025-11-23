import Foundation
import SwiftUI

@MainActor
final class PlantHealthVisionViewModel: ObservableObject, ViewModel {
    @Published var loadState: LoadState = .idle
    @Published var quickResult: QuickHealthScreen?
    @Published var analysis: PlantHealthAnalysis?
    @Published var history: [PlantHealthAnalysis] = []
    @Published var errorMessage: String?
    
    private let analyzer: PlantHealthVisionAnalyzer
    
    init(analyzer: PlantHealthVisionAnalyzer = PlantHealthVisionAnalyzer()) {
        self.analyzer = analyzer
        self.history = analyzer.analysisHistory
    }
    
    func quickAnalyze(image: UIImage) async {
        setLoading()
        do {
            let result = try await analyzer.quickHealthScreen(image: image)
            quickResult = result
            setLoaded()
        } catch {
            errorMessage = error.localizedDescription
            setFailed(error.localizedDescription)
        }
    }
    
    func fullAnalyze(image: UIImage, plant: Plant) async {
        setLoading()
        do {
            let result = try await analyzer.analyzeHealthFromPhoto(image: image, plant: plant)
            analysis = result
            history = analyzer.analysisHistory
            setLoaded()
        } catch {
            errorMessage = error.localizedDescription
            setFailed(error.localizedDescription)
        }
    }
}
