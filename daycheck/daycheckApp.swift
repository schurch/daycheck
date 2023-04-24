//
//  daycheckApp.swift
//  daycheck
//
//  Created by Stefan Church on 22/04/23.
//

import SwiftUI

@main
struct daycheckApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            MainView()
        }
    }
}
