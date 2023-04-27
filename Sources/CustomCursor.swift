import Cocoa

class CustomCursor {
  static var crosshair: NSCursor = {
    CustomCursor.loadCursor("crosshair", NSPoint(x: 15, y: 15))
      ?? .crosshair
  }()

  static var camera: NSCursor = {
    CustomCursor.loadCursor("camera", NSPoint(x: 14, y: 11)) ?? .pointingHand
  }()

  static func loadCursor(_ name: String, _ hotSpot: NSPoint) -> NSCursor? {
    let url = Bundle.module.url(forResource: "Cursors/\(name)", withExtension: "png")!

    guard
      let image = NSImage(contentsOf: url)
    else {
      return nil
    }

    return NSCursor(image: image, hotSpot: hotSpot)
  }
}
