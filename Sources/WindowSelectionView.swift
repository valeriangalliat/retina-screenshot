import Cocoa

struct WindowInfo {
  var windowNumber: Int
  var level: Int
  var frame: NSRect
}

class WindowSelectionView: NSView {
  var selectionWindow: WindowSelectionWindow?
  var saver: ScreenshotSaver?

  override func resetCursorRects() {
    self.addCursorRect(self.bounds, cursor: CustomCursor.camera)
  }

  override func viewWillMove(toWindow newWindow: NSWindow?) {
    if newWindow == nil {
      // View was removed, hide the associated window too
      self.selectionWindow?.orderOut(nil)
    }
  }

  override func becomeFirstResponder() -> Bool {
    if super.becomeFirstResponder() {
      self.updateSelection()
      return true
    }

    return false
  }

  func windowUnderMouse() -> WindowInfo? {
    let mouseLocation = NSEvent.mouseLocation
    let options: CGWindowListOption = .optionOnScreenBelowWindow

    guard
      let windowInfoList = CGWindowListCopyWindowInfo(
        options, CGWindowID(self.window!.windowNumber))
        as? [[CFString: Any]]
    else {
      return nil
    }

    for windowInfo in windowInfoList {
      // Actually it's documented as a `CFNumber` but we need it as a `Int`
      // everywhere and it seems compatible.
      guard let windowNumber = windowInfo[kCGWindowNumber] as? Int else {
        continue
      }

      // Ignore our own selection window
      if windowNumber == self.selectionWindow?.windowNumber {
        continue
      }

      // See <https://forums.swift.org/t/how-can-i-cast-any-to-cf-types/17071> for double `as`
      guard let bounds = windowInfo[kCGWindowBounds] as? NSDictionary as CFDictionary? else {
        continue
      }

      // This is relative to the top-left corner of the main screen.
      // See <https://developer.apple.com/documentation/coregraphics/kcgwindowbounds>.
      var topLeftRect = CGRect()
      CGRectMakeWithDictionaryRepresentation(bounds, &topLeftRect)

      // The mouse is relative to the bottom-left corner of the main screen so
      // we need to convert the coordinate space.
      let bottomLeftRect = topLeftToBottomLeft(topLeftRect)

      if bottomLeftRect.contains(mouseLocation) {
        // Again actually a `CFNumber` but we want an `Int`
        guard let level = windowInfo[kCGWindowLayer] as? Int else {
          continue
        }

        return WindowInfo(
          windowNumber: windowNumber,
          level: level,
          frame: bottomLeftRect
        )
      }
    }

    return nil
  }

  func updateSelection() {
    guard let windowInfo = self.windowUnderMouse() else {
      return
    }

    // We draw relative to the bottom-left corner of the view we're drawing
    // on, which fits the whole screen in our case, so we need to substract
    // the screen origin position.
    let drawRect = NSRect(
      x: windowInfo.frame.origin.x - self.window!.screen!.frame.origin.x,
      y: windowInfo.frame.origin.y - self.window!.screen!.frame.origin.y,
      width: windowInfo.frame.width,
      height: windowInfo.frame.height
    )

    self.selectionWindow?.level = NSWindow.Level(windowInfo.level)
    self.selectionWindow?.order(.above, relativeTo: windowInfo.windowNumber)
    self.selectionWindow?.selectionView.selectionRect = drawRect
  }

  override func mouseMoved(with event: NSEvent) {
    super.mouseMoved(with: event)
    self.updateSelection()
  }

  override func mouseUp(with event: NSEvent) {
    if let windowInfo = self.windowUnderMouse(), let saver = self.saver {
      ScreenOverlayWindow.closeAll()

      // Run asnyc to let the UI update instantaneously
      DispatchQueue.main.async {
        saver.window(windowInfo.windowNumber).save()
      }
    }
  }

}
