

/// utility types for simple window geometry
struct Size {
    var width : Float
    var height : Float
}

struct Point {
    var x : Float
    var y : Float
}

struct Rect {
    var point : Point
    var size : Size

    func pointIsWithinRect(_ x: Float, _ y: Float) -> Bool {
        return x >= point.x && x <= (point.x + size.width) && y >= point.y && y <= (point.y + size.height)
    }
}

/// class for buttons (unfortunately they cannot display any text yet, glut functions don not work)
class Button {
    /// rectangular area of button
    var frameRect : Rect
    /// callback which will be called when button was clicked
    var callback: () -> Void
    /// bool indicating whether there might be potential button click
    var mouseGotPressedWithinFrameRect = false
    /// text of button (not working yet)
    var text: String
    /// delegate for displaying the button
    var graphicsDelegate: Graphics?
    /** init function of button
     init function of button
     - Parameter:
         - x: x position on screen (left side)
         - y: y position on screen (bottom side)
         - width: width of button
         - height: height of button
         - text: String containting button text
         - clickCallback: callback which is called when button was clicked
    */
    init(x: Float, y: Float, width: Float, height: Float, text: String, clickCallback: @escaping () -> Void) {
        frameRect = Rect(point: Point(x: x, y: y), size: Size(width: width, height: height))
        callback = clickCallback
        self.text = text
    }
    /// convenience init for button with rect instead of x, y, width, height
    init(rect: Rect, text: String, clickCallback: @escaping () -> Void) {
        frameRect = rect
        callback = clickCallback
        self.text = text
    }
    /// receives mouse event and processes it
    func mouseEvent( _ state: Int32, _ x: Float, _ y: Float) {
        if state == 0 && frameRect.pointIsWithinRect(x, y) {
            mouseGotPressedWithinFrameRect = true
        }
        else if state == 1 && mouseGotPressedWithinFrameRect == true && frameRect.pointIsWithinRect(x, y) {
            callback()
            mouseGotPressedWithinFrameRect = false

        } else {
            mouseGotPressedWithinFrameRect = false
        }
    }
    /// display function
    func display() {
        if mouseGotPressedWithinFrameRect {
            graphicsDelegate?.drawPressedButton(x1: frameRect.point.x,
                                                y1: frameRect.point.y,
                                                x2: frameRect.point.x + frameRect.size.width,
                                                y2: frameRect.point.y + frameRect.size.height,
                                                text: text)
        } else {
            graphicsDelegate?.drawUnpressedButton(x1: frameRect.point.x,
                                                  y1: frameRect.point.y,
                                                  x2: frameRect.point.x + frameRect.size.width,
                                                  y2: frameRect.point.y + frameRect.size.height,
                                                  text: text)
        }
    }
}
