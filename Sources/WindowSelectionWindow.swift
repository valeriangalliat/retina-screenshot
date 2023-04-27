import Cocoa

class WindowSelectionWindowView: NSView {
  var selectionRect = NSRect.zero {
    didSet {
      self.needsDisplay = true
    }
  }

  override func draw(_ dirtyRect: NSRect) {
    super.draw(dirtyRect)
    NSColor.selectedTextBackgroundColor.withAlphaComponent(0.5).setFill()
    NSBezierPath(rect: self.selectionRect).fill()
  }
}

class WindowSelectionWindow: NSWindow {
  var selectionView: WindowSelectionWindowView

  init(_ screen: NSScreen) {
    self.selectionView = WindowSelectionWindowView(
      frame: NSRect(x: 0, y: 0, width: screen.frame.width, height: screen.frame.height)
    )

    super.init(
      contentRect: screen.frame,
      styleMask: [],
      backing: .buffered,
      defer: false
    )

    self.isOpaque = false
    self.backgroundColor = .clear

    self.contentView!.addSubview(self.selectionView)
  }
}
