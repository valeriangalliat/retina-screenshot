import Cocoa

// See <https://stackoverflow.com/questions/46023769/how-to-show-a-window-without-stealing-focus-on-macos>.
class ScreenOverlayWindow: NSPanel {
  static var instances: [ScreenOverlayWindow] = []

  var saver: ScreenshotSaver
  var windowView: WindowSelectionView?
  var mouseView: MouseSelectionView?

  static func openOnAllScreens(_ opts: RetinaScreenshotOptions) {
    for screen in NSScreen.screens {
      let overlay = ScreenOverlayWindow(screen, opts)

      // We need to call this to force the window on its designated screen,
      // otherwise it gets put on the active screen.
      overlay.setFrame(screen.frame, display: true)

      // Put the overlay on top of everything otherwise it doesn't intercept
      // the mouse events. It doesn't seem we need to call `makeKeyAndOrderFront`,
      // just `orderFront` suffice.
      overlay.orderFront(nil)

      Self.instances.append(overlay)
    }
  }

  static func closeAll() {
    for instance in Self.instances {
      instance.close()
    }
  }

  // Need to override those because we're in borderless mode.
  // See <https://developer.apple.com/documentation/appkit/nswindow/stylemask/1644698-borderless>.
  override var canBecomeKey: Bool { true }
  override var canBecomeMain: Bool { true }

  var opts: RetinaScreenshotOptions

  init(_ screen: NSScreen, _ opts: RetinaScreenshotOptions) {
    self.opts = opts
    self.saver = ScreenshotSaver(opts)

    super.init(
      contentRect: screen.frame,
      // We need `nonactivatingPanel` to keep the app behind focused (e.g.
      // colored window buttons).
      //
      // The downside is this closes the context menus when we call
      // `orderFront`, while when using `NSWindow` with `styleMask: []`,
      // the context menus are preserved (however our screenshot selection UI
      // is still buggy with those menus but they do appear).)
      styleMask: [.nonactivatingPanel],
      backing: .buffered,
      defer: false
    )

    self.isOpaque = false
    self.backgroundColor = .clear

    // Needed in order to intercept mouse events
    self.ignoresMouseEvents = false
    self.acceptsMouseMovedEvents = true

    // So we show above the menu bar and context menus
    self.level = .screenSaver

    switch opts.startMode {
    case .screen: self.screenMode()
    case .window: self.windowMode()
    case .mouse: self.mouseMode()
    }
  }

  override func close() {
    self.windowView?.selectionWindow?.close()
    super.close()
  }

  var cursorHackcounter = 100

  override func mouseMoved(with event: NSEvent) {
    // When moving across screens, make sure we're the key window so we can
    // intercept clicks.
    if !self.isKeyWindow {
      self.makeKey()
      self.cursorHackcounter = 0
    }

    // Hack because custom cursor gets lost when moving between screens.
    //
    // The cursor rects are set properly but macOS doesn't pick it up for
    // a `nonactivatingPanel` after moving between screens.
    //
    // Same problem when using `NSTrackingArea`.`
    //
    // Also if we invalidate right when we `makeKey()`, it doesn't work.
    // We need to invalidate slightly after, hence the counter. A value of 4
    // seems to work systematically on my side but I used 10 to be safe.
    //
    // I'm thinking it may be related to <https://github.com/PitNikola/NonActivatingPanelIssue/tree/master>
    // although I'm not sure it's the same issue.
    //
    // If you know a better way around this, please tell me!
    if self.cursorHackcounter < 10 {
      self.invalidateCursorRects(for: self.contentView!)
      self.cursorHackcounter += 1
    }
  }

  func screenMode() {
    // TODO
  }

  func activate(_ view: NSView) {
    self.contentView = view

    // Needed for the view to intercept key events.
    self.makeFirstResponder(self.contentView)
  }

  func windowMode() {
    if self.windowView == nil {
      self.windowView = WindowSelectionView()
      self.windowView!.selectionWindow = WindowSelectionWindow(self.screen!)
      self.windowView!.selectionWindow!.setFrame(self.screen!.frame, display: true)
      self.windowView!.saver = self.saver
    }

    self.activate(self.windowView!)
  }

  func mouseMode() {
    if self.mouseView == nil {
      self.mouseView = MouseSelectionView()
      self.mouseView!.saver = self.saver
    }

    self.activate(self.mouseView!)
  }

  override func keyDown(with event: NSEvent) {
    if event.characters == " " {
      if self.contentView is WindowSelectionView {
        for instance in Self.instances {
          instance.mouseMode()
        }
      } else {
        for instance in Self.instances {
          instance.windowMode()
        }
      }
    }
  }
}
