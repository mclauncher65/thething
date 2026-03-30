//
//  Main.swift
//  thething
//
//  Created by Dev Dashora on 3/30/26.
//

import AppKit

@main
struct App {
    static func main() {
        let app = NSApplication.shared
        let del = AppDelegate()
        app.delegate = del
        _ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
    }
}
