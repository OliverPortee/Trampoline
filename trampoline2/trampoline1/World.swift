
import simd

/// protocol for all objects that can be drawn, updated and converted to a String
protocol SimulationObject: CustomStringConvertible {
    func update(dt: Float)
    func display()
}

/// class which holds all objects contained in a virtual world
/// class should provide more flexibility when multiple objects should be drawn
class World: SimulationObject {
    /// model of the mesh
    var mesh: Mesh
    static let gravity = simd_float3(x: 0, y: 0, z: 0)
    /// delegate for displaying
    var graphicsDelegate : Graphics? {
        didSet {
            mesh.graphicsDelegate = graphicsDelegate
        }
    }
    /// description for CustomStringConvertible protocol
    var description: String {
        return "\(mesh)"
    }
    
    /// init function of World class which sets the parameters for mesh
    init() {
        /// parameters of mesh
        let fineness : Float = 0.03 // actually 0.002 // 0.2
        let particleMass : Float = 0.26 * fineness * fineness
        mesh = Mesh.makeCircularJumpingSheet(r1: 3.3 / 2.0,
        r2: 2.62 / 2.0,
        particleMass: particleMass,
        fineness: fineness,
        n_outerSprings: 72,
        innerSpringConstant: 4000,
        innerVelConstant: 1,
        outerSpringConstant: 2264,
        outerVelConstant: 1,
        outerSpringLength: 0.17)
    }
    /// update function which should update all subobjects
    func update(dt: Float) {
        mesh.update(dt: dt)
    }
    /// display function which should display all subobjects
    func display() {
        mesh.display()
    }
}


