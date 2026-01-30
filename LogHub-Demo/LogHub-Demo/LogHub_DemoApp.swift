//
//  LogHub_DemoApp.swift
//  LogHub-Demo
//
//  Created by Abdullah Al Hadi on 30/1/26.
//

import SwiftUI

@main
struct LogHub_DemoApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(LoggingController.shared)
        }
    }
}
