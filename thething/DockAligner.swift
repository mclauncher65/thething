//
//  DockAligner.swift
//  thething
//
//  Created by rdjpower on 4/6/26.
//

import Foundation
import AppKit
import SwiftUI
import Combine

enum DockAlignment: String, CaseIterable, Identifiable {
    case left, right, bottom
    var id: Self {self}
}

class DockAlignerFormHeader: ObservableObject {
    @Published var dockAlignment: DockAlignment
    
    init(_ dockAlignment: DockAlignment) {
        self.dockAlignment = dockAlignment
    }
}

struct DockAlignerForm: View {
    private static var holder = DockAlignerFormHeader(.bottom)
    @ObservedObject private var obj = holder
    
    init(_ data: SharedController) {
        data.submitData = { [self] sTime, eTime in
            return AppleScriptWrapper(name: "Dock Alignment",
                                      script: "tell application \"System Events\" to tell dock preferences to set screen edge to \(obj.dockAlignment.rawValue)",
                                      startTime: sTime,
                                      endTime: eTime)
        }
    }
    
    var body: some View {
        Section("General") {
            LabeledContent {
                Picker("Where will the dock be?", selection: $obj.dockAlignment) {
                    ForEach(DockAlignment.allCases) { al in
                        Text(al.rawValue.capitalized)
                    }
                }
            } label: {
                Text("Dock Alignment: ")
            }
        }
    }
}
