// Disegna l'icona: le quattro tessere coi colori di Swift, UIKit, Kotlin e
// Flutter, ognuna col proprio segno in bianco — gli stessi di `TrackMark`,
// così l'icona e il marchio nello splash sono la stessa cosa.
//
// Uso: swift scripts/make_icon.swift Resources/Assets.xcassets/AppIcon.appiconset/icon.png
//
// Il PNG esce senza canale alpha (noneSkipLast): l'icona dell'App Store non può
// averne, altrimenti l'upload viene respinto con ITMS-90717.
import AppKit
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
import Foundation

let size = 1024
let space = CGColorSpace(name: CGColorSpace.sRGB)!
let ctx = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
                    space: space, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!

func c(_ hex: UInt32) -> CGColor {
    CGColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
}

ctx.setFillColor(c(0xFFF8F3))
ctx.fill(CGRect(x: 0, y: 0, width: CGFloat(size), height: CGFloat(size)))

// MARK: I segni

/// Un punto dentro una scatola, con `v` misurato dall'alto come in SwiftUI:
/// CoreGraphics ha la y al contrario, e ragionare al contrario fa sbagliare.
func p(_ u: CGFloat, _ v: CGFloat, in box: CGRect) -> CGPoint {
    CGPoint(x: box.minX + u * box.width, y: box.maxY - v * box.height)
}

/// La scatola quadrata, o col rapporto chiesto, centrata nella tessera.
func box(in rect: CGRect, side: CGFloat, ratio: CGFloat = 1) -> CGRect {
    var w = side, h = side
    if ratio < 1 { w = side * ratio } else { h = side / ratio }
    return CGRect(x: rect.midX - w / 2, y: rect.midY - h / 2, width: w, height: h)
}

/// Kotlin: un quadrato con la tacca a V sul lato destro.
func kotlinMark(in rect: CGRect, side: CGFloat) {
    let b = box(in: rect, side: side)
    let path = CGMutablePath()
    path.move(to: p(1, 1, in: b))
    path.addLine(to: p(0, 1, in: b))
    path.addLine(to: p(0, 0, in: b))
    path.addLine(to: p(1, 0, in: b))
    path.addLine(to: p(0.5, 0.5, in: b))
    path.closeSubpath()
    ctx.addPath(path)
    ctx.fillPath()
}

/// Flutter: la trave in diagonale e la piega sotto. Proporzioni del logo (256×317).
func flutterMark(in rect: CGRect, side: CGFloat) {
    let b = box(in: rect, side: side, ratio: 256.0 / 317.0)
    let path = CGMutablePath()
    path.move(to: p(0.616, 0, in: b))
    path.addLine(to: p(0, 0.497, in: b))
    path.addLine(to: p(0.191, 0.651, in: b))
    path.addLine(to: p(0.997, 0, in: b))
    path.closeSubpath()
    path.move(to: p(0.612, 0.459, in: b))
    path.addLine(to: p(0.285, 0.723, in: b))
    path.addLine(to: p(0.612, 1, in: b))
    path.addLine(to: p(0.997, 1, in: b))
    path.addLine(to: p(0.672, 0.723, in: b))
    path.addLine(to: p(0.997, 0.459, in: b))
    path.closeSubpath()
    ctx.addPath(path)
    ctx.fillPath()
}

/// UIKit non ha un logo: è una schermata di iPhone, riempita in even-odd
/// perché lo schermo è un buco nella scocca.
func uikitMark(in rect: CGRect, side: CGFloat) {
    let b = box(in: rect, side: side, ratio: 0.62)
    func r(_ u: CGFloat, _ v: CGFloat, _ rw: CGFloat, _ rh: CGFloat, _ radius: CGFloat) -> CGPath {
        let frame = CGRect(x: b.minX + u * b.width,
                           y: b.maxY - (v + rh) * b.height,
                           width: rw * b.width, height: rh * b.height)
        return CGPath(roundedRect: frame, cornerWidth: radius * b.width,
                      cornerHeight: radius * b.width, transform: nil)
    }
    let path = CGMutablePath()
    path.addPath(r(0, 0, 1, 1, 0.19))                 // la scocca
    path.addPath(r(0.11, 0.07, 0.78, 0.86, 0.1))      // il buco: lo schermo
    path.addPath(r(0.11, 0.07, 0.78, 0.17, 0.08))     // la barra di navigazione
    path.addPath(r(0.22, 0.36, 0.56, 0.055, 0.03))    // due righe di contenuto
    path.addPath(r(0.22, 0.49, 0.38, 0.055, 0.03))
    path.addPath(r(0.11, 0.76, 0.78, 0.17, 0.08))     // la barra delle tab
    ctx.addPath(path)
    ctx.fillPath(using: .evenOdd)
}

/// Swift: il rondone è un simbolo di sistema, nessuno lo disegna meglio.
/// Si tinge di bianco prima, perché qui non c'è una view a dargli un colore.
func swiftMark(in rect: CGRect, side: CGFloat) {
    let config = NSImage.SymbolConfiguration(pointSize: side, weight: .regular)
    guard let symbol = NSImage(systemSymbolName: "swift", accessibilityDescription: nil)?
        .withSymbolConfiguration(config) else { fatalError("simbolo swift non trovato") }

    let white = NSImage(size: symbol.size)
    white.lockFocus()
    let full = NSRect(origin: .zero, size: symbol.size)
    symbol.draw(in: full)
    NSColor.white.set()
    full.fill(using: .sourceAtop)
    white.unlockFocus()

    let frame = CGRect(x: rect.midX - symbol.size.width / 2,
                       y: rect.midY - symbol.size.height / 2,
                       width: symbol.size.width, height: symbol.size.height)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx, flipped: false)
    white.draw(in: frame)
    NSGraphicsContext.restoreGraphicsState()
}

// MARK: Le quattro tessere

enum Mark { case swift, uikit, kotlin, flutter }

let side = CGFloat(size)
let tile: CGFloat = 330, gap: CGFloat = 56
let origin = (side - tile * 2 - gap) / 2
// Coordinate CoreGraphics: y cresce verso l'alto, quindi la riga "alta" è la seconda.
let tiles: [(CGFloat, CGFloat, [UInt32], Mark)] = [
    (0, 1, [0xFA7343, 0xF05138], .swift),
    (1, 1, [0x3FA2FF, 0x007AFF], .uikit),
    (0, 0, [0x7F52FF, 0xC711E1, 0xE44857], .kotlin),
    (1, 0, [0x13B9FD, 0x02569B], .flutter),
]
for (col, row, colors, mark) in tiles {
    let rect = CGRect(x: origin + col * (tile + gap), y: origin + row * (tile + gap), width: tile, height: tile)
    ctx.saveGState()
    ctx.addPath(CGPath(roundedRect: rect, cornerWidth: 92, cornerHeight: 92, transform: nil))
    ctx.clip()
    let g = CGGradient(colorsSpace: space, colors: colors.map(c) as CFArray, locations: nil)!
    ctx.drawLinearGradient(g, start: CGPoint(x: rect.minX, y: rect.maxY), end: CGPoint(x: rect.maxX, y: rect.minY), options: [])
    ctx.restoreGState()

    // Lo stesso rapporto fra segno e tessera che ha `AppMark`: la metà.
    let glyph = tile * 0.5
    ctx.setFillColor(.white)
    switch mark {
    case .swift: swiftMark(in: rect, side: glyph * 0.92)
    case .uikit: uikitMark(in: rect, side: glyph)
    case .kotlin: kotlinMark(in: rect, side: glyph)
    case .flutter: flutterMark(in: rect, side: glyph)
    }
}

let url = URL(fileURLWithPath: CommandLine.arguments[1]) as CFURL
let dest = CGImageDestinationCreateWithURL(url, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(dest, ctx.makeImage()!, nil)
guard CGImageDestinationFinalize(dest) else { fatalError("scrittura PNG fallita") }
