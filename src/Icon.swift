import Cocoa

func makePencilIcon(size: NSSize = NSSize(width: 18, height: 18)) -> NSImage {
    let img = NSImage(size: size)
    img.lockFocus()

    NSColor.clear.setFill()
    NSBezierPath(rect: NSRect(origin: .zero, size: size)).fill()

    let strokeColor = NSColor.labelColor
    strokeColor.setStroke()
    let path = NSBezierPath()
    path.move(to: NSPoint(x: size.width * 0.2, y: size.height * 0.8))
    path.line(to: NSPoint(x: size.width * 0.8, y: size.height * 0.2))
    path.lineWidth = max(1.0, size.width * 0.12)
    path.stroke()

    let tip = NSBezierPath()
    tip.move(to: NSPoint(x: size.width * 0.8, y: size.height * 0.2))
    tip.line(to: NSPoint(x: size.width * 0.75, y: size.height * 0.15))
    tip.line(to: NSPoint(x: size.width * 0.85, y: size.height * 0.15))
    tip.close()
    tip.fill()

    img.unlockFocus()
    img.isTemplate = true
    return img
}
