// Disegna l'icona: quattro spicchi coi colori di Swift, UIKit, Kotlin e Flutter.
// Uso: swift scripts/make_icon.swift Resources/Assets.xcassets/AppIcon.appiconset/icon.png
import AppKit

let size: CGFloat = 1024
let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(size), pixelsHigh: Int(size),
                           bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                           colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
let ctx = NSGraphicsContext.current!.cgContext

func c(_ hex: UInt32) -> CGColor {
    CGColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
}

ctx.setFillColor(c(0xFFF8F3))
ctx.fill(CGRect(x: 0, y: 0, width: size, height: size))

let tile: CGFloat = 330, gap: CGFloat = 56
let origin = (size - tile * 2 - gap) / 2
// Coordinate CoreGraphics: y cresce verso l'alto, quindi la riga "alta" è la seconda.
let tiles: [(CGFloat, CGFloat, [UInt32])] = [
    (0, 1, [0xFA7343, 0xF05138]),
    (1, 1, [0x3FA2FF, 0x007AFF]),
    (0, 0, [0x7F52FF, 0xC711E1, 0xE44857]),
    (1, 0, [0x13B9FD, 0x02569B]),
]
for (col, row, colors) in tiles {
    let rect = CGRect(x: origin + col * (tile + gap), y: origin + row * (tile + gap), width: tile, height: tile)
    ctx.saveGState()
    ctx.addPath(CGPath(roundedRect: rect, cornerWidth: 92, cornerHeight: 92, transform: nil))
    ctx.clip()
    let g = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB), colors: colors.map(c) as CFArray, locations: nil)!
    ctx.drawLinearGradient(g, start: CGPoint(x: rect.minX, y: rect.maxY), end: CGPoint(x: rect.maxX, y: rect.minY), options: [])
    ctx.restoreGState()
}

try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
