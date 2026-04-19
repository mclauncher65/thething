//
//  AppleScriptWrapper.swift
//  thething
//
//  Created by rdjpower on 4/5/26.
//

import Foundation

struct AppleScriptWrapper: Useful, Identifiable {
    let id = UUID()
    let name: String
    let script: String
    
    var startTime: UInt
    var endTime: UInt // ~~ Useless ~~
    
    private enum CodingKeys : String, CodingKey {
        case name, script, startTime, endTime
    }
    
    init(name: String, script: String, startTime: UInt, endTime: UInt) {
        self.name = name
        self.startTime = startTime
        self.endTime = endTime
        self.script = script
    }
    
    @MainActor
    func `do`() {
        var ptr: NSDictionary?
        
        guard let scr = NSAppleScript(source: script) else {return}
        let res = scr.executeAndReturnError(&ptr) as NSAppleEventDescriptor?
        
        if let r = res {
            print(r)
        }
        
        guard let err = ptr else {
            return
        }
        
        print(err)
    }
    
    func done() {
        // ~~ Useless ~~
    }
}
