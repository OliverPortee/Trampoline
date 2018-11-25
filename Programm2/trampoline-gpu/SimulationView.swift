

import Foundation
import MetalKit
import GLKit



/// class representing the view which displays the model
class SimulationView: MTKView, DataControllerDelegate {
    /// renderer to render mesh
    var renderer: Renderer!
    /// updater to update mesh
    var updater: MeshUpdater!
    /// model mesh containing particle and spring buffers
    var mesh: CircularTrampolineMesh!
    /// mesh parameters of the current run
    var currentMeshParameters: CircularMeshParameters?
    /// variable to keep track of deltaTime
    var lastFrameTime: NSDate!
    /// constants to control speed of rotation and zoom
    let mouseDragSensitivity: Float = 0.004
    let scrollSensitivity: Float = 0.01
    /// dataController which interacts with model
    var dataController: DataController?
    /// bool indicating whether simulation is supposed to run; if state is .init, .parametersSet or .loadingModel this variable is ignored
    var shouldRun = false
    /// saves initial particleArray, springArray and constantsArray in order to reload model faster when it is reset
    var initialValues: ([Particle], [Spring], [Float])!
    /// virtual time that goes by during one frame
    var desiredVirtualFrameTime: Double?// = 0.001
    /// total time that went by since model started running
    var virtualTime: Double = 0
    /// state of the model (see ModelState in UtilTypes.swift)
    var state: ModelState! { didSet{ print("state changed to: \(state!)") } }
    /// init of the view
    required init(coder: NSCoder) {
        super.init(coder: coder)
        framebufferOnly = false
        self.preferredFramesPerSecond = 60
        /// sets state to .init
        self.state = .init
        /// initializing metal objectes for rendering and updating
        self.device = MTLCreateSystemDefaultDevice()!
        let library = device!.makeDefaultLibrary()!
        let commandQueue = self.device!.makeCommandQueue()!
        /// initializes renderer and updater
        self.renderer = Renderer(device: self.device!, commandQueue: commandQueue)
        self.updater = MeshUpdater(device: self.device!, library: library, commandQueue: commandQueue, springFunctionName: "spring_update", particleFunctionName: "particle_update")
        /// creates matrizes
        let projectionMatrix = GLKMatrix4MakePerspective(85 * Float.pi / 180, self.frame.aspectRatio, 0.01, 100)
        var parentModelMatrix = GLKMatrix4Identity; parentModelMatrix = GLKMatrix4Translate(parentModelMatrix, 0, 0.5, -3); parentModelMatrix = GLKMatrix4RotateX(parentModelMatrix, 20.0 * Float.pi / 180)
        /// creates mesh (which has no particles and springs yet)
        self.mesh = CircularTrampolineMesh(device: self.device!, projectionMatrix: projectionMatrix, parentModelMatrix: parentModelMatrix, updateHandler: {(_ dt: Float) in self.updater.update(dt: dt, mesh: self.mesh)})
        /// creates lastFrameTime to keep track of dt
        self.lastFrameTime = NSDate()

    }
    /// gets meshParameters from the ViewController
    func setMeshParamters(parameters: CircularMeshParameters) {
        mesh.initParameters(parameters)
        /// sets state to .parametersSet
        self.state = .parametersSet
    }
    
    /// loads mesh particles and springs in the background
    func loadModelInBackground(parameters: CircularMeshParameters) {
        self.state = .loadingModel
        /// lets the UI indicate that model is loading
        (window?.contentViewController as! ViewController).showHeight("?")
        (window?.contentViewController as! ViewController).showForce("?")
        (window?.contentViewController as! ViewController).showTime("?")
        /// runs a different thread to load model in background in order to keep UI running
        DispatchQueue.global(qos: .userInitiated).async {
            /// function to create particles and springs
            self.initialValues = self.mesh.makeCircularJumpingSheet(parameters: parameters)
            /// creates and sets dataController
            self.dataController = DataController()
            self.dataController!.dataParticleIndices = self.mesh.middleParticleIndices
            self.dataController!.mesh = self.mesh
            self.dataController!.delegate = self
            self.updater.dataController = self.dataController
            /// when this thread has completed its work the state is set to .readyToRun
            self.state = .readyToRun
        }
    }
    
    /// loads model from initial values which is faster
    func reloadModelInBackground() {
        self.state = .loadingModel
        self.mesh.initiateBuffers(particles: self.initialValues.0, springs: self.initialValues.1, constants: self.initialValues.2)
        self.dataController?.reset()
        self.lastFrameTime = NSDate()
        self.state = .readyToRun
    }

    /// called every frame to get dt, either from real time or from virtualTime
    private func updateTime() -> Double {
        let realDeltaTime = -lastFrameTime.timeIntervalSinceNow
        self.lastFrameTime = NSDate()
        if let virtualDeltaTime = desiredVirtualFrameTime { return virtualDeltaTime }
        return realDeltaTime

    }
    
    /// main update loop; function which is called every frame by the Cocoa  framework
    override func draw(_ dirtyRect: NSRect) {
        /// fetch dt
        let dt = updateTime()
        /// assures that there is a drawable available
        guard currentDrawable != nil else { return }
        /// changes state if necesssary
        if shouldRun == true && state == .readyToRun {
            state = .running
        } else if shouldRun == false && state == .running {
            state = .readyToRun
        }
        /// renders and/or updates the model according to the current frame
        switch self.state! {
        /// do nothing when state is .init because model is not initialized yet
        case .`init`:
            break
        /// renders blue edge of trampoline when model is initialized
        case .parametersSet, .loadingModel:
            renderer.renderFrame(renderObject: mesh, drawable: currentDrawable!, renderOnlyOtherRenderObjects: true, dt: dt)
        /// renders mesh and blue edge when model is ready to run
        case .readyToRun:
            renderer.renderFrame(renderObject: mesh, drawable: currentDrawable!, renderOnlyOtherRenderObjects: false, dt: dt)
            (window?.contentViewController as! ViewController).showHeight("!")
            (window?.contentViewController as! ViewController).showForce("!")
            (window?.contentViewController as! ViewController).showTime("!")
        /// renders and updates and updates every thing
        case .running:
            virtualTime += dt
            self.mesh.updateHandler(Float(dt))
            renderer.renderFrame(renderObject: mesh, drawable: currentDrawable!, renderOnlyOtherRenderObjects: false, dt: dt)
            /// shows height and force of dataParticles and time
            (window?.contentViewController as! ViewController).showHeight(String(format: "%.2f", dataController?.dataParticleHeight ?? -999))
            (window?.contentViewController as! ViewController).showForce(String(format: "%.1f", dataController?.dataParticleForce.y ?? -999))
            (window?.contentViewController as! ViewController).showTime(String(format: "%.3f", virtualTime))
            
        }
    }
    
    /// method to reset simulation
    func resetSim(resetVirtualTime: Bool) {
        if state == .readyToRun || state == .running {
            if resetVirtualTime { virtualTime = 0 }
            reloadModelInBackground()
            shouldRun = false
            (window?.contentViewController as! ViewController).showHeight("?")
            (window?.contentViewController as! ViewController).showForce("?")
            (window?.contentViewController as! ViewController).showTime("?")
        }
    }
}

/// extension to deal with simView related user events
extension SimulationView {
    /// rotates mesh on mouse drag
    override func mouseDragged(with event: NSEvent) {
        mesh.rotationX += (Float(event.deltaY) * mouseDragSensitivity)
        mesh.rotationY += (Float(event.deltaX) * mouseDragSensitivity)
        mesh.rotationZ += (Float(event.deltaZ) * mouseDragSensitivity)
    }
    /// ensure that the graphics of the mesh does not skew by resetting the projection matrix
    override func resize(withOldSuperviewSize oldSize: NSSize) {
        mesh.projectionMatrix = float4x4(glkMatrix: GLKMatrix4MakePerspective(85 * Float.pi / 180, frame.aspectRatio, 0.01, 100))
    }
    /// zooms in and out on scroll event
    override func scrollWheel(with event: NSEvent) {
        let deltaZ = Float(event.scrollingDeltaY) * scrollSensitivity
        mesh.parentModelMatrix[3, 2] += deltaZ
    }
}




