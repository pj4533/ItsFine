import Foundation
import SwiftUI
import os.log

class HeadlinesViewModel: ObservableObject {
    @Published var headlines: [Headline] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    private let logger = Logger(subsystem: "ItsFine.HeadlinesViewModel", category: "HeadlinesViewModel")
    private let rssService = RSSService()
    
    // Property to hold the next set of transformed headlines
    private var nextTransformedHeadlines: [Headline]? = nil
    
    // Flag to indicate if a background transformation is in progress
    private var isBackgroundTransforming: Bool = false
    
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
                    // Start pre-fetching transformed headlines in the background
                    self.transformHeadlinesInBackground()
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    self.logger.error("Failed to fetch headlines: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func transformHeadlines() {
        logger.info("Transforming headlines...")
        
        if let preFetchedHeadlines = nextTransformedHeadlines {
            // Use the pre-fetched transformed headlines
            self.headlines = preFetchedHeadlines
            self.logger.info("Applied pre-fetched transformed headlines.")
            // Reset the pre-fetched headlines
            self.nextTransformedHeadlines = nil
            // Start pre-fetching the next set of transformed headlines
            self.transformHeadlinesInBackground()
        } else {
            // If no pre-fetched headlines are available, perform transformation immediately
            logger.info("No pre-fetched headlines available. Performing on-demand transformation.")
            isLoading = true
            OpenAIDataSource.shared.transformHeadlines(headlines) { [weak self] result in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    self.isLoading = false
                    switch result {
                    case .success(let transformedHeadlines):
                        self.headlines = transformedHeadlines
                        self.logger.info("Successfully transformed headlines. Total: \(transformedHeadlines.count)")
                        // Start pre-fetching the next set of transformed headlines
                        self.transformHeadlinesInBackground()
                    case .failure(let error):
                        self.errorMessage = error.localizedDescription
                        self.logger.error("Failed to transform headlines: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    private func transformHeadlinesInBackground() {
        // Prevent multiple background transformations from running simultaneously
        guard !isBackgroundTransforming else {
            logger.info("Background transformation already in progress.")
            return
        }
        
        isBackgroundTransforming = true
        logger.info("Starting background transformation of headlines.")
        
        OpenAIDataSource.shared.transformHeadlines(headlines) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isBackgroundTransforming = false
                switch result {
                case .success(let transformedHeadlines):
                    self.nextTransformedHeadlines = transformedHeadlines
                    self.logger.info("Successfully pre-fetched transformed headlines. Total: \(transformedHeadlines.count)")
                case .failure(let error):
                    self.logger.error("Failed to pre-fetch transformed headlines: \(error.localizedDescription)")
                    // Optionally, handle the error (e.g., retry logic, user notification)
                }
            }
        }
    }
}
