#!/usr/bin/env swift
// Generates Resources/AppIcon.icns: a rounded square with a grid, part of it highlighted.
// Usage: swift scripts/make-icon.swift   (run from the repository root)
import AppKit

func render(pixels: Int) -> Data {
    let size = CGFloat(pixels)
    let image = NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
        // macOS icons leave a margin around the artwork.
        let tile = rect.insetBy(dx: size * 0.098, dy: size * 0.098)
        let tilePath = NSBezierPath(roundedRect: tile, xRadius: size * 0.18, yRadius: size * 0.18)
        NSGradient(
            colors: [NSColor(red: 0.20, green: 0.24, blue: 0.34, alpha: 1), NSColor(red: 0.08, green: 0.10, blue: 0.16, alpha: 1)]
        )?.draw(in: tilePath, angle: -90)

        let cells = 3
        let gap = tile.width * 0.045
        let pad = tile.width * 0.14
        let cell = (tile.width - 2 * pad - CGFloat(cells - 1) * gap) / CGFloat(cells)
        for row in 0..<cells {
            for column in 0..<cells {
                let origin = NSPoint(
                    x: tile.minX + pad + CGFloat(column) * (cell + gap),
                    y: tile.minY + pad + CGFloat(row) * (cell + gap))
                let path = NSBezierPath(
                    roundedRect: NSRect(origin: origin, size: NSSize(width: cell, height: cell)),
                    xRadius: cell * 0.2, yRadius: cell * 0.2)
                // Highlight the top-left 2x2 block, like a dragged selection.
                let selected = column < 2 && row >= 1
                (selected ? NSColor.systemBlue : NSColor.white.withAlphaComponent(0.16)).setFill()
                path.fill()
            }
        }
        return true
    }
    let rep = NSBitmapImageRep(data: image.tiffRepresentation!)!
    return rep.representation(using: .png, properties: [:])!
}

let fileManager = FileManager.default
let iconset = fileManager.temporaryDirectory.appendingPathComponent("AppIcon.iconset")
try? fileManager.removeItem(at: iconset)
try fileManager.createDirectory(at: iconset, withIntermediateDirectories: true)

for base in [16, 32, 128, 256, 512] {
    try render(pixels: base).write(to: iconset.appendingPathComponent("icon_\(base)x\(base).png"))
    try render(pixels: base * 2).write(to: iconset.appendingPathComponent("icon_\(base)x\(base)@2x.png"))
}

let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
process.arguments = ["-c", "icns", iconset.path, "-o", "Resources/AppIcon.icns"]
try process.run()
process.waitUntilExit()
try? fileManager.removeItem(at: iconset)
print(process.terminationStatus == 0 ? "Wrote Resources/AppIcon.icns" : "iconutil failed")
