

import Foundation
import MetalKit
import GLKit

class SimulationView: MTKView, DataControllerDelegate {
    
    var renderer: Renderer!
    var updater: MeshUpdater!
    var mesh: CircularTrampolineMesh!
    var currentMeshParameters: MeshParameters?
    var lastFrameTime: NSDate!
    var mouseDragSensitivity: Float = 0.004
    var scrollSensitivity: Float = 0.01
    var dataController: DataController?
    var shouldRun = false
    var initialValues: ([Particle], [Spring], [Float])!
    var desiredVirtualFrameTime: Double?// = 0.001
    var virtualTime: Double = 0
    
    

    var state: ModelState! { didSet{ print("state changed to: \(state!)") } }
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
        self.preferredFramesPerSecond = 60
        self.state = .init
        self.device = MTLCreateSystemDefaultDevice()!
        let library = device!.makeDefaultLibrary()!
        let commandQueue = self.device!.makeCommandQueue()!
        self.renderer = Renderer(device: self.device!, commandQueue: commandQueue)
        self.updater = MeshUpdater(device: self.device!, library: library, commandQueue: commandQueue, springFunctionName: "spring_update", particleFunctionName: "particle_update")
        let projectionMatrix = GLKMatrix4MakePerspective(85 * Float.pi / 180, self.frame.aspectRatio, 0.01, 100)
        var parentModelMatrix = GLKMatrix4Identity; parentModelMatrix = GLKMatrix4Translate(parentModelMatrix, 0, 0, -3); parentModelMatrix = GLKMatrix4RotateX(parentModelMatrix, 20.0 * Float.pi / 180)
        self.mesh = CircularTrampolineMesh(device: self.device!, projectionMatrix: projectionMatrix, parentModelMatrix: parentModelMatrix, updateHandler: {(_ dt: Float) in self.updater.update(dt: dt, mesh: self.mesh)})
        self.lastFrameTime = NSDate()

    }
    
    func setMeshParamters(parameters: MeshParameters) {
        mesh.initParameters(parameters)
        self.state = .parametersSet
    }
    
    
    func loadModelInBackground(parameters: MeshParameters) {
        (window?.contentViewController as! ViewController).showHeight("?")
        (window?.contentViewController as! ViewController).showForce("?")
        (window?.contentViewController as! ViewController).showTime("?")
        self.state = .loadingModel
        DispatchQueue.global(qos: .userInitiated).async {
            self.initialValues = self.mesh.makeCircularJumpingSheet(parameters: parameters)
            self.dataController = DataController()
            self.dataController!.dataParticleIndices = self.mesh.middleParticleIndices
            self.dataController!.mesh = self.mesh
            self.dataController!.delegate = self
            self.updater.dataController = self.dataController
            self.state = .readyToRun
        }
    }
    
    func reloadModelInBackground() {
        self.state = .loadingModel
        self.mesh.initiateBuffers(particles: self.initialValues.0, springs: self.initialValues.1, constants: self.initialValues.2)
        self.dataController?.reset()
        self.lastFrameTime = NSDate()
        self.state = .readyToRun
        
    }

    private func updateTime() -> Double {
        let realDeltaTime = -lastFrameTime.timeIntervalSinceNow
        self.lastFrameTime = NSDate()
        if let virtualDeltaTime = desiredVirtualFrameTime { return virtualDeltaTime }
        return realDeltaTime

    }
    
    
    override func draw(_ dirtyRect: NSRect) {
        let dt = updateTime()
        
        guard currentDrawable != nil else { return }
        
        if shouldRun == true && state == .readyToRun {
            state = .running
        } else if shouldRun == false && state == .running {
            state = .readyToRun
        }
        
        switch self.state! {
        case .`init`:
            break
        case .parametersSet, .loadingModel:
            renderer.renderFrame(renderObject: mesh, drawable: currentDrawable!, renderOnlyOtherRenderObjects: true, dt: dt)
        case .readyToRun:
            renderer.renderFrame(renderObject: mesh, drawable: currentDrawable!, renderOnlyOtherRenderObjects: false, dt: dt)
            (window?.contentViewController as! ViewController).showHeight("!")
            (window?.contentViewController as! ViewController).showForce("!")
            (window?.contentViewController as! ViewController).showTime("!")
        case .running:
            virtualTime += dt
            self.mesh.updateHandler(Float(dt))
            renderer.renderFrame(renderObject: mesh, drawable: currentDrawable!, renderOnlyOtherRenderObjects: false, dt: dt)
            (window?.contentViewController as! ViewController).showHeight(String(format: "%.2f", dataController?.dataParticleHeight ?? -999))
            (window?.contentViewController as! ViewController).showForce(String(format: "%.1f", dataController?.dataParticleForce.y ?? -999))
            (window?.contentViewController as! ViewController).showTime(String(format: "%.1f", virtualTime))
            
        }
    }
    
    
    func resetSim() {
        if state == .readyToRun || state == .running {
            virtualTime = 0
            reloadModelInBackground()
            shouldRun = false
            (window?.contentViewController as! ViewController).showHeight("?")
            (window?.contentViewController as! ViewController).showForce("?")
            (window?.contentViewController as! ViewController).showTime("?")
        }
    }
    
    
}


extension SimulationView {
    
    
    override func mouseDragged(with event: NSEvent) {
        mesh.rotationX += (Float(event.deltaY) * mouseDragSensitivity)
        mesh.rotationY += (Float(event.deltaX) * mouseDragSensitivity)
        mesh.rotationZ += (Float(event.deltaZ) * mouseDragSensitivity)

        
    }
    

    override func resize(withOldSuperviewSize oldSize: NSSize) {
        mesh.projectionMatrix = float4x4(glkMatrix: GLKMatrix4MakePerspective(85 * Float.pi / 180, frame.aspectRatio, 0.01, 100))
    }
    
    override func scrollWheel(with event: NSEvent) {
        let deltaZ = Float(event.scrollingDeltaY) * scrollSensitivity
        mesh.parentModelMatrix[3, 2] += deltaZ
    }
    
    
    
    
}


enum ModelState {
    case `init`, parametersSet, loadingModel, readyToRun, running
}


struct MeshParameters: CustomStringConvertible {
    
    var r1: Float
    var r2: Float
    var particleMass: Float
    var fineness: Float
    var n_outerSprings: Float
    var innerSpringConstant: Float
    var innerVelConstant: Float
    var outerSpringConstant: Float
    var outerVelConstant: Float
    var outerSpringLength: Float
    var n_dataParticles: Int
    
    init(r1: Float, r2: Float, particleMass: Float, fineness: Float, n_outerSprings: Float, innerSpringConstant: Float, innerVelConstant: Float, outerSpringConstant: Float, outerVelConstant: Float, outerSpringLength: Float, n_dataParticles: Int) {
        self.r1 = r1
        self.r2 = r2
        self.particleMass = particleMass
        self.fineness = fineness
        self.n_outerSprings = n_outerSprings
        self.innerSpringConstant = innerSpringConstant
        self.innerVelConstant = innerVelConstant
        self.outerSpringConstant = outerSpringConstant
        self.outerVelConstant = outerVelConstant
        self.outerSpringLength = outerSpringLength
        self.n_dataParticles = n_dataParticles
    }
    
    init(r1: Float, r2: Float, fineness: Float, n_outerSprings: Float, innerSpringConstant: Float, innerVelConstant: Float, outerSpringConstant: Float, outerVelConstant: Float, outerSpringLength: Float, n_dataParticles: Int) {
        self.r1 = r1
        self.r2 = r2
        self.particleMass = 0.26 * fineness * fineness
        self.fineness = fineness
        self.n_outerSprings = n_outerSprings
        self.innerSpringConstant = innerSpringConstant
        self.innerVelConstant = innerVelConstant
        self.outerSpringConstant = outerSpringConstant
        self.outerVelConstant = outerVelConstant
        self.outerSpringLength = outerSpringLength
        self.n_dataParticles = n_dataParticles
    }
    
    var description: String {
        return "CircularTrampolineSheet{r1: \(r1), r2: \(r2), fineness: \(fineness), n_outerSprings: \(n_outerSprings), innerSpringConstant: \(innerSpringConstant), innerVelConstant: \(innerVelConstant), outerSpringConstant: \(outerSpringConstant), outerVelConstant: \(outerVelConstant), outerSpringLength: \(outerSpringLength), n_dataParticles: \(n_dataParticles)}"
    }

}



