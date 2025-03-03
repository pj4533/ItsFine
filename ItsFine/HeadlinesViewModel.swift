import Foundation
import SwiftUI
import os.log

class HeadlinesViewModel: ObservableObject {
    @Published var headlines: [Headline] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    private let logger = Logger(subsystem: "ItsFine.HeadlinesViewModel", category: "HeadlinesViewModel")
    
    init() {
        fetchHeadlines()
    }
    
    func fetchHeadlines() {
        isLoading = true
        RSSService().fetchHeadlines { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let headlines):
                    self?.headlines = headlines
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                    self?.logger.error("Failed to fetch headlines: \(error.localizedDescription)")
                }
            }
        }
    }
}
