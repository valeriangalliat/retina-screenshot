import Cocoa

enum SelectionMode {
  case screen
  case window
  case mouse
}

enum ScreenshotQuality {
  case nominal
  case best
  case both
}

enum FileNamePattern: String {
  case at = "@2x"
  case underscore = "_2x"
}

enum FileFormat: String {
  case png
  case jpeg
  case tiff
}

struct RetinaScreenshotOptions {
  var clipboard = false
  var interactive = false
  var display: Int?
  var imageOptions: CGWindowImageOption = []
  var onlyMode: SelectionMode?
  var startMode: SelectionMode = .mouse
  var format: FileFormat = .png
  var windowId: Int?
  var fileDialog = false
  var quality: ScreenshotQuality = .both
  var captureEverything = false
  var files: [String] = []
}

class RetinaScreenshot {
  var opts: RetinaScreenshotOptions

  init(_ opts: RetinaScreenshotOptions) {
    self.opts = opts
  }

  func run() {
    if self.opts.interactive {
      return self.runInteractive()
    }

    self.runHeadless()
  }

  func runHeadless() {
    let saver = ScreenshotSaver(self.opts)

    if let windowId = self.opts.windowId {
      saver.window(windowId)
    } else if let display = self.opts.display {
      saver.screen(display)
    } else if self.opts.captureEverything {
      saver.everything()
    } else {
      // If no files specified, capture all screens, otherwise capture as many
      // screens as there are files.
      let max =
        self.opts.files.count > 0
        ? min(self.opts.files.count, NSScreen.screens.count)
        : NSScreen.screens.count

      for i in 0..<max {
        saver.screen(i)
      }
    }

    saver.save()
  }

  func runInteractive() {
    let app = NSApplication.shared

    let delegate = RetinaScreenshotAppDelegate(self.opts)

    app.delegate = delegate
    app.run()
  }
}
