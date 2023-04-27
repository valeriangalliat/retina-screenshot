import Cocoa

let usage = """
  Usage: retina-screenshot [options] [<file>...]

  Arguments:
    <file>...  Where to save the screen capture, 1 file per screen. If none
               given, saves to default screenshot location.

  Options:
    -h, --help               Show help.
    -c, --clipboard          Force screen capture to go to the clipboard.
    -i, --interactive        Capture screen interactively, by selection or
                             window. The space key will toggle between mouse
                             selection and window selection modes. The escape
                             key will cancel the interactive screenshot.
    -D, --display <display>  Screen capture the specified display. 1 is main, 2
                             secondary, etc.
    -o, --no-shadow          In window capture mode, do not capture the shadow
                             of the window.
    -s, --select-only        Only allow mouse selection mode.
    -t, --format <format>    Image format to create (`png`, `jpg` and `tiff`).
                             [default: png]
    -w, --window-only        Only allow window selection mode.
    -W                       Start interaction in window selection mode.
    -l, --window <id>        Captures the window with given ID.

    -q, --quality <quality>  Set screenshot quality, between `1x`, `2x` (Retina),
                             and `both`. When copying to clipboard and `both` is
                             set, it will use `1x`. [default: both]
    -e, --everything         In noninteractive mode, capture all screens in a
                             single file.
    -f, --dialog             Show file selection dialog.
  """

// swiftlint:disable:next function_body_length cyclomatic_complexity
func parseCliOptions() -> RetinaScreenshotOptions {
  var opts = RetinaScreenshotOptions()
  let args = CommandLine.arguments
  var i = 1

  while i < args.count {
    switch args[i] {
    case "-h", "--help":
      print(usage)
      exit(0)

    case "-D", "--display":
      guard i + 1 < args.count else {
        print("Missing argument for `-D`")
        exit(1)
      }

      opts.display = Int(args[i + 1])

      if opts.display == nil {
        print("Invalid screen number for `-D`")
        exit(1)
      }

      i += 1

    case "-t", "--format":
      guard i + 1 < args.count else {
        print("Missing argument for `-t`")
        exit(1)
      }

      switch args[i + 1] {
      case "png":
        opts.format = .png
      case "jpeg":
        opts.format = .jpeg
      case "tiff":
        opts.format = .tiff
      default:
        print("Invalid format `-t`")
        exit(1)
      }

      i += 1

    case "-l", "--window":
      guard i + 1 < args.count else {
        print("Missing argument for `-l`")
        exit(1)
      }

      opts.windowId = Int(args[i + 1])

      if opts.windowId == nil {
        print("Invalid window ID for `-l`")
        exit(1)
      }

      i += 1

    case "-q", "--quality":
      guard i + 1 < args.count else {
        print("Missing argument for `-q`")
        exit(1)
      }

      switch args[i + 1] {
      case "1x": opts.quality = .nominal
      case "2x": opts.quality = .best
      case "both": opts.quality = .both
      default:
        print("Invalid value for `-q`")
        exit(1)
      }

      i += 1

    case "-c", "--clipboard":
      opts.clipboard = true

    case "-i", "--interactive":
      opts.interactive = true

    case "-e", "--everything":
      opts.captureEverything = true

      // We want to ignore framing since this mode doesn't include any shadow
      // but without ignoring framing, the extra space for the shadows is still
      // included.
      opts.imageOptions.insert(.boundsIgnoreFraming)

    case "-f", "--dialog":
      opts.fileDialog = true

    case "-o", "--no-shadow":
      opts.imageOptions.insert(.boundsIgnoreFraming)

    case "-s", "--select-only":
      opts.interactive = true
      opts.onlyMode = .mouse

    case "-w", "--window-only":
      opts.interactive = true
      opts.onlyMode = .window

    case "-W":
      opts.interactive = true
      opts.startMode = .window

    case let arg where arg.starts(with: "-"):
      print("Unknown option `\(arg)`")
      exit(1)

    default:
      opts.files.append(args[i])
    }

    i += 1
  }

  if opts.interactive && opts.display != nil {
    print("Warning: ignoring `-D` option because running in interactive mode")
  }

  if opts.interactive && opts.windowId != nil {
    print("Warning: ignoring `-l` option because running in interactive mode")
  }

  if opts.clipboard && opts.files.count > 0 {
    print("Warning: ignoring destnation files since `-c` was set")
  }

  return opts
}
