import Foundation
import SwiftUI
import os.log

class HeadlinesViewModel: ObservableObject {
    @Published var headlines: [Headline] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    private let logger = Logger(subsystem: "ItsFine.HeadlinesViewModel", category: "HeadlinesViewModel")
    private let rssService = RSSService()
    
    init() {
        logger.info("HeadlinesViewModel initialized. Starting to fetch headlines.")
        fetchHeadlines()
    }
    
    func fetchHeadlines() {
        logger.info("Fetching headlines...")
        isLoading = true
        rssService.fetchHeadlines { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoading = false
                switch result {
                case .success(let headlines):
                    self.headlines = headlines
                    self.logger.info("Successfully fetched \(headlines.count) headlines.")
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    self.logger.error("Failed to fetch headlines: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func transformHeadlines() {
        logger.info("Transforming headlines using OpenAIDataSource...")
        isLoading = true
        OpenAIDataSource.shared.transformHeadlines(headlines) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoading = false
                switch result {
                case .success(let transformedHeadlines):
                    self.headlines = transformedHeadlines
                    self.logger.info("Successfully transformed headlines. Total: \(transformedHeadlines.count)")
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    self.logger.error("Failed to transform headlines: \(error.localizedDescription)")
                }
            }
        }
    }
}
