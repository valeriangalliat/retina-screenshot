import SwiftUI

struct ScreenshotResult {
  var best: CGImage?
  var nominal: CGImage?
}

struct ResultAndFile {
  var result: ScreenshotResult
  var base: String
  var format: FileFormat
}

class SavePanelState: ObservableObject {
  @Published var pattern: FileNamePattern = .at
  @Published var name = ""
  @Published var format: FileFormat = .png
}

struct SaveAccessoryView: View {
  @EnvironmentObject var state: SavePanelState

  var body: some View {
    Form {
      HStack {
        TextField("Name", text: self.$state.name).frame(width: 256)

        Picker("File name pattern", selection: self.$state.pattern) {
          Text(FileNamePattern.at.rawValue).tag(FileNamePattern.at)
          Text(FileNamePattern.underscore.rawValue).tag(FileNamePattern.underscore)
        }
        .pickerStyle(.segmented)
        .labelsHidden()
      }

      Text("\(self.state.name).\(self.state.format.rawValue)")
      Text("\(self.state.name)\(self.state.pattern.rawValue).\(self.state.format.rawValue)")

      Picker("Format", selection: self.$state.format) {
        Text(FileFormat.png.rawValue.uppercased()).tag(FileFormat.png)
        Text(FileFormat.jpeg.rawValue.uppercased()).tag(FileFormat.jpeg)
        Text(FileFormat.tiff.rawValue.uppercased()).tag(FileFormat.tiff)
      }
      .fixedSize()
    }
    .fixedSize()
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    .padding()
  }
}

typealias ScreenshotSaverCallback = (_ path: String, _ format: FileFormat) -> Void

class ScreenshotSaverDelegate: NSObject, NSApplicationDelegate {
  var opts: RetinaScreenshotOptions
  var defaultLocation: String
  var defaultName: String
  var callback: ScreenshotSaverCallback

  static func run(
    _ opts: RetinaScreenshotOptions, _ location: String, _ name: String,
    _ callback: @escaping ScreenshotSaverCallback
  ) {
    // We need this to show the panel in the foreground
    let app = NSApplication.shared
    let delegate = ScreenshotSaverDelegate(opts, location, name, callback)

    if !app.isRunning {
      app.delegate = delegate
      app.run()
    } else {
      delegate.launch()
    }
  }

  init(
    _ opts: RetinaScreenshotOptions, _ location: String, _ name: String,
    _ callback: @escaping ScreenshotSaverCallback
  ) {
    self.opts = opts
    self.defaultLocation = location
    self.defaultName = name
    self.callback = callback
  }

  func setupMenu() -> NSMenu {
    let mainMenu = NSMenu()

    let appMenu = NSMenuItem()
    mainMenu.addItem(appMenu)

    let editMenu = NSMenuItem()
    mainMenu.addItem(editMenu)

    let editSubmenu = NSMenu(title: "Edit")
    editMenu.submenu = editSubmenu

    // We need to do this manually in order for text keyboard shortcuts to work
    // in the `NSOpenPanel` text fields...
    editSubmenu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
    editSubmenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
    editSubmenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
    editSubmenu.addItem(
      withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")

    return mainMenu
  }

  func launch() {
    let app = NSApplication.shared

    // Needed for the `NSOpenPanel` to show up
    app.setActivationPolicy(.regular)
    app.activate(ignoringOtherApps: true)

    app.mainMenu = self.setupMenu()

    let savePanel = NSOpenPanel()
    let state = SavePanelState()

    state.name = self.defaultName
    state.format = self.opts.format

    savePanel.directoryURL = URL(filePath: self.defaultLocation)
    savePanel.canCreateDirectories = true
    savePanel.canChooseDirectories = true
    savePanel.prompt = "Save"
    savePanel.accessoryView = NSHostingView(rootView: SaveAccessoryView().environmentObject(state))
    savePanel.isAccessoryViewDisclosed = true

    // Needed to have the menu accessible while the panel is open, `runModal`
    // wouldn't work.
    savePanel.begin {
      if $0 == .OK {
        guard let url = savePanel.url else {
          exit(1)
        }

        let path = url.appendingPathComponent("\(state.name).\(state.format.rawValue)")
          .path(percentEncoded: false)

        self.callback(path, state.format)
      } else {
        exit(1)
      }
    }
  }

  func applicationDidFinishLaunching(_ notification: Notification) {
    self.launch()
  }
}

class ScreenshotSaver {
  var opts: RetinaScreenshotOptions
  var results: [ScreenshotResult] = []

  init(_ opts: RetinaScreenshotOptions) {
    self.opts = opts
  }

  func writeFile(_ cgImage: CGImage, to: URL) throws {
    let context = CIContext()
    let image = CIImage(cgImage: cgImage)

    switch self.opts.format {
    case .png:
      try context.writePNGRepresentation(
        of: image,
        to: to,
        format: .RGBA8,
        colorSpace: image.colorSpace!
      )
    case .jpeg:
      try context.writeJPEGRepresentation(
        of: image,
        to: to,
        colorSpace: image.colorSpace!
      )
    case .tiff:
      try context.writeTIFFRepresentation(
        of: image,
        to: to,
        format: .RGBA8,
        colorSpace: image.colorSpace!
      )
    }
  }

  func getDefaultLocation() -> String {
    return NSString(
      string:
        UserDefaults(suiteName: "com.apple.screencapture")?.string(forKey: "location")
        ?? "~/Desktop"
    ).expandingTildeInPath
  }

  func getDefaultName() -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd 'at' HH.mm.ss"
    let dateString = dateFormatter.string(from: Date())
    return "Screenshot \(dateString)"
  }

  func saveGeneric(_ results: [ResultAndFile]) throws {
    for item in results {
      let result = item.result
      let base = item.base
      let ext = item.format

      if let best = result.best, let nominal = result.nominal {
        try self.writeFile(best, to: URL(fileURLWithPath: "\(base)@2x.\(ext)"))
        print("Wrote \(base)@2x.\(ext)")
        try self.writeFile(nominal, to: URL(fileURLWithPath: "\(base).\(ext)"))
        print("Wrote \(base).\(ext)")
      } else if let best = result.best {
        try self.writeFile(best, to: URL(fileURLWithPath: "\(base).\(ext)"))
        print("Wrote \(base).\(ext)")
      } else if let nominal = result.nominal {
        try self.writeFile(nominal, to: URL(fileURLWithPath: "\(base).\(ext)"))
        print("Wrote \(base).\(ext)")
      }
    }

    exit(0)
  }

  func saveToFile(_ base: String, _ format: FileFormat? = nil) throws {
    var results: [ResultAndFile] = []

    for (i, result) in self.results.enumerated() {
      var name = base

      if i > 0 {
        name = "\(name) (\(i + 1))"
      }

      results.append(ResultAndFile(result: result, base: name, format: format ?? self.opts.format))
    }

    try self.saveGeneric(results)
  }

  func saveToFiles(_ files: [String]) throws {
    var results: [ResultAndFile] = []

    for i in 0..<min(files.count, self.results.count) {
      let file = files[i]
      var base = file
      var format = self.opts.format

      if file.hasSuffix(".png") {
        base = String(file.dropLast(4))
        format = .png
      } else if file.hasSuffix(".jpg") {
        base = String(file.dropLast(4))
        format = .jpeg
      } else if file.hasSuffix(".jpeg") {
        base = String(file.dropLast(5))
        format = .jpeg
      } else if file.hasSuffix(".tiff") {
        base = String(file.dropLast(5))
        format = .tiff
      }

      results.append(ResultAndFile(result: self.results[i], base: base, format: format))
    }

    try self.saveGeneric(results)
  }

  func saveHeadless() throws {
    if self.opts.files.count > 0 {
      try self.saveToFiles(self.opts.files)
    } else {
      let path = self.getDefaultLocation() + "/" + self.getDefaultName()
      try self.saveToFile(path)
    }
  }

  func saveDialog() {
    ScreenshotSaverDelegate.run(self.opts, self.getDefaultLocation(), self.getDefaultName()) {
      do {
        try self.saveToFile($0, $1)
      } catch let error {
        handleError(error)
      }
    }
  }

  func saveResults() throws {
    if self.opts.fileDialog {
      self.saveDialog()
    } else {
      try self.saveHeadless()
    }
  }

  func doubleScreenshot(
    _ closure: (CGWindowImageOption) -> Result<CGImage, Error>
  ) -> Result<ScreenshotResult, Error> {
    var result = ScreenshotResult()

    do {
      if self.opts.quality == .both || self.opts.quality == .best {
        result.best = try closure(self.opts.imageOptions.union([.bestResolution])).get()
      }

      if self.opts.quality == .both || self.opts.quality == .nominal {
        result.nominal = try closure(self.opts.imageOptions.union([.nominalResolution])).get()
      }

      return .success(result)
    } catch let error {
      return .failure(error)
    }
  }

  @discardableResult
  func append(
    _ closure: (CGWindowImageOption) -> Result<CGImage, Error>
  ) -> Self {
    do {
      self.results.append(try self.doubleScreenshot(closure).get())
    } catch let error {
      handleError(error)
    }

    return self
  }

  @discardableResult
  func screen(_ number: Int) -> Self {
    return self.append { opts in Screenshot.screen(number, opts) }
  }

  @discardableResult
  func window(_ number: Int) -> Self {
    return self.append { opts in Screenshot.window(number, opts) }
  }

  @discardableResult
  func area(_ rect: CGRect) -> Self {
    return self.append { opts in Screenshot.area(rect, opts) }
  }

  @discardableResult
  func everything() -> Self {
    return self.append { opts in Screenshot.everything(opts) }
  }

  func save() {
    do {
      try self.saveResults()
    } catch let error {
      handleError(error)
    }
  }
}
