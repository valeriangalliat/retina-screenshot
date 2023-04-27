import Cocoa

struct ScreenshotError: LocalizedError {
  var errorDescription: String? {
    "Failed to capture screenshot: CGWindowListCreateImage() returned nil"
  }
}

class Screenshot {
  static func raw(
    _ rect: CGRect,
    _ listOptions: CGWindowListOption,
    _ window: CGWindowID,
    _ imageOptions: CGWindowImageOption
  ) -> Result<CGImage, Error> {
    if let image = CGWindowListCreateImage(rect, listOptions, window, imageOptions) {
      return .success(image)
    }

    return .failure(ScreenshotError())
  }

  static func screen(_ number: Int, _ options: CGWindowImageOption) -> Result<CGImage, Error> {
    return Self.raw(
      topLeftToBottomLeft(NSScreen.screens[number].frame),
      .optionAll,
      kCGNullWindowID,
      options
    )
  }

  static func window(_ number: Int, _ options: CGWindowImageOption) -> Result<CGImage, Error> {
    return Self.raw(
      .null,
      .optionIncludingWindow,
      CGWindowID(number),
      options
    )
  }

  static func area(_ rect: CGRect, _ options: CGWindowImageOption) -> Result<CGImage, Error> {
    return Self.raw(
      rect,
      .optionAll,
      kCGNullWindowID,
      options
    )
  }

  static func everything(_ options: CGWindowImageOption) -> Result<CGImage, Error> {
    return Self.raw(
      .null,
      .optionAll,
      kCGNullWindowID,
      options
    )
  }
}
