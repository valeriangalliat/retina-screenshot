import Cocoa

// Takes a `NSRect` where the origin is relative to the top-left of the main
// screen, e.g. as in `kCGWindowBounds`, and converts it to be relative
// to the bottom-left of the main screen, e.g. as in `NSEvent.mouseLocation`.
func topLeftToBottomLeft(_ rect: NSRect) -> NSRect {
  // We use `NSScreen.screens[0]` and not `NSScreen.main` to get the "main"
  // screen, because we want the main screen as in the screen whose position is
  // `(0, 0)` but `NSScreen.main` is the currently focused screen!
  let mainScreenHeight = NSScreen.screens[0].frame.height

  return NSRect(
    x: rect.origin.x,
    y: mainScreenHeight - rect.origin.y - rect.height,
    width: rect.width,
    height: rect.height
  )
}

func handleError(_ error: Error) {
  if let error = error as NSError?, error.userInfo[error.domain] != nil {
    let message = error.userInfo[error.domain]!
    print("Error writing image2:", message)
    exit(1)
  } else {
    print("Error writing image:", error.localizedDescription)
    exit(1)
  }
}
