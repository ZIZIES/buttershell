import AppKit
import CoreGraphics

// Renders the app icon into an .iconset folder:
//   swift scripts/icon/make_icon.swift Resources/AppIcon.iconset
//   iconutil -c icns Resources/AppIcon.iconset -o Resources/AppIcon.icns

let s: CGFloat = 1024
let cs = CGColorSpace(name: CGColorSpace.sRGB)!
let full = CGRect(x: 0, y: 0, width: s, height: s)

func makeContext(_ px: Int) -> CGContext {
    CGContext(data: nil, width: px, height: px, bitsPerComponent: 8, bytesPerRow: 0,
              space: cs, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
}

func layer(_ draw: (CGContext) -> Void) -> CGImage {
    let c = makeContext(Int(s))
    draw(c)
    return c.makeImage()!
}

// design coordinates: top-left origin on a 1024 canvas
func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x, y: s - y) }
func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> CGRect {
    CGRect(x: x, y: s - y - h, width: w, height: h)
}

func rgb(_ hex: UInt32, _ a: CGFloat = 1) -> CGColor {
    CGColor(srgbRed: CGFloat((hex >> 16) & 0xff) / 255, green: CGFloat((hex >> 8) & 0xff) / 255,
            blue: CGFloat(hex & 0xff) / 255, alpha: a)
}

func gradient(_ stops: [(CGColor, CGFloat)]) -> CGGradient {
    CGGradient(colorsSpace: cs, colors: stops.map { $0.0 } as CFArray, locations: stops.map { $0.1 })!
}

let squircle = CGPath(roundedRect: full, cornerWidth: s * 0.225, cornerHeight: s * 0.225, transform: nil)

// melted butter across the top, standing in for the window title bar
let base: CGFloat = 250
let fillet: CGFloat = 30
let drips: [(x: CGFloat, w: CGFloat, tip: CGFloat)] = [
    (170, 40, 400), (330, 28, 322), (520, 46, 470), (705, 32, 360), (872, 42, 428),
]
let k: CGFloat = 0.5523

let butter = CGMutablePath()
butter.move(to: p(-10, -10))
butter.addLine(to: p(-10, base))
for d in drips {
    butter.addLine(to: p(d.x - d.w - fillet, base))
    butter.addQuadCurve(to: p(d.x - d.w, base + fillet), control: p(d.x - d.w, base))
    butter.addLine(to: p(d.x - d.w, d.tip - d.w))
    butter.addCurve(to: p(d.x, d.tip), control1: p(d.x - d.w, d.tip - d.w + k * d.w),
                    control2: p(d.x - k * d.w, d.tip))
    butter.addCurve(to: p(d.x + d.w, d.tip - d.w), control1: p(d.x + k * d.w, d.tip),
                    control2: p(d.x + d.w, d.tip - d.w + k * d.w))
    butter.addLine(to: p(d.x + d.w, base + fillet))
    butter.addQuadCurve(to: p(d.x + d.w + fillet, base), control: p(d.x + d.w, base))
}
butter.addLine(to: p(s + 10, base))
butter.addLine(to: p(s + 10, -10))
butter.closeSubpath()
butter.addEllipse(in: rect(503, 508, 34, 34))

let butterLayer = layer { c in
    c.addPath(butter)
    c.clip()
    c.drawLinearGradient(gradient([(rgb(0xFFF4C7), 0), (rgb(0xFFDA6B), 0.5), (rgb(0xF5B43A), 1)]),
                         start: p(0, 0), end: p(0, 540), options: [.drawsAfterEndLocation])

    // darker lower rim so the drips read as round
    for (offset, alpha) in [(CGFloat(16), CGFloat(0.22)), (7, 0.35)] {
        let rim = CGMutablePath()
        rim.addRect(full.insetBy(dx: -40, dy: -40))
        rim.addPath(butter, transform: CGAffineTransform(translationX: 0, y: offset))
        c.addPath(rim)
        c.setFillColor(rgb(0xD9861A, alpha))
        c.fillPath(using: .evenOdd)
    }

    // top sheen
    c.drawLinearGradient(gradient([(rgb(0xFFFFFF, 0.45), 0), (rgb(0xFFFFFF, 0), 1)]),
                         start: p(0, 0), end: p(0, 120), options: [])

    // glossy streaks down the longer drips
    c.setLineCap(.round)
    c.setStrokeColor(rgb(0xFFFFFF, 0.55))
    for d in drips where d.tip - d.w > base + fillet + 40 {
        c.setLineWidth(d.w * 0.28)
        c.move(to: p(d.x - d.w * 0.45, base + fillet + 8))
        c.addLine(to: p(d.x - d.w * 0.45, d.tip - d.w * 0.95))
        c.strokePath()
    }

    // window buttons pressed into the butter
    for x: CGFloat in [132, 212, 292] {
        let dot = rect(x - 27, 128 - 27, 54, 54)
        c.setFillColor(rgb(0xE7A33A))
        c.fillEllipse(in: dot)
        c.saveGState()
        c.addEllipse(in: dot)
        c.clip()
        let lip = CGMutablePath()
        lip.addRect(dot.insetBy(dx: -10, dy: -10))
        lip.addEllipse(in: dot.offsetBy(dx: 0, dy: -7))
        c.addPath(lip)
        c.setFillColor(rgb(0xB9761C, 0.8))
        c.fillPath(using: .evenOdd)
        c.restoreGState()
    }
}

// the prompt
let chevron = CGMutablePath()
chevron.move(to: p(260, 600))
chevron.addLine(to: p(425, 720))
chevron.addLine(to: p(260, 840))

let prompt = CGMutablePath()
prompt.addPath(chevron.copy(strokingWithWidth: 78, lineCap: .round, lineJoin: .round, miterLimit: 10))
prompt.addPath(CGPath(roundedRect: rect(490, 802, 240, 78), cornerWidth: 22, cornerHeight: 22, transform: nil))

let promptLayer = layer { c in
    c.addPath(prompt)
    c.clip()
    c.drawLinearGradient(gradient([(rgb(0xFFEA9A), 0), (rgb(0xF7B83F), 1)]),
                         start: p(0, 560), end: p(0, 880), options: [])
}

let master = layer { c in
    c.addPath(squircle)
    c.clip()
    c.drawLinearGradient(gradient([(rgb(0x2C2622), 0), (rgb(0x131110), 1)]),
                         start: p(0, 0), end: p(0, s), options: [])
    c.drawRadialGradient(gradient([(rgb(0xFFC23D, 0.13), 0), (rgb(0xFFC23D, 0), 1)]),
                         startCenter: p(460, 740), startRadius: 0,
                         endCenter: p(460, 740), endRadius: 460, options: [])

    // phosphor glow on the prompt
    c.saveGState()
    c.setShadow(offset: .zero, blur: 60, color: rgb(0xFFC23D, 0.6))
    c.draw(promptLayer, in: full)
    c.restoreGState()

    // butter casts a shadow onto the window
    c.saveGState()
    c.setShadow(offset: CGSize(width: 0, height: -14), blur: 30, color: rgb(0x000000, 0.6))
    c.draw(butterLayer, in: full)
    c.restoreGState()

    c.addPath(squircle)
    c.setStrokeColor(rgb(0xFFFFFF, 0.10))
    c.setLineWidth(6)
    c.strokePath()
}

// halve step by step so the small sizes stay crisp
var images: [Int: CGImage] = [1024: master]
var px = 1024
while px > 16 {
    let c = makeContext(px / 2)
    c.interpolationQuality = .high
    c.draw(images[px]!, in: CGRect(x: 0, y: 0, width: px / 2, height: px / 2))
    px /= 2
    images[px] = c.makeImage()!
}

let out = URL(fileURLWithPath: CommandLine.arguments[1])
try! FileManager.default.createDirectory(at: out, withIntermediateDirectories: true)
for pt in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let name = scale == 1 ? "icon_\(pt)x\(pt).png" : "icon_\(pt)x\(pt)@2x.png"
        let rep = NSBitmapImageRep(cgImage: images[pt * scale]!)
        try! rep.representation(using: .png, properties: [:])!.write(to: out.appendingPathComponent(name))
    }
}
