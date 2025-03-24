//
//  TranslateMeApp.swift
//  TranslateMe
//
//  Created by Julian Valencia on 3/23/25.
//

import SwiftUI
import Firebase

@main
struct TranslationMeApp: App {
    
    init() {
        // Initialize Firebase
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
