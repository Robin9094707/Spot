//
//  SpotApp.swift
//  Spot
//
//  Created by Leon Böttger on 05.12.24.
//

import LUI
import SwiftUI
import WebKit

@main
struct SpotApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        LUIInit(configuration: configuration)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
