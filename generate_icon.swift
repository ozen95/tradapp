#!/usr/bin/swift
import AppKit

// ─── Dessin de l'icône ────────────────────────────────────────────────────────

func drawIcon(size: CGFloat) -> NSImage {
    return NSImage(size: NSSize(width: size, height: size), flipped: false) { _ in
        guard let ctx = NSGraphicsContext.current?.cgContext else { return false }
        let s = size

        // ── Clip : rectangle arrondi macOS ────────────────────────────────
        let corner = s * 0.2237
        let clipPath = CGPath(roundedRect: CGRect(x: 0, y: 0, width: s, height: s),
                              cornerWidth: corner, cornerHeight: corner, transform: nil)
        ctx.addPath(clipPath)
        ctx.clip()

        // ── Dégradé fond : bleu #2563EB → indigo #4F46E5 ─────────────────
        let cs = CGColorSpaceCreateDeviceRGB()
        let gradColors = [
            CGColor(red: 0.145, green: 0.388, blue: 0.922, alpha: 1.0),
            CGColor(red: 0.310, green: 0.275, blue: 0.898, alpha: 1.0)
        ] as CFArray
        let locs: [CGFloat] = [0.0, 1.0]
        if let grad = CGGradient(colorsSpace: cs, colors: gradColors, locations: locs) {
            ctx.drawLinearGradient(grad,
                                   start: CGPoint(x: 0,    y: s),
                                   end:   CGPoint(x: s, y: 0),
                                   options: [])
        }

        // ── Bulle 1 : bas-gauche, blanche opaque (envoi) ──────────────────
        let bW: CGFloat = s * 0.60
        let bH: CGFloat = s * 0.33
        let bR: CGFloat = bH * 0.38

        let b1x = s * 0.10
        let b1y = s * 0.22
        bubbleFill(ctx: ctx,
                   rect:  CGRect(x: b1x, y: b1y, width: bW, height: bH),
                   radius: bR,
                   tailX:  b1x + bW * 0.18,
                   tailTip: CGPoint(x: b1x + bW * 0.07, y: b1y - bH * 0.26),
                   tailEnd: b1x + bW * 0.38,
                   color:  CGColor(red: 1, green: 1, blue: 1, alpha: 0.97))

        // Lignes de texte dans bulle 1
        textLines(ctx: ctx, bubbleRect: CGRect(x: b1x, y: b1y, width: bW, height: bH),
                  color: CGColor(red: 0.145, green: 0.388, blue: 0.922, alpha: 0.55),
                  lineCount: 3, s: s)

        // ── Bulle 2 : haut-droite, blanche semi-transparente (réception) ──
        let b2x = s * 0.30
        let b2y = s * 0.45
        bubbleFill(ctx: ctx,
                   rect:  CGRect(x: b2x, y: b2y, width: bW, height: bH),
                   radius: bR,
                   tailX:  b2x + bW * 0.70,
                   tailTip: CGPoint(x: b2x + bW * 0.95, y: b2y - bH * 0.26),
                   tailEnd: b2x + bW * 0.86,
                   color:  CGColor(red: 1, green: 1, blue: 1, alpha: 0.45))

        // Lignes de texte dans bulle 2
        textLines(ctx: ctx, bubbleRect: CGRect(x: b2x, y: b2y, width: bW, height: bH),
                  color: CGColor(red: 1, green: 1, blue: 1, alpha: 0.50),
                  lineCount: 2, s: s)

        return true
    }
}

// Dessine une bulle arrondie + queue triangulaire
func bubbleFill(ctx: CGContext, rect: CGRect, radius: CGFloat,
                tailX: CGFloat, tailTip: CGPoint, tailEnd: CGFloat,
                color: CGColor) {
    ctx.setFillColor(color)
    let combined = CGMutablePath()
    combined.addRoundedRect(in: rect, cornerWidth: radius, cornerHeight: radius)

    // Triangle "queue"
    let tail = CGMutablePath()
    tail.move(to: CGPoint(x: tailX, y: rect.minY))
    tail.addLine(to: tailTip)
    tail.addLine(to: CGPoint(x: tailEnd, y: rect.minY))
    tail.closeSubpath()
    combined.addPath(tail)

    ctx.addPath(combined)
    ctx.fillPath()
}

// Dessine des petites lignes pour simuler du texte dans la bulle
func textLines(ctx: CGContext, bubbleRect: CGRect, color: CGColor, lineCount: Int, s: CGFloat) {
    let lH = bubbleRect.height / CGFloat(lineCount + 1)
    let lW = [0.65, 0.80, 0.50]
    let lT = s * 0.018          // épaisseur des lignes
    let lR = lT / 2             // arrondi

    ctx.setFillColor(color)
    for i in 1...lineCount {
        let ratio = i < lW.count ? lW[i - 1] : 0.65
        let lineWidth = bubbleRect.width * 0.72 * ratio
        let lx = bubbleRect.minX + (bubbleRect.width - lineWidth) / 2
        let ly = bubbleRect.minY + lH * CGFloat(i) - lT / 2
        let lineRect = CGRect(x: lx, y: ly, width: lineWidth, height: lT)
        let linePath = CGPath(roundedRect: lineRect, cornerWidth: lR, cornerHeight: lR, transform: nil)
        ctx.addPath(linePath)
    }
    ctx.fillPath()
}

// ─── Sauvegarde PNG ───────────────────────────────────────────────────────────

func savePNG(_ image: NSImage, to path: String, size: Int) -> Bool {
    let targetSize = NSSize(width: size, height: size)
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil,
                               pixelsWide: size, pixelsHigh: size,
                               bitsPerSample: 8, samplesPerPixel: 4,
                               hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB,
                               bytesPerRow: 0, bitsPerPixel: 0)!
    rep.size = targetSize

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    image.draw(in: NSRect(origin: .zero, size: targetSize),
               from: NSRect(origin: .zero, size: image.size),
               operation: .copy, fraction: 1.0)
    NSGraphicsContext.restoreGraphicsState()

    guard let png = rep.representation(using: .png, properties: [:]) else { return false }
    do {
        try png.write(to: URL(fileURLWithPath: path))
        return true
    } catch {
        print("Erreur écriture \(path): \(error)")
        return false
    }
}

// ─── Main ─────────────────────────────────────────────────────────────────────

let iconsetDir = "/tmp/TradApp.iconset"
try? FileManager.default.createDirectory(atPath: iconsetDir, withIntermediateDirectories: true, attributes: nil)

let masterIcon = drawIcon(size: 1024)

let sizes: [(String, Int)] = [
    ("icon_16x16.png",       16),
    ("icon_16x16@2x.png",    32),
    ("icon_32x32.png",       32),
    ("icon_32x32@2x.png",    64),
    ("icon_128x128.png",    128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png",    256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png",    512),
    ("icon_512x512@2x.png", 1024),
]

var ok = true
for (name, px) in sizes {
    let path = "\(iconsetDir)/\(name)"
    if savePNG(masterIcon, to: path, size: px) {
        print("✓ \(name)")
    } else {
        print("✗ \(name) — ÉCHEC")
        ok = false
    }
}

print(ok ? "\n✅ Iconset généré dans \(iconsetDir)" : "\n❌ Erreurs lors de la génération")
