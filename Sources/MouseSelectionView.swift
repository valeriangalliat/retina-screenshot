import Cocoa

class MouseSelectionView: NSView {
  var saver: ScreenshotSaver?
  var startingPoint: NSPoint?
  var spacePoint: NSPoint?
  var currentRect: NSRect?

  override func resetCursorRects() {
    self.addCursorRect(self.bounds, cursor: CustomCursor.crosshair)
  }

  override func keyDown(with event: NSEvent) {
    if self.startingPoint != nil && event.characters == " " {
      self.spacePoint = event.locationInWindow
    } else {
      // Propagate to parent window
      super.keyDown(with: event)
    }
  }

  override func keyUp(with event: NSEvent) {
    self.spacePoint = nil
  }

  override func mouseDown(with event: NSEvent) {
    self.startingPoint = event.locationInWindow
  }

  func updateSelection(_ event: NSEvent) {
    let currentPoint = event.locationInWindow

    guard let startingPoint = self.startingPoint else {
      return
    }

    if let spacePoint = self.spacePoint, let currentRect = self.currentRect {
      // Move the box
      let deltaX = currentPoint.x - spacePoint.x
      let deltaY = currentPoint.y - spacePoint.y

      self.startingPoint = NSPoint(
        x: startingPoint.x + deltaX,
        y: startingPoint.y + deltaY
      )

      self.spacePoint = NSPoint(
        x: spacePoint.x + deltaX,
        y: spacePoint.y + deltaY
      )

      self.currentRect = NSRect(
        x: currentRect.origin.x + deltaX,
        y: currentRect.origin.y + deltaY,
        width: currentRect.width,
        height: currentRect.height
      )
    } else {
      // Resize the box
      self.currentRect = NSRect(
        x: min(startingPoint.x, currentPoint.x),
        y: min(startingPoint.y, currentPoint.y),
        width: abs(startingPoint.x - currentPoint.x),
        height: abs(startingPoint.y - currentPoint.y)
      )
    }

    self.needsDisplay = true
  }

  override func mouseDragged(with event: NSEvent) {
    self.updateSelection(event)
  }

  override func draw(_ dirtyRect: NSRect) {
    super.draw(dirtyRect)

    guard let currentRect = self.currentRect else {
      return
    }

    NSColor.white.setStroke()
    NSColor.gray.withAlphaComponent(0.25).setFill()

    let path = NSBezierPath(rect: currentRect)

    path.lineWidth = 1

    path.stroke()
    path.fill()
  }

  override func mouseUp(with event: NSEvent) {
    self.updateSelection(event)

    if let rect = self.currentRect, let saver = self.saver {
      ScreenOverlayWindow.closeAll()

      // Run asnyc to let the UI update instantaneously
      DispatchQueue.main.async {
        saver.area(rect).save()
      }
    }

    self.startingPoint = nil
    self.currentRect = nil
    self.needsDisplay = true
  }
}
