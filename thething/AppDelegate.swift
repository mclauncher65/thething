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
import Combine

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

protocol Useful: Identifiable, Codable {
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

enum err : Error {
    case no
}

class AnyUseful: Useful {
    var body: any Useful
    
    let id = UUID()
    let name: String
    var startTime: UInt
    var endTime: UInt
    
    enum CodingKeys: String, CodingKey {
        case name, startTime, endTime, body
    }
    
    func `do`() {
        body.do()
    }
    
    func done() {
        body.done()
    }
    
    init(body: any Useful) {
        self.body = body
        self.name = body.name
        self.startTime = body.startTime
        self.endTime = body.endTime
    }
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(startTime, forKey: .startTime)
        try container.encode(endTime, forKey: .endTime)
        try container.encode(body, forKey: .body)
    }
    
    required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        startTime = try container.decode(UInt.self, forKey: .startTime)
        endTime = try container.decode(UInt.self, forKey: .endTime)
        
        switch name {
        case "Alert":
            body = try container.decode(AlertHeader.self, forKey: .body)
            return
        case "Set Desktop Image":
            body = try container.decode(DesktopImageSetter.self, forKey: .body)
            return
        case "Dock Alignment":
            body = try container.decode(AppleScriptWrapper.self, forKey: .body)
            return
        case "File Spam":
            body = try container.decode(FileSpammer.self, forKey: .body)
            return
        default: break
        }
        
        throw err.no
    }
}

class AppState: ObservableObject {
    @Published public var list: [AnyUseful] = []
}

struct AppView: View {
    public static var st = AppState()
    @ObservedObject private var state = st
    
    @State private var target = Target.RED
    
    @State private var timeStart = "00:00:000"
    @State private var timeEnd = "00:00:000"
    
    private var highest: UInt { state.list.last?.endTime ?? 0 }
    
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
                    for item in state.list {
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
            
            audioPlayer?.stop()
            audioPlayer?.currentTime = 0
            
            for item in state.list {
                item.done()
            }
            
            mainWindow.setIsVisible(true)
            mainWindow.makeKeyAndOrderFront(nil)
        }
    }
    
    func stop() {
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
                    timeStart = deformat(highest)
                    timeEnd = deformat(highest)
                }
                
                guard let item = target.getController().submitData?(unwrappedTimeStart, unwrappedTimeEnd) else {
                    return
                }
                
                state.list.append(AnyUseful(body: item))
                
                state.list.sort(by: {
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
                    ForEach(state.list, id: \.id) {item in
                        TimecodeView(item, {
                            state.list.sort(by: {
                                return $0.endTime < $1.endTime
                            })
                            
                            timeStart = deformat(highest)
                            timeEnd = deformat(highest)
                        }, {
                            var bool = false
                            if state.list.last?.id == item.id {
                                bool = true
                            }
                            state.list.removeAll(where: {$0.id == item.id})
                            if bool {
                                timeStart = deformat(highest)
                                timeEnd = deformat(highest)
                            }
                        })
                    }
                    
                    LabeledContent {
                        TextField("Format: mm:ss:msms", text: $timeStart).textFieldStyle(.squareBorder).fixedSize()
                    } label: {
                        Text("Time Start: ")
                    }.onChange(of: highest) {
                        timeStart = deformat(highest)
                    }
                    
                    LabeledContent {
                        TextField("Format: mm:ss:msms", text: $timeEnd).textFieldStyle(.squareBorder).fixedSize()
                    } label: {
                        Text("Time End: ")
                    }.onChange(of: highest) {
                        timeEnd = deformat(highest)
                    }
                }
                
                switch target {
                case .RED:
                    AlertForm(target.getController(), lastAlert: state.list.filter({$0.body is AlertHeader}).last?.body as? AlertHeader)
                case .GREEN:
                    DockAlignerForm(target.getController())
                case .TEAL:
                    DesktopImageSetterForm(target.getController())
                case .PURPLE:
                    FileSpammerForm(target.getController())
                }
            }.listStyle(.plain)
            
            
            Text("Made with ❤️ by rdjpower")
        }.padding()
    }
}

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    public var window: NSWindow?
    
    @objc func save(_ sender: Any?) {
        let sp = NSSavePanel()
        sp.title = "Save the App Data"
        sp.message = "Save your app data so you can open it later."
        sp.nameFieldStringValue = "app.json"
        sp.canCreateDirectories = true
        sp.allowedContentTypes = [.json]
        
        let response = sp.runModal()
        
        if response != .OK {
            return
        }
        
        guard let url = sp.url else {
            return
        }
        
        if !url.startAccessingSecurityScopedResource() {
            return
        }
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        do {
            let data = try encoder.encode(AppView.st.list)
            try data.write(to: url)
        } catch {
            NSAlert(error: error).runModal()
        }
        
        url.stopAccessingSecurityScopedResource()
    }
    
    @objc func load(_ sender: Any?) {
        let op = NSOpenPanel()
        op.allowedContentTypes = [.json]
        op.canChooseFiles = true
        op.allowsMultipleSelection = false
        
        let response = op.runModal()
        if response != .OK {
            return
        }
        
        guard let url = op.url else {
            return
        }
        
        if !url.startAccessingSecurityScopedResource() {
            return
        }
        
        let decoder = JSONDecoder()
        
        do {
            let data = try Data(contentsOf: url)
            AppView.st.list = try decoder.decode([AnyUseful].self, from: data)
        } catch {
            NSAlert(error: error).runModal()
        }
        
        url.stopAccessingSecurityScopedResource()
    }
    
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
        let submenu = app.submenu else {
            return
        }
        
        let about = NSMenuItem(title: "About thething", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        
        submenu.addItem(about)
        
        let fileMenu = NSMenuItem(title: "File", action: nil, keyEquivalent: "")
        let subMenu = NSMenu()
        
        fileMenu.submenu = subMenu
        menu.addItem(fileMenu)
        
        subMenu.addItem(NSMenuItem.separator())
        subMenu.addItem(NSMenuItem(title: "Save", action: #selector(save(_:)), keyEquivalent: "s"))
        
        let mi = NSMenuItem(title: "Open...", action: #selector(load(_:)), keyEquivalent: "o")
        mi.image = NSImage(systemSymbolName: "arrow.up.forward.app", accessibilityDescription: nil)
        
        subMenu.addItem(mi)
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

