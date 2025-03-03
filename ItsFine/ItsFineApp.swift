//
//  ItsFineApp.swift
//  ItsFine
//
//  Created by PJ Gray on 3/2/25.
//

import SwiftUI
import OSLog

@main
struct ItsFineApp: App {
    private let logger = Logger(subsystem: "ItsFine.ItsFineApp", category: "ItsFineApp")
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    logger.info("ItsFineApp started and ContentView is presented.")
                }
        }
    }
}
