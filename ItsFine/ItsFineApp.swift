//
//  ItsFineApp.swift
//  ItsFine
//
//  Created by PJ Gray on 3/2/25.
//

import SwiftUI

@main
struct ItsFineApp: App {
    @StateObject private var logger = Logger(subsystem: "ItsFine.ItsFineApp", category: "ItsFineApp")
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    logger.info("ItsFineApp started and ContentView is presented.")
                }
        }
    }
}
