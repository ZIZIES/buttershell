import AppKit
import CoreGraphics

let size = 1024
let cs = CGColorSpace(name: CGColorSpace.sRGB)!
let ctx = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8,
                    bytesPerRow: 0, space: cs,
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
let s = CGFloat(size)

// rounded-square dark slate background
let bgRect = CGRect(x: 0, y: 0, width: s, height: s)
let bgPath = CGPath(roundedRect: bgRect, cornerWidth: s * 0.225, cornerHeight: s * 0.225, transform: nil)
ctx.addPath(bgPath)
ctx.clip()
let bgColors = [CGColor(srgbRed: 0.13, green: 0.13, blue: 0.16, alpha: 1),
                CGColor(srgbRed: 0.07, green: 0.07, blue: 0.09, alpha: 1)] as CFArray
ctx.drawLinearGradient(CGGradient(colorsSpace: cs, colors: bgColors, locations: [0, 1])!,
                       start: CGPoint(x: 0, y: s), end: CGPoint(x: 0, y: 0), options: [])

func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * s, y: y * s) }

// butter block: front face
let front = CGMutablePath()
front.move(to: p(0.20, 0.30))
front.addLine(to: p(0.74, 0.30))
front.addLine(to: p(0.74, 0.52))
front.addLine(to: p(0.20, 0.52))
front.closeSubpath()

// side face (right)
let side = CGMutablePath()
side.move(to: p(0.74, 0.30))
side.addLine(to: p(0.84, 0.40))
side.addLine(to: p(0.84, 0.62))
side.addLine(to: p(0.74, 0.52))
side.closeSubpath()

// top face
let top = CGMutablePath()
top.move(to: p(0.20, 0.52))
top.addLine(to: p(0.74, 0.52))
top.addLine(to: p(0.84, 0.62))
top.addLine(to: p(0.30, 0.62))
top.closeSubpath()

ctx.setShadow(offset: CGSize(width: 0, height: -s*0.02), blur: s*0.05,
              color: CGColor(srgbRed: 0, green: 0, blue: 0, alpha: 0.5))
ctx.setFillColor(CGColor(srgbRed: 1.00, green: 0.80, blue: 0.28, alpha: 1))
ctx.addPath(front); ctx.fillPath()
ctx.setFillColor(CGColor(srgbRed: 0.93, green: 0.66, blue: 0.16, alpha: 1))
ctx.addPath(side); ctx.fillPath()
ctx.setShadow(offset: .zero, blur: 0, color: nil)
ctx.setFillColor(CGColor(srgbRed: 1.00, green: 0.93, blue: 0.62, alpha: 1))
ctx.addPath(top); ctx.fillPath()

// melty drip running down the front-left
let drip = CGMutablePath()
drip.move(to: p(0.28, 0.30))
drip.addLine(to: p(0.36, 0.30))
drip.addLine(to: p(0.36, 0.16))
drip.addCurve(to: p(0.30, 0.16), control1: p(0.36, 0.10), control2: p(0.30, 0.10))
drip.closeSubpath()
ctx.setFillColor(CGColor(srgbRed: 1.00, green: 0.80, blue: 0.28, alpha: 1))
ctx.addPath(drip); ctx.fillPath()

// tiny highlight on the top face corner
ctx.setFillColor(CGColor(srgbRed: 1, green: 1, blue: 0.9, alpha: 0.7))
let hl = CGMutablePath()
hl.move(to: p(0.30, 0.62))
hl.addLine(to: p(0.84, 0.62))
hl.addLine(to: p(0.82, 0.645))
hl.addLine(to: p(0.31, 0.645))
hl.closeSubpath()
ctx.addPath(hl); ctx.fillPath()

let img = ctx.makeImage()!
let rep = NSBitmapImageRep(cgImage: img)
let png = rep.representation(using: .png, properties: [:])!
try! png.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
