
import Foundation
import simd


/// callbacks for button events
func btnCollectDataCallback() {
    controller.collectData()
}

func btnDownCallback() {
    controller.dataPartDown()
}

func btnUpCallback() {
    controller.dataPartUp()
}

func btnAnalyseDataCallback() {
    controller.analyseData()
}

func btnLockUnlockDataP() {
    controller.lockUnlockDataP()
}


/// class for managing program logic
class Controller {
    /// object which executes drawing commands
    var graphics: Graphics
    /// abstract class object which holds everything which is in model world
    var world: World
    /// time at the last frame
    var time: Date
    /// virtual time between two frames
    var dt: Float
    /// obejct which processes incomming measurement data
    var dataController: DoubleData
    /// array of buttons
    var buttons = [Button]()
    
    /// init functino of Controller class
    init() {
        let WIDTH: Int32 = 1000
        let HEIGHT: Int32 = 1000
        /// initializes the graphics object
        graphics = Graphics(width: WIDTH, height: HEIGHT)
        /// initializes the world object
        world = World()
        /// sets the world's delegate
        world.graphicsDelegate = graphics
        /// initializes time and dt
        time = Date()
        dt = 0.001
        /// initializes GLUT framework
        var n: Int32 = 1
        glutInit(&n, nil)
        glutInitWindowSize(WIDTH, HEIGHT)
        glutInitDisplayMode(UInt32(GLUT_RGBA | GLUT_DOUBLE | GLUT_DEPTH))
        glutCreateWindow("trampoline")
        /// initializes OpenGL
        graphics.initOpenGL()
        /// initializes the dataController
        dataController = DoubleData()
        /// sets dataParticles
        dataController.dataParticle = getNearestParticles(of: simd_float3(x: 0, y: 0, z: 0), within: world.mesh.particles, number: 1, containingSelf: true)[0] // world.mesh.particles.first(where: {$0.pos == Vec3.zero()})
        dataController.dataParticle?.lock()
        /// initializes all buttons
        buttons.append(Button(x: 10, y: 10, width: 100, height: 30, text: "collect Data", clickCallback: btnCollectDataCallback))
        buttons.append(Button(x: 120, y: 10, width: 100, height: 30, text: "down", clickCallback: btnDownCallback))
        buttons.append(Button(x: 230, y: 10, width: 100, height: 30, text: "up", clickCallback: btnUpCallback))
        buttons.append(Button(x: 340, y: 10, width: 100, height: 30, text: "analyse Data", clickCallback: btnAnalyseDataCallback))
        buttons.append(Button(x: 450, y: 10, width: 100, height: 30, text: "lock/unlock", clickCallback: btnLockUnlockDataP))
        /// sets graphicsDelegate so that buttons can be displayed
        for button in buttons {
            button.graphicsDelegate = graphics
        }
    }
    
    /// method which manages one loop cycle including updating and drawing the model
    func updateAndDisplay() {
        /// calculates new dt
        dt = Float(time.timeIntervalSinceNow * -1.0)
        /// sets back time
        time = Date()
        /// updates the model (in this case hardcoded time, else use dt)
        world.update(dt: 0.0001)       // IMPORTANT: - update // bei fineness == 0.2 ist 0.001334 der Schwellenwert
        /// helper functions to update OpenGL
        graphics.startDrawingProcess()
        /// displays the model
        world.display()
        /// displays buttons
        for button in buttons {
            button.display()
        }
        /// swaps the pixel buffers for more efficiency
        glutSwapBuffers()
    }
    /// called when window is reshaped
    func reshape(_ width: Int32, _ height: Int32) {
        graphics.reshape(width, height)
    }
    /// called when user clicks on window screen
    func mouseEvent(_ state: Int32, _ x: Int32, _ y: Int32) {
        /// passes the event further in response chain
        for button in buttons {
            button.mouseEvent(state, Float(x), Float(y))
        }
    }
    /// callback for collect data button
    func collectData() {
        dataController.shouldCollectData = true
    }
    /// callback for particle down button
    func dataPartDown() {
        dataController.dataPartDown()
    }
    /// callback for particle up button
    func dataPartUp() {
        dataController.dataPartUp()
    }
    /// callback for analyse data button
    func analyseData() {
        dataController.printData()
    }
    /// callback for toggling isLocked of dataParticld
    func lockUnlockDataP () {
        dataController.lockUnlockDataP()
    }
}


/// initializes controller and thus all other important objects
var controller = Controller()

/// callback for update loop event
func displayCallback() {
    controller.updateAndDisplay()
}
/// callback for reshape events
func reshapeCallback(_ width: Int32, _ height: Int32) {
    controller.reshape(width, height)
}
/// callback for mouseclicks
func mouseCallback(_ button: Int32, _ state: Int32, _ x: Int32, _ y: Int32) {
    if button == 0 {
        controller.mouseEvent(state, x, y)
    }
}



/// sets up GLUT
func main() {
    /// sets update loop func (called automatically once per frame)
    glutDisplayFunc(displayCallback)
    glutIdleFunc(displayCallback)
    /// sets reshape func
    glutReshapeFunc(reshapeCallback)
    /// sets mouse event func
    glutMouseFunc(mouseCallback)
    /// starts update loop
    glutMainLoop()
}


/// executes programm
main()


