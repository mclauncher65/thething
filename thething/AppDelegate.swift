//
//  AppDelegate.swift
//  thething
//
//  Created by Dev Dashora on 3/30/26.
//

import Cocoa
import SwiftUI
import UniformTypeIdentifiers
import AVFoundation

enum Target: CaseIterable, Identifiable {
    var id: UUID {
        return UUID()
    }
    
    case RED
    case GREEN
    case TEAL
    case PURPLE
    
    private static var controllers: [Target : SharedController] = [:]
    
    func getController() -> SharedController {
        if Self.controllers[self] == nil {
            Self.controllers[self] = .init()
        }
        
        return Self.controllers[self]!
    }
    
    func getValue() -> Color {
        switch self {
        case .RED:
            return .red
        case .GREEN:
            return .green
        case .TEAL:
            return .teal
        case .PURPLE:
            return .purple
        }
    }
}
    
struct FormHeader: View {
    let title: String
    
    init(_ title: String) {
        self.title = title
    }
    
    var body: some View {
        HStack {
            Rectangle()
                .frame(width: 25, height: 1)
                .tint(.gray)
            Text(title)
            Rectangle()
                .frame(width: 50, height: 1)
                .tint(.gray)
        }
    }
}

func format(_ str: String) -> UInt? {
    let split = str.split(separator: ":")
    if split.count != 3 {
        return nil
    }
    
    guard let first = split.first else {
        return nil
    }
    
    let second = split[1]
    
    guard let third = split.last else {
        return nil
    }
    
    guard let minutes = UInt(first) else {
        return nil
    }
    
    guard let seconds = UInt(second) else {
        return nil
    }
    
    guard let milliseconds = UInt(third) else {
        return nil
    }
    
    return 60000*minutes + 1000*seconds + milliseconds
}

func deformat(_ x: UInt) -> String {
    return String(format: "%02d", (x/60000)) + ":" + String(format: "%02d", (x/1000) % 60) + ":" + String(format: "%03d", x % 1000)
}

struct TimecodeView : View {
    @State var item : any Useful
    @State private var timeStart: String
    @State private var timeEnd: String
    @FocusState private var timeStartFocus
    @FocusState private var timeEndFocus
    
    private let del: () -> Void
    private let set: () -> Void
    
    init(_ item: any Useful, _ set: @escaping () -> Void, _ del: @escaping () -> Void) {
        self.del = del
        self.set = set
        self.item = item
        self.timeStart = deformat(item.startTime)
        self.timeEnd = deformat(item.endTime)
    }
    
    var body: some View {
        HStack {
            Text(item.name)
            TextField("mm:ss:msms", text: $timeStart)
                .focused($timeStartFocus)
                .onChange(of: timeStartFocus, {
                    if $1 {
                       return
                    }
                    
                    guard let unwrappedTimeStart = format(timeStart) else {
                        let al = NSAlert()
                        al.messageText = "Invalid timecode for Time Start"
                        al.informativeText = "Use mm:ss:msms format."
                        al.runModal()
                        return
                    }
                    
                    item.startTime = unwrappedTimeStart
                    set()
                }).fixedSize()
            Text("to")
            TextField("mm:ss:msms", text: $timeEnd)
                .focused($timeEndFocus)
                .onChange(of: timeEndFocus, {
                    if $1 {
                       return
                    }
                
                    guard let unwrappedTimeEnd = format(timeEnd) else {
                        let al = NSAlert()
                        al.messageText = "Invalid timecode for Time End"
                        al.informativeText = "Use mm:ss:msms format."
                        al.runModal()
                        return
                    }
                    item.endTime = unwrappedTimeEnd
                    set()
                }).fixedSize()
            Spacer().frame(maxWidth: .infinity, alignment: .leading)
        }.frame(maxWidth: .infinity).overlay(alignment: .trailing) {
            Button(action: del) {
                Image(systemName: "minus")
            }.buttonStyle(BorderlessButtonStyle())
        }
    }
}

protocol Useful: Identifiable {
    var id: UUID {get}
    var name: String {get}
    var startTime: UInt {get set}
    var endTime: UInt {get set}
    
    func `do`()
    func done()
}

class SharedController {
    var submitData: ((UInt, UInt) -> any Useful)?
    init(_ submitData: ((UInt, UInt) -> any Useful)? = nil) {
        self.submitData = submitData
    }
}

class KeyCodesHandler {
    static var onRecordKeyCodeRun: () -> Void = {}
    static var onStopRecordKeyCodeRun: () -> Void = {}
}

@_cdecl("RecordKeyCode_Swift")
func onRecordKeyCode() {
    KeyCodesHandler.onRecordKeyCodeRun()
}

@_cdecl("StopRecordKeyCode_Swift")
func onStopRecordKeyCode() {
    KeyCodesHandler.onStopRecordKeyCodeRun()
}

extension View {
    func setRecordKeyCode(fn: @escaping () -> Void) -> some View {
        KeyCodesHandler.onRecordKeyCodeRun = fn
        return self
    }
    
    func setStopRecordKeyCode(fn: @escaping () -> Void) -> some View {
        KeyCodesHandler.onStopRecordKeyCodeRun = fn
        return self
    }
}

struct AppView: View {
    @State private var target = Target.RED
    
    @State private var timeStart = "00:00:000"
    @State private var timeEnd = "00:00:000"
    
    @State private var highest: UInt = 0
    
    @State private var list: [any Useful] = []
    @State private var done = false
    
    @State private var openedFile = false
    @State private var audioPlayer: AVAudioPlayer? = nil
    
    @State private var mainWindow: NSWindow
    
    init() {
        mainWindow = (NSApp.delegate as! AppDelegate).window!
    }
    
    func play() {
        mainWindow.setIsVisible(false)
        NSApp.activate()
        
        Thread.sleep(forTimeInterval: 1)
        
        audioPlayer?.play()
        Task {
            var millis = 0
            while millis <= highest && !done {
                let currentMillis = millis
                
                Task {
                    for item in list {
                        if item.startTime != currentMillis && item.endTime != currentMillis {
                            continue
                        }
                        
                        if item.startTime == currentMillis {
                            item.do()
                        }
                        
                        if item.endTime == currentMillis {
                            item.done()
                        }
                    }
                }
                
                millis += 1
                try await Task.sleep(nanoseconds: 1_000_000)
            }
            
            done = false
            
            for item in list {
                item.done()
            }
            
            mainWindow.setIsVisible(true)
            mainWindow.makeKeyAndOrderFront(nil)
        }
    }
    
    func stop() {
        audioPlayer?.stop()
        audioPlayer?.currentTime = 0
        done = true
    }
    
    var body: some View {
        VStack {
            HStack(spacing: 15) {
                ForEach(Target.allCases) { color in
                    Button(action: {
                        target = color
                    }) {
                        Rectangle()
                            .fill(color.getValue())
                        .frame(width: 100, height: 100)
                        .border(target == color ? Color.accentColor : .black, width: 2)
                    }
                    .tint(.clear)
                }
            }.padding(.all, 25)
                .background(.gray, in: Rectangle())
                .border(.black)
            
            Button("Spawn", action: {
                guard let unwrappedTimeStart = format(timeStart) else {
                    let al = NSAlert()
                    al.messageText = "Invalid timecode for Time Start"
                    al.informativeText = "Use mm:ss:msms format."
                    al.runModal()
                    return
                }
                
                guard let unwrappedTimeEnd = format(timeEnd) else {
                    let al = NSAlert()
                    al.messageText = "Invalid timecode for Time Start"
                    al.informativeText = "Use mm:ss:msms format."
                    al.runModal()
                    return
                }
                
                if unwrappedTimeEnd > highest {
                    highest = unwrappedTimeEnd
                    timeStart = deformat(highest)
                    timeEnd = deformat(highest)
                }
                
                guard let item = target.getController().submitData?(unwrappedTimeStart, unwrappedTimeEnd) else {
                    return
                }
                
                list.append(item)
                
                list.sort(by: {
                    return $0.endTime < $1.endTime
                })
            }).buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
            
            List {
                Section("Audio Track") {
                    LabeledContent {
                        Button("Open File") {
                            openedFile = true
                        }.fileImporter(isPresented: $openedFile, allowedContentTypes: [.audio], onCompletion: {url in
                        do {
                            let url = try url.get()
                            let worked = url.startAccessingSecurityScopedResource()
                            if !worked {
                                return
                            }
                            
                            audioPlayer = try AVAudioPlayer(contentsOf: url)
                            audioPlayer?.prepareToPlay()
                            
                            url.stopAccessingSecurityScopedResource()
                        } catch {
                            NSAlert(error: error).runModal()
                        }
                    })
                    } label: {
                        Text("Select an audio track to play.")
                    }
                }
                
                Section("Play/Pause") {
                    HStack {
                        Button(action: stop) {
                            Image(systemName: "stop.fill")
                        }.buttonStyle(BorderlessButtonStyle())
                            .setStopRecordKeyCode(fn: stop)
                        Text("⌘ ⇧ R")
                        
                        Button(action: play) {
                            Image(systemName: "play.fill")
                        }.buttonStyle(BorderlessButtonStyle())
                            .setRecordKeyCode(fn: play)
                        Text("⌘ R")
                    }
                }
                
                Section("Timecodes") {
                    ForEach(list, id: \.id) {item in
                        TimecodeView(item, {
                            list.sort(by: {
                                return $0.endTime < $1.endTime
                            })
                            
                            highest = list.last?.endTime ?? 0
                            timeStart = deformat(highest)
                            timeEnd = deformat(highest)
                        }, {
                            var bool = false
                            if list.last?.id == item.id {
                                bool = true
                            }
                            list.removeAll(where: {$0.id == item.id})
                            if bool {
                                highest = list.last?.endTime ?? 0
                                timeStart = deformat(highest)
                                timeEnd = deformat(highest)
                            }
                        })
                    }
                    
                    LabeledContent {
                        TextField("Format: mm:ss:msms", text: $timeStart).textFieldStyle(.squareBorder).fixedSize()
                    } label: {
                        Text("Time Start: ")
                    }
                    
                    LabeledContent {
                        TextField("Format: mm:ss:msms", text: $timeEnd).textFieldStyle(.squareBorder).fixedSize()
                    } label: {
                        Text("Time End: ")
                    }
                }
                
                switch target {
                case .RED:
                    AlertForm(target.getController(), lastAlert: list.filter({$0 is AlertHeader}).last as? AlertHeader)
                case .GREEN:
                    DockAlignerForm(target.getController())
                case .TEAL:
                    DesktopImageSetterForm(target.getController())
                case .PURPLE:
                    FileSpammerForm(target.getController())
                }
            }.listStyle(.plain)
            
            
            Text("Made with 􀊵 by rdjpower")
        }.padding()
    }
}

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    public var window: NSWindow?
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        RecordKeyCode_init()
        StopRecordKeyCode_init()
        
        window = NSWindow(contentRect: NSRect(x: 0, y: 0,
                                              width:  512,
                                              height: 512),
                          styleMask: [.miniaturizable, .closable, .resizable, .titled],
                          backing: .buffered,
                          defer: false)
        window?.title = "thething"
        window?.contentView = NSHostingView(rootView: AppView())
        window?.makeKeyAndOrderFront(nil)
        window?.center()
        
        guard let menu = NSApp.mainMenu else {
            return
        }
        
        guard let app = menu.item(at: 0),
              let submenu = app.submenu else { return }
        
        let about = NSMenuItem(title: "About thething", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        
        submenu.insertItem(about, at: 0)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
        RecordKeyCode_deinit()
        StopRecordKeyCode_deinit()
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}

