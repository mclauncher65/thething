//
//  FileSpammer.swift
//  thething
//
//  Created by Dev Dashora on 4/5/26.
//

import Foundation
import AppKit
import SwiftUI
import Combine
import AudioToolbox

class FileSpammerFormHeader: ObservableObject {
    @Published var count : String
    
    init(count: String = "1") {
        self.count = count
    }
}

struct FileSpammerForm: View {
    private static var holder = FileSpammerFormHeader();
    @ObservedObject private var obj = holder;
    
    init(_ data: SharedController) {
        data.submitData = { [self] sTime, eTime in
            return FileSpammer(startTime: sTime, endTime: eTime, count: UInt(self.obj.count)!)
        }
    }
    
    var body: some View {
        Section("General") {
            LabeledContent {
                TextField("Some Number", text: $obj.count).textFieldStyle(.squareBorder).fixedSize()
                    .onChange(of: obj.count) { old, new in
                        if UInt(new) != nil && UInt(new)! > 0 {
                            return
                        }
                        
                        obj.count = old
                    }
            } label: {
                Text("Number of Files Spammed: ")
            }
        }
    }
}

class FileSpammer: Useful, Identifiable {
    let id = UUID()
    let name: String = "File Spam"
    let count: UInt
    
    var urls: [URL] = []
    var startTime: UInt
    var endTime: UInt
    
    init(startTime: UInt, endTime: UInt, count: UInt) {
        self.startTime = startTime
        self.endTime = endTime
        self.count = count
    }
    
    func `do`() {
        for i in 1...count {
            let url = URL.desktopDirectory.appending(path: "\(i).txt")
            urls.append(url)
            
            do {
                _ = url.startAccessingSecurityScopedResource()
                try Data().write(to: url)
                url.stopAccessingSecurityScopedResource()
            } catch {
                NSAlert(error: error).runModal()
            }
        }
    }
    
    func done() {
        for u in urls {
            do {
                try FileManager.default.trashItem(at: u, resultingItemURL: nil)
                AudioServicesPlaySystemSound(SystemSoundID(0x10))
            } catch {
                NSAlert(error: error).runModal()
            }
        }
        
        urls = []
    }
}
