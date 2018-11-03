

import Foundation
import MetalKit
import GLKit

class SimulationView: MTKView {
    
    var renderer: Renderer!
    var updater: MeshUpdater!
    var mesh: CircularTrampolineMesh!
    var currentMeshParameters: MeshParameters?
    var lastFrameTime: NSDate!
    var mouseDragSensitivity: Float = 0.004
    var dataController: DataController?
    

    enum State {
        case loadingModel, notRunning, running
    }
    var state: State!
    
    
    required init(coder: NSCoder) {


        super.init(coder: coder)

        // TODO: set FrameRate
        
        
        self.state = .loadingModel

            self.currentMeshParameters = MeshParameters(r1: 3.3 / 2.0,
                                                        r2: 2.62 / 2.0,
                                                        fineness: 0.02,
                                                        n_outerSprings: 72,
                                                        innerSpringConstant: 10,
                                                        innerVelConstant: 0.5,
                                                        outerSpringConstant: 2,
                                                        outerVelConstant: 1,
                                                        outerSpringLength: 0.17)
            
        
        let projectionMatrix = GLKMatrix4MakePerspective(85 * Float.pi / 180, self.frame.aspectRatio, 0.01, 100)
        var parentModelMatrix = GLKMatrix4Identity; parentModelMatrix = GLKMatrix4Translate(parentModelMatrix, 0, 0, -3); parentModelMatrix = GLKMatrix4RotateX(parentModelMatrix, 20.0 * Float.pi / 180)
        
        self.device = MTLCreateSystemDefaultDevice()!
        let commandQueue = self.device!.makeCommandQueue()!
    
        self.renderer = Renderer(device: self.device!, commandQueue: commandQueue, vertexFunctionName: "particle_vertex_shader", fragmentFunctionName: "fragment_shader", primitiveType: .line, otherFragmentFunctionName: "basic_vertex_shader")
        self.updater = MeshUpdater(device: self.device!, commandQueue: commandQueue, springFunctionName: "spring_update", particleFunctionName: "particle_update")
        
        
        DispatchQueue.global(qos: .userInitiated).async {

            self.mesh = CircularTrampolineMesh(device: self.device!, projectionMatrix: projectionMatrix, parentModelMatrix: parentModelMatrix, parameters: self.currentMeshParameters!, updateHandler: {(_ dt: Float) in self.updater.update(dt: dt, mesh: self.mesh)})
            self.dataController = DataController()
            self.dataController!.dataParticleIndex = self.mesh.middleParticleIndex
            self.dataController!.delegate = self.mesh
            
            
            self.lastFrameTime = NSDate()
            
            self.state = .notRunning
        }
        

//        renderer.renderMovie(size: self.frame.size, seconds: 10, deltaTime: 1.0 / 120.0, renderObject: mesh, url: URL(fileURLWithPath: "movie.mp4"))
       
    }
    
    override func draw(_ dirtyRect: NSRect) {
        let dt = Float(-lastFrameTime.timeIntervalSinceNow)
        self.lastFrameTime = NSDate()
        guard currentDrawable != nil else { return }
        self.mesh.updateHandler(dt)
        renderer.renderFrame(renderObject: self.mesh, drawable: currentDrawable!)
        
        
        
    }
    
    
    override func mouseDragged(with event: NSEvent) {
        mesh.rotationX += (Float(event.deltaY) * mouseDragSensitivity)
        mesh.rotationY += (Float(event.deltaX) * mouseDragSensitivity)
        mesh.rotationZ += (Float(event.deltaZ) * mouseDragSensitivity)
    }
    

    override func resize(withOldSuperviewSize oldSize: NSSize) {
        mesh.projectionMatrix = float4x4(glkMatrix: GLKMatrix4MakePerspective(85 * Float.pi / 180, frame.aspectRatio, 0.01, 100))
    }
    
    
    
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
    
    init(r1: Float, r2: Float, particleMass: Float, fineness: Float, n_outerSprings: Float, innerSpringConstant: Float, innerVelConstant: Float, outerSpringConstant: Float, outerVelConstant: Float, outerSpringLength: Float) {
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
    }
    
    init(r1: Float, r2: Float, fineness: Float, n_outerSprings: Float, innerSpringConstant: Float, innerVelConstant: Float, outerSpringConstant: Float, outerVelConstant: Float, outerSpringLength: Float) {
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
    }
    
    var description: String {
        return "CircularTrampolineSheet{r1: \(r1), r2: \(r2), fineness: \(fineness), n_outerSprings: \(n_outerSprings), innerSpringConstant: \(innerSpringConstant), innerVelConstant: \(innerVelConstant), outerSpringConstant: \(outerSpringConstant), outerVelConstant: \(outerVelConstant), outerSpringLength: \(outerSpringLength)}"
    }

}



extension NSRect {
    var aspectRatio: Float { return Float(self.width / self.height) }
}
