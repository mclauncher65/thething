//
//  DesktopImageSetter.swift
//  thething
//
//  Created by Dev Dashora on 4/7/26.
//

import Foundation
import AppKit
import SwiftUI
import Combine
import UniformTypeIdentifiers

class DesktopImageSetterFormHeader: ObservableObject {
    @Published var openFilePicker: Bool
    @Published var url: URL
    @Published var img: NSImage = NSImage()
    
    init() {
        openFilePicker = false
        url = NSWorkspace.shared.desktopImageURL(for: NSScreen.main!)!
        img = NSImage(contentsOf: url)!
        img.size = .init(width: 64, height: 64)
    }
}

struct DesktopImageSetterForm: View {
    private static var holder = DesktopImageSetterFormHeader()
    @ObservedObject private var obj = holder
    
    init(_ data: SharedController) {
        data.submitData = { [self] sTime, eTime in
            return DesktopImageSetter(startTime: sTime, endTime: eTime, url: obj.url)
        }
    }
    
    var body: some View {
        Section("General") {
            Image(nsImage: obj.img)
            
            LabeledContent {
                Button("Open File") {
                    obj.openFilePicker = true
                }.fileImporter(isPresented: $obj.openFilePicker, allowedContentTypes: [.image], onCompletion: {url in
                    do {
                        let url = try url.get()
                        let worked = url.startAccessingSecurityScopedResource()
                        if !worked {
                            return
                        }
                        
                        obj.url = url
                        
                        obj.img = NSImage(contentsOf: url)!
                        obj.img.size = .init(width: 64, height: 64)
                        
                        url.stopAccessingSecurityScopedResource()
                    } catch {
                        NSAlert(error: error).runModal()
                    }
                })
            } label: {
                Text("New Desktop Image: ")
            }
        }
    }
}

class DesktopImageSetter: Useful, Identifiable {
    let id = UUID()
    let name: String = "Set Desktop Image"
    
    var startTime: UInt
    var endTime: UInt // ~~Useless~~
    var url: URL
    
    init(startTime: UInt, endTime: UInt, url: URL) {
        self.startTime = startTime
        self.endTime = endTime
        self.url = url
    }
    
    func `do`() {
        guard let m = NSScreen.main else {
            print("o")
            return
        }
        
        do {
            try NSWorkspace.shared.setDesktopImageURL(url, for: m)
        } catch {
            NSAlert(error: error).runModal()
        }
    }
    
    func done() {
        //~~Useless~~
    }
}
