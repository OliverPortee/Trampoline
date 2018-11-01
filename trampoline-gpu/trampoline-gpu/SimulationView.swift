

import Foundation
import MetalKit
import GLKit

class SimulationView: MTKView {
    
    var renderer: Renderer!
    var mesh: Mesh!
    var currentMeshParameters: MeshParameters?
    
    required init(coder: NSCoder) {

        super.init(coder: coder)

        // TODO: set FrameRate
        
        self.device = MTLCreateSystemDefaultDevice()!
        
        self.renderer = Renderer(device: device!, vertexFunctionName: "vertex_shader", fragmentFunctionName: "fragment_shader", primitiveType: .line)
        
        

        
        self.currentMeshParameters = MeshParameters(r1: 3.3 / 2.0,
                                               r2: 2.62 / 2.0,
                                               fineness: 0.05,
                                               n_outerSprings: 72,
                                               innerSpringConstant: 0.01,
                                               innerVelConstant: 0.01,
                                               outerSpringConstant: 0.001,
                                               outerVelConstant: 0.01,
                                               outerSpringLength: 0.17)

        let (particles, springs) = Mesh.makeCircularJumpingSheet(parameters: currentMeshParameters!)
        
        let projectionMatrix = GLKMatrix4MakePerspective(85 * Float.pi / 180, Float(self.bounds.size.width / self.bounds.size.height), 0.01, 100)
        var parentModelMatrix = GLKMatrix4Identity; parentModelMatrix = GLKMatrix4Translate(parentModelMatrix, 0, 0, -3); parentModelMatrix = GLKMatrix4RotateX(parentModelMatrix, 20.0 * Float.pi / 180)
        
        self.mesh = Mesh(device: device!, projectionMatrix: projectionMatrix, parentModelMatrix: parentModelMatrix, particles: particles, springs: springs)

        renderer.renderMovie(size: self.frame.size, seconds: 10, deltaTime: 1.0 / 120.0, renderObject: mesh, url: URL(fileURLWithPath: "movie.mp4"))
        
    }
    
    override func draw(_ dirtyRect: NSRect) {
        
        guard currentDrawable != nil else { return }
        
        renderer.renderFrame(renderObject: self.mesh, drawable: currentDrawable!)
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
