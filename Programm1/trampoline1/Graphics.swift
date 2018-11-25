
import OpenGL
import simd

/// class for displaying objects with OpenGL
class Graphics {
    var WIDTH: Int32, HEIGHT: Int32
    /// init function of Graphics class
    init(width: Int32, height: Int32) {
        WIDTH = width
        HEIGHT = height
    }
    /// initializes OpenGL
    func initOpenGL() {
        glFrustum(-1, 1, -1, 1, 1, 6)
        glTranslated(0, 0, -2.7)
        glRotated(20, 1, 0, 0)
        glClearColor(1, 1, 1, 1)
    }
    /// reshape callback (makes sure that the displayed objects are not skewed when resizing the window)
    func reshape(_ width: Int32, _ height: Int32) {
        WIDTH = width
        HEIGHT = height
        glViewport(0, 0, WIDTH, HEIGHT)
    }
    /// clears the window screen and resets rotation
    func startDrawingProcess() {
        glClear(UInt32(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT))
        glRotated(0.1, 0, 1, 0)
    }
    /// draws coordinate system axis (mainly for debugging)
    func drawDefaults() {
        glLineWidth(1.0)
        glBegin(UInt32(GL_LINES))
        glColor3d(1.0, 0.0, 0.0)
        glVertex3d(0.0, 0.0, 0.0)
        glVertex3d(1.0, 0.0, 0.0)
        glColor3d(0.0, 1.0, 0.0)
        glVertex3d(0.0, 0.0, 0.0)
        glVertex3d(0.0, 1.0, 0.0)
        glColor3d(0.0, 0.0, 1.0)
        glVertex3d(0.0, 0.0, 0.0)
        glVertex3d(0.0, 0.0, 1.0)
        glEnd()
    }
    /// draws spring (one simple line between two points)
    func drawSpring(_ vec1: simd_float3, _ vec2: simd_float3) {
        glLineWidth(1.0)
        glColor3d(0.0, 0.0, 0.0)
        glBegin(UInt32(GL_LINES))
        glVertex3f(vec1.x, vec1.y, vec1.z)
        glVertex3f(vec2.x, vec2.y, vec2.z)
        glEnd()
    }
    /// draws particel (a short line)
    func drawParticle(_ vec: simd_float3) {
        glColor3d(0.0, 0.0, 0.0)
        glBegin(UInt32(GL_POINTS))
        glVertex3f(vec.x, vec.y, vec.z)
        glVertex3f(vec.x, vec.y + 0.01, vec.z)
        glEnd()
    }
    /// draws trampoline edge which is a blue circe
    func drawTrampolineEdge(middle: simd_float3, radius: Float) {
        glLineWidth(2.0)
        glColor3d(0.0, 1.0, 1.0)
        glBegin(UInt32(GL_LINE_LOOP))
        let n_vertices = 50
        let angleStep = 2.0 * Double.pi / Double(n_vertices)
        for angle in stride(from: 0, to: Double.pi * 2.0, by: angleStep) {
            glVertex3f(radius * Float(sin(angle)) + middle.x, 0.0 + middle.y, radius * Float(cos(angle)) + middle.z)
        }
        glEnd()
    }
    /// draws unpressed button (grey rectangle)
    func drawUnpressedButton(x1: Float, y1: Float, x2: Float, y2: Float, text: String) {
        glPushMatrix()
        glLoadIdentity()
        glOrtho(0, GLdouble(WIDTH), GLdouble(HEIGHT), 0, 0, 1)
        glColor3f(0.5, 0.5, 0.5)
        glRectf(x1, y1, x2, y2)
        glPopMatrix()
    }
    /// draws pressed button (brighter than unpressed button)
    func drawPressedButton(x1: Float, y1: Float, x2: Float, y2: Float, text: String) {
        glPushMatrix()
        glLoadIdentity()
        glOrtho(0, GLdouble(WIDTH), GLdouble(HEIGHT), 0, 0, 1)
        glColor3f(0.6, 0.6, 0.6)
        glRectf(x1, y1, x2, y2)
        glPopMatrix()
    }
}
