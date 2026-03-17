#!/usr/bin/env swift
import AppKit

func drawIcon(size: Int) -> NSImage {
    let s = CGFloat(size)
    let image = NSImage(size: NSSize(width: s, height: s))
    image.lockFocus()

    // Full-bleed gradient background (system applies rounded-rect mask)
    let rect = NSRect(x: 0, y: 0, width: s, height: s)
    let gradient = NSGradient(colors: [
        NSColor(red: 0.25, green: 0.55, blue: 1.0, alpha: 1.0),
        NSColor(red: 0.40, green: 0.30, blue: 0.95, alpha: 1.0)
    ])!
    gradient.draw(in: rect, angle: -45)

    // Draw the markdown mark using paths (M with down arrow)
    NSColor.white.setStroke()
    NSColor.white.setFill()

    let margin = s * 0.22
    let lineW = s * 0.065
    let top = s * 0.72
    let bottom = s * 0.28

    // M shape
    let mLeft = margin
    let mRight = margin + s * 0.38
    let mMidX = (mLeft + mRight) / 2
    let mMidY = bottom + (top - bottom) * 0.4

    let mPath = NSBezierPath()
    mPath.lineWidth = lineW
    mPath.lineCapStyle = .round
    mPath.lineJoinStyle = .round
    mPath.move(to: NSPoint(x: mLeft, y: bottom))
    mPath.line(to: NSPoint(x: mLeft, y: top))
    mPath.line(to: NSPoint(x: mMidX, y: mMidY))
    mPath.line(to: NSPoint(x: mRight, y: top))
    mPath.line(to: NSPoint(x: mRight, y: bottom))
    mPath.stroke()

    // Down arrow
    let arrowX = s - margin
    let arrowHeadW = s * 0.09

    let arrowPath = NSBezierPath()
    arrowPath.lineWidth = lineW
    arrowPath.lineCapStyle = .round
    arrowPath.lineJoinStyle = .round
    arrowPath.move(to: NSPoint(x: arrowX, y: top))
    arrowPath.line(to: NSPoint(x: arrowX, y: bottom))
    arrowPath.move(to: NSPoint(x: arrowX - arrowHeadW, y: bottom + arrowHeadW * 1.4))
    arrowPath.line(to: NSPoint(x: arrowX, y: bottom))
    arrowPath.line(to: NSPoint(x: arrowX + arrowHeadW, y: bottom + arrowHeadW * 1.4))
    arrowPath.stroke()

    image.unlockFocus()
    return image
}

let iconsetPath = "AppIcon.iconset"
try? FileManager.default.removeItem(atPath: iconsetPath)
try! FileManager.default.createDirectory(atPath: iconsetPath, withIntermediateDirectories: true)

let sizes: [(String, Int)] = [
    ("icon_16x16", 16), ("icon_16x16@2x", 32),
    ("icon_32x32", 32), ("icon_32x32@2x", 64),
    ("icon_128x128", 128), ("icon_128x128@2x", 256),
    ("icon_256x256", 256), ("icon_256x256@2x", 512),
    ("icon_512x512", 512), ("icon_512x512@2x", 1024),
]

for (name, size) in sizes {
    let image = drawIcon(size: size)
    guard let tiff = image.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let png = rep.representation(using: .png, properties: [:]) else {
        fatalError("Failed to create PNG for \(name)")
    }
    try! png.write(to: URL(fileURLWithPath: "\(iconsetPath)/\(name).png"))
}

let proc = Process()
proc.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
proc.arguments = ["-c", "icns", iconsetPath, "-o", "AppIcon.icns"]
try! proc.run()
proc.waitUntilExit()

guard proc.terminationStatus == 0 else {
    fatalError("iconutil failed")
}

try? FileManager.default.removeItem(atPath: iconsetPath)
print("Created AppIcon.icns")
