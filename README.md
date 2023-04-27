# Retina Screenshot

> CLI screenshot tool for macOS with Retina support.

![Demo](../../raw/assets/demo.png)

## Overview

The goal of this tool is to be near-compatible with macOS
[`screencapture(1)`](https://ss64.com/osx/screencapture.html) command,
with some extra additions, like the possibility to capture both 1x and
2x versions of the screenshot on Retina screens.

This is useful, say, if you want two _native_ captures of the same
window, both at a regular resolution and at a Retina resolution. This
way you can get the best rendering in both cases, without any
artificial downscaling.

You can also get only the 1x resolution e.g. for embedding on many sites
that don't support 2x images, to avoid your screenshots looking 4 times
bigger than they should be.

## Installation

```sh
git clone https://github.com/valeriangalliat/retina-screenshot.git
cd retina-screenshot
swift build
mv .build/debug/retina-screenshot .
./retina-screenshot --help
```

## Usage

### Capture every screen and save it in the default location

```sh
retina-screenshot
```

If you have two screens, this will save, e.g.:

```
~/Desktop/Screenshot YYYY-MM-DD at hh.mm.ss.png
~/Desktop/Screenshot YYYY-MM-DD at hh.mm.ss@2x.png
~/Desktop/Screenshot YYYY-MM-DD at hh.mm.ss (2).png
~/Desktop/Screenshot YYYY-MM-DD at hh.mm.ss (2)@2x.png
```

It will respect the default screenshot location you have set in macOS
screenshot utility. You can see it by running:

```sh
defaults read com.apple.screencapture location
```

Or by pressing <kbd>Command</kbd> + <kbd>Shift</kbd> + <kbd>5</kbd>
and looking at the **Options > Save to** value.

### Capture every screen, specify filename

```sh
retina-screenshot screen1.png screen2.png
```

You will get:

```
screen1.png
screen1@2x.png
screen2.png
screen2@2x.png
```

If you have two screens and you only specify a single filename, it will
only capture the main screen.

### Chose quality (1x, 2x or both)

```sh
retina-screenshot -q 1x
retina-screenshot --quality 1x
retina-screenshot --quality 2x
retina-screenshot --quality both
```

Defaults to both.

### Interactive capture

```sh
retina-screenshot -i
retina-screenshot --interactive
```

This will show an interactive UI that mimics the default macOS
screenshot tool, where you can cycle between mouse, window and screen
selection mode with the space bar.

The filename behavior will be the same as noninteractive mode.

### Save dialog

```sh
retina-screenshot --f
retina-screenshot --dialog
```

Instead of automatically generating the filename, or taking it from the
CLI arguments, you will get an interactive dialog to select where to
save the file(s).

![Dialog example](../../raw/assets/dialog.png)

### Capture specific display

### No shadow

In window selection mode, do not capture the shadow.

```sh
retina-screenshot -o
retina-screenshot --no-shadow
```

### Specify format (PNG, JPEG, TIFF)

```sh
retina-screenshot -t png
retina-screenshot --format png
retina-screenshot --format jpg
retina-screenshot --format tiff
```

Defaults to PNG.

### Save all screens in a single file

```sh
retina-capture -e
retina-capture --everything
```

The screens will be arranged like configured in displays preferences.
Uncovered areas are transparent.

![Everything example](../../raw/assets/everything.png)

## Development

Basic linting:

```sh
make lint
```

Deeper linting:

```sh
make analyze
```
