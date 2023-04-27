import Cocoa

class RetinaScreenshotAppDelegate: NSObject, NSApplicationDelegate {
  var opts: RetinaScreenshotOptions

  init(_ opts: RetinaScreenshotOptions) {
    self.opts = opts
  }

  func applicationWillFinishLaunching(_ notification: Notification) {
    // Activation policy defaults to `.prohibited` which prevents putting the
    // window in the front despite `activate(ignoringOtherApps: true)` and
    // `makeKeyAndOrderFront(nil)`.
    //
    // The issue with that is that it will kill any open context menus when
    // we open the app. Also it defocuses the other apps so we can't screenshot
    // the "active" state...
    //
    // Doesn't seem necessary when using a `NSPanel` for the overlay.
    // app.setActivationPolicy(.regular)
    // app.setActivationPolicy(.accessory)
  }

  func applicationDidFinishLaunching(_ notification: Notification) {
    ScreenOverlayWindow.openOnAllScreens(self.opts)

    // Activate the app, otherwise it's not intercepting clicks until manually
    // focused by the user.
    //
    // Doesn't seem necessary when using a `NSPanel` for the overlay.
    // app.activate(ignoringOtherApps: true)
  }
}
