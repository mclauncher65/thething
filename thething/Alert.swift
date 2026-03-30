//
//  Alert.swift
//  thething
//
//  Created by Dev Dashora on 3/30/26.
//
import AppKit
import SwiftUI
import Combine
import UniformTypeIdentifiers

class AlertFormHeader: ObservableObject {
    @Published var alertImg = NSImage(named: NSImage.applicationIconName)!
    @Published var openFilePicker = false
    
    @Published var hasErrorTitle = false
    @Published var redErrorTitle = ""
    
    @Published var hasErrorDetails = false
    @Published var redErrorDetails = ""
    
    @Published var hasCheckbox = false
    @Published var checkboxTitle = ""
    
    @Published var button1Title = "OK"
    
    @Published var hasButton2 = false
    @Published var button2Title = ""
    
    @Published var hasButton3 = false
    @Published var button3Title = ""
    
    @Published var hasHelp = false
    @Published var leftAligned = false

    @Published var hasOffset = false
    @Published var offsetXStr = "5"
    @Published var offsetYStr = "5"
    @Published var offset = CGPoint(x: 0, y: 0)
    
    init() {
        alertImg.size = .init(width: 64, height: 64)
    }
}

struct AlertForm: View {
    private static var holder = AlertFormHeader()
    private let lastAlert: AlertHeader?
    
    @ObservedObject var obj = holder
    
    init(_ data: SharedController, lastAlert: AlertHeader?) {
        self.lastAlert = lastAlert
        
        data.submitData = { [obj] start,end in
            return AlertHeader(
                startTime: start,
                endTime: end,
                withImage: obj.alertImg,
                text: obj.hasErrorTitle ? obj.redErrorTitle : nil,
                info: obj.hasErrorDetails ? obj.redErrorDetails : nil,
                button1: obj.button1Title.isEmpty ? "OK" : obj.button1Title,
                button2: obj.hasButton2 ? obj.button2Title : nil,
                button3: obj.hasButton3 ? obj.button3Title : nil,
                checkBox: obj.hasCheckbox ? obj.checkboxTitle : nil,
                help: obj.hasHelp,
                leftAlign: obj.leftAligned,
                position: obj.hasOffset ? lastAlert != nil ? CGPoint(x: lastAlert!.setPosition.x + obj.offset.x,
                                                                         y: lastAlert!.setPosition.y + obj.offset.y) : nil : nil
            )
        }
    }
    
    var body: some View {
        Section("Alert Info") {
            Image(nsImage: obj.alertImg)
            
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
                        
                        obj.alertImg = NSImage(contentsOf: url)!
                        obj.alertImg.size = .init(width: 64, height: 64)
                        
                        url.stopAccessingSecurityScopedResource()
                    } catch {
                        NSAlert(error: error).runModal()
                    }
                })
            } label: {
                Text("Alert Icon: ")
            }
            
            LabeledContent {
                Toggle(isOn: $obj.hasErrorTitle, label: {
                    Text("Show Alert Title")
                }).toggleStyle(.checkbox)
                if obj.hasErrorTitle {
                    TextField("General info about the alert", text: $obj.redErrorTitle).textFieldStyle(.squareBorder).fixedSize()
                }
            } label: {
                Text("Alert Title: ")
            }
            
            LabeledContent {
                Toggle(isOn: $obj.hasErrorDetails, label: {
                    Text("Show Alert Details")
                }).toggleStyle(.checkbox)
                if obj.hasErrorDetails {
                    TextField("What does the alert do?", text: $obj.redErrorDetails).textFieldStyle(.squareBorder).fixedSize()
                }
            } label: {
                Text("Alert Details: ")
            }
            
            if lastAlert != nil {
                LabeledContent {
                    Toggle(isOn: $obj.hasOffset, label: {
                        Text("Has Offset")
                    }).toggleStyle(.checkbox)
                    if obj.hasOffset {
                        HStack {
                            Text("Offset X: ")
                            
                            TextField("Some Number (x)", text: $obj.offsetXStr).textFieldStyle(.squareBorder).fixedSize()
                                .onChange(of: obj.offsetXStr) { old, new in
                                    if Float(new) == nil {
                                        obj.offsetXStr = old
                                    }
                                    
                                    obj.offset.x = CGFloat(Float(obj.offsetXStr)!)
                                }
                            
                            Text("Offset Y: ")
                            
                            TextField("Some Number (y)", text: $obj.offsetYStr).textFieldStyle(.squareBorder).fixedSize()
                                .onChange(of: obj.offsetYStr) { old, new in
                                    if Float(new) == nil {
                                        obj.offsetYStr = old
                                    }
                                    
                                    obj.offset.y = -CGFloat(Float(obj.offsetYStr)!)
                                }
                        }
                    }
                } label: {
                    Text("Offset from Last Alert: ")
                }
            }
            
            LabeledContent {
                Toggle(isOn: $obj.hasCheckbox, label: {
                    Text("Show Alert Checkbox")
                }).toggleStyle(.checkbox)
                if obj.hasCheckbox {
                    TextField("Checkbox Label", text: $obj.checkboxTitle).textFieldStyle(.squareBorder).fixedSize()
                }
            } label: {
                Text("Alert Checkbox: ")
            }
        }
        
        Section("Buttons") {
            LabeledContent {
                TextField("Button 1 Title", text: $obj.button1Title).textFieldStyle(.squareBorder).fixedSize()
            } label: {
                Text("Button 1: ")
            }
            
            LabeledContent {
                Toggle(isOn: $obj.hasButton2, label: {
                    Text("Show Button 2")
                }).toggleStyle(.checkbox)
                if obj.hasButton2 {
                    TextField("Button 2 Title", text: $obj.button2Title).textFieldStyle(.squareBorder).fixedSize()
                }
            } label: {
                Text("Button 2: ")
            }
            
            LabeledContent {
                Toggle(isOn: $obj.hasButton3, label: {
                    Text("Show Button 3")
                }).toggleStyle(.checkbox)
                if obj.hasButton2 {
                    TextField("Button 3 Title", text: $obj.button3Title).textFieldStyle(.squareBorder).fixedSize()
                }
            } label: {
                Text("Button 3: ")
            }
        }
        
        Section("Miscellaneous") {
            LabeledContent {
                Toggle(isOn: $obj.hasHelp, label: {
                    Text("Has Help Button")
                }).toggleStyle(.checkbox)
            } label: {
                Text("Help Button: ")
            }
            
            LabeledContent {
                Toggle(isOn: $obj.leftAligned, label: {
                    Text("Has Alert Aligned to Left")
                }).toggleStyle(.checkbox)
            } label: {
                Text("Left Align: ")
            }
        }
    }
}

class AlertHeader: Identifiable, Useful {
    let name: String = "Alert"
    
    let id = UUID()
    var setPosition = CGPoint.zero
    
    var window: Alert? = nil
    
    var startTime: UInt
    var endTime: UInt
    let img: NSImage
    let text: String?
    let info: String?
    let button1: String
    let button2: String?
    let button3: String?
    let checkBox: String?
    let help: Bool
    let leftAlign: Bool
    
    func `do`() {
        let w = Alert(self)
        window = w
        w.makeKeyAndOrderFront(nil)
        w.setFrame(NSRect(origin: setPosition, size: w.frame.size), display: true)
    }
    
    func done() {
        window?.close()
        window = nil
    }
    
    init(startTime: UInt, endTime: UInt,
         withImage img: NSImage,
         text: String?=nil,
         info: String?=nil,
         button1: String="OK",
         button2: String?=nil,
         button3: String?=nil,
         checkBox: String?=nil,
         help: Bool=false,
         leftAlign: Bool=false,
         position: CGPoint?
        ) {
        self.startTime = startTime
        self.endTime = endTime
        self.img = img
        self.text = text
        self.info = info
        self.button1 = button1
        self.button2 = button2
        self.button3 = button3
        self.checkBox = checkBox
        self.help = help
        self.leftAlign = leftAlign
        
        if let pos = position {
            self.setPosition = pos
        } else {
            window = Alert(self)
            window?.center()
            window?.toggleSetMode(true)
        }
    }
}

class Alert: NSWindow {
    
    private var setButton: (Bool) -> () = {_ in}
    
    var setPosition = CGPoint.zero
    let alert: AlertHeader?
    
    func toggleSetMode(_ bool: Bool) {
        setButton(bool)
    }
    
    init(_ alert: AlertHeader) {
        self.alert = alert
        super.init(contentRect: NSRect(x: 0, y: 0, width: NSAlert().window.frame.width, height: 0),
                   styleMask: .init(rawValue: 8589967361),
                   backing: .buffered,
                   defer: false)
        
        self.isMovableByWindowBackground = true
        self.animationBehavior = .alertPanel
        
        let stack = NSStackView()
        stack.edgeInsets = .init(top: 20, left: 20, bottom: 20, right: 20)
        stack.orientation = .vertical
        stack.spacing = 19
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.alignment = alert.leftAlign ? .leading : .centerX
        
        if alert.help {
            let helpButton = NSButton()
            if #available(macOS 26.0, *) {
                helpButton.borderShape = .circle
            } else {
                helpButton.bezelStyle = .circular
            }
            helpButton.translatesAutoresizingMaskIntoConstraints = false
            helpButton.image = NSImage(systemSymbolName: "questionmark", accessibilityDescription: nil)
            
            stack.addSubview(helpButton)
            
            NSLayoutConstraint.activate([
                helpButton.widthAnchor.constraint(equalToConstant: 28),
                helpButton.heightAnchor.constraint(equalToConstant: 28),
                helpButton.topAnchor.constraint(equalTo: stack.topAnchor, constant: 12),
                helpButton.trailingAnchor.constraint(equalTo: stack.trailingAnchor, constant: -12)
            ])
        }
        
        let imageView = NSImageView(image: alert.img)
        alert.img.size = NSSize(width: 64, height: 64)
        imageView.frame.size = alert.img.size
        
        stack.addArrangedSubview(imageView)
        
        let createText = { (s: String, f: NSFont) -> NSTextField in
            let nsp = NSMutableParagraphStyle()
            nsp.hyphenationFactor = 1
            nsp.lineSpacing = 3
            nsp.alignment = alert.leftAlign ? .natural : .center
            
            let field = NSTextField(labelWithAttributedString: NSAttributedString(string: s, attributes: [NSAttributedString.Key.paragraphStyle : nsp]))
            field.font = f
            field.translatesAutoresizingMaskIntoConstraints = false
            
            stack.addArrangedSubview(field)
            field.leadingAnchor.constraint(equalTo: stack.layoutMarginsGuide.leadingAnchor).isActive = true
            field.trailingAnchor.constraint(equalTo: stack.layoutMarginsGuide.trailingAnchor).isActive = true
            return field
        }
        
        if let t = alert.text {
            let v = createText(t, .boldSystemFont(ofSize: 13))
            stack.setCustomSpacing(12, after: v)
        }
        
        if let i = alert.info {
            let v = createText(i, .systemFont(ofSize: 13))
            stack.setCustomSpacing(19, after: v)
        }
        
        if let checkBoxTitle = alert.checkBox {
            let chk = NSButton(checkboxWithTitle: checkBoxTitle, target: nil, action: nil)
            stack.addArrangedSubview(chk)
        }
        
        let bttnStack = NSStackView()
        bttnStack.orientation = .horizontal
        bttnStack.spacing = 8
        bttnStack.distribution = .fillEqually
        bttnStack.translatesAutoresizingMaskIntoConstraints = false
        bttnStack.setContentHuggingPriority(.init(1), for: .horizontal)
        stack.addArrangedSubview(bttnStack)
        
        let createButton = {(text: String, customColor: NSColor?) -> NSButton in
            let bttn = NSButton()
            bttn.bezelColor = customColor
            bttn.setButtonType(.momentaryPushIn)
            bttn.title = text
            bttn.translatesAutoresizingMaskIntoConstraints = false
            bttn.setContentHuggingPriority(.init(1), for: .horizontal)
            bttn.wantsLayer = true
            bttn.layer?.cornerRadius = 12
            
            return bttn
        }
        
        if let bttn2 = alert.button2 {
            let secondary = createButton(bttn2, nil)
            bttnStack.addView(secondary, in: .trailing)
        }
        
        let primitive = createButton(alert.button1, .controlAccentColor)
        bttnStack.addView(primitive, in: .trailing)
        
        self.setButton = { bool in
            if bool {
                primitive.title = "Set Position"
                primitive.bezelColor = .systemRed
            } else {
                primitive.title = alert.button1
                primitive.bezelColor = .controlAccentColor
            }
            primitive.target = self
            primitive.action = #selector(self.setModeFinish(_:))
        }
        
        if let bttn3 = alert.button3 {
            let tertiary = createButton(bttn3, nil)
            bttnStack.orientation = .vertical
            bttnStack.removeView(primitive)
            bttnStack.addView(primitive, in: .leading)
            
            bttnStack.addView(tertiary, in: .trailing)
        }
        
        self.contentView = stack
        
        self.makeKeyAndOrderFront(nil)
        self.titleVisibility = .hidden
        self.titlebarAppearsTransparent = true
    }
    
    @IBAction func setModeFinish(_: NSButton) {
        alert?.setPosition = frame.origin
        close()
    }
    
    required init(coder: NSCoder) {alert = nil; super.init(contentRect: .zero, styleMask: [], backing: .buffered, defer: false)}
}
