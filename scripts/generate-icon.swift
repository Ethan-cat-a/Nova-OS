import AppKit
import Foundation

let backgroundURL = URL(fileURLWithPath: CommandLine.arguments[1])
let outputURL = URL(fileURLWithPath: CommandLine.arguments[2])
let canvasSize = 1024
let canvas = NSImage(size: NSSize(width: canvasSize, height: canvasSize))
canvas.lockFocus()

let bounds = NSRect(x: 0, y: 0, width: canvasSize, height: canvasSize)
guard let background = NSImage(contentsOf: backgroundURL) else {
    fputs("Could not load Nova OS icon background.\n", stderr)
    exit(1)
}
background.draw(in: bounds, from: .zero, operation: .copy, fraction: 1)

let logo = NSImage(systemSymbolName: "apple.logo", accessibilityDescription: "Apple logo")
guard let logo else {
    fputs("The system Apple logo symbol is unavailable on this macOS version.\n", stderr)
    exit(1)
}
let symbolConfiguration = NSImage.SymbolConfiguration(pointSize: 408, weight: .regular)
    .applying(NSImage.SymbolConfiguration(hierarchicalColor: .white))
let renderedLogo = logo.withSymbolConfiguration(symbolConfiguration) ?? logo
let glow = NSShadow()
glow.shadowColor = NSColor(calibratedRed: 0.40, green: 0.68, blue: 1, alpha: 0.82)
glow.shadowBlurRadius = 34
glow.shadowOffset = .zero
glow.set()
renderedLogo.draw(
    in: NSRect(x: 294, y: 292, width: 436, height: 438),
    from: .zero,
    operation: .sourceOver,
    fraction: 1
)
NSShadow().set()

canvas.unlockFocus()
guard let tiff = canvas.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiff),
      let png = bitmap.representation(using: .png, properties: [:]) else {
    fputs("Could not render Nova OS icon.\n", stderr)
    exit(1)
}
try png.write(to: outputURL, options: .atomic)
