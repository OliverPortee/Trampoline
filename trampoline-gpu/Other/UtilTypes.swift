

import Metal

/// Particle struct used for representing hubs in the mesh model
struct Particle: _StaticDefaultProperty {
    /// position of particle in an cartesian coordinate system
    var pos: float3
    /// velocity of particle in an cartesian coordinate system
    var vel: float3
    /// force appied to particle in an cartesion coordinate system
    var force: float3
    /// inertial of the particle
    var mass: Float
    /// bool indicating whether particle is capable to move; if false: the particle ingnores all forces and velocity
    var isLocked: Bool
    /// init of Particle
    init(pos: float3, vel: float3, force: float3, mass: Float, isLocked: Bool) {
        self.pos = pos
        self.vel = vel
        self.force = force
        self.mass = mass
        self.isLocked = isLocked
    }
    /// convenience init to initialize force and velocity automatically to zero vector; default value of isLocked is false
    init(x: Float, y: Float, z: Float, mass: Float, isLocked: Bool = false) {
        self.init(pos: float3(x: x, y: y, z: z), vel: float3(x: 0, y: 0, z: 0), force: float3(x: 0, y: 0, z: 0), mass: mass, isLocked: isLocked)
    }
    /// static default value to conform to _StaticDefaultProperty protocol
    static var defaultSelf: Particle { return Particle(x: 0, y: 0, z: 0, mass: 1) }
}

/// Spring struct used for representing connections between particles in the mesh model
struct Spring: _StaticDefaultProperty {
    /// indices to connected particles in particleArray
    var indices: int2
    /// starting length of the spring; if the vector between connected particles has the length of initial length, the spring won't apply any force to the particles
    var initialLength: Float
    /// indices to springConstant (x) and velConstant (y) in constantsArray
    var constantsIndices: int2
    /// static default value to conform to _StaticDefaultProperty protocol
    static var defaultSelf: Spring { return Spring(indices: int2(0, 1), initialLength: 1, constantsIndices: int2(0, 2)) }
    
}

/// VertexIn struct representing a vertex in basic_vertex_shader function in Shaders.metal
struct VertexIn {
    var position: float3
    var color: float3
}

/// Constants struct to store MemoryLayout strides (needed space of the Type in the memory)
struct StrideConstants {
    /// stride of Particle type
    static let particleStride = MemoryLayout<Particle>.stride
    /// stride of Spring type
    static let springStride = MemoryLayout<Spring>.stride
    /// stride of VertexIn type
    static let vertexInStride = MemoryLayout<VertexIn>.stride
    /// stride of Float type
    static let constantStride = MemoryLayout<Float>.stride
}


/// protocol for delegate of DataController to receive events like resetting the simulation
/// and to get properties (state of the simulation and shouldRun which indicate wheter simulation runs)
protocol DataControllerDelegate {
    func resetSim(resetVirtualTime: Bool)
    var state: ModelState! { get set }
    var shouldRun: Bool { get set }
}

/// protocol which defines a basic interface of objects which can be rendered by the Renderer
protocol Renderable {
    /// number of vertices
    var vertexCount: Int { get }
    /// closure to set buffers in the Renderer
    var setBufferHandlerWhenRendering: ( inout MTLRenderCommandEncoder) -> Void { get }
    /// MTLPrimitiveType (.line, .lineStrip, .point, .triangle, .triangleStrip) determines in which way the vertices are drawn
    var primitiveType: MTLPrimitiveType { get }
    /// MTLRenderPipelineState to connect to rendering function in Shaders.metal
    var renderPipelineState: MTLRenderPipelineState { get }
}

/// protocol extending Renderable; defines properties of an object which has other rendering objects (Renderable) attached to it
protocol BaseRenderable: Renderable {
    /// color to clear the texture of the drawable with
    var clearColor: MTLClearColor { get set }
    var projectionMatrix: float4x4 { get set }
    var modelViewMatrix: float4x4 { get }
    var otherRendering: [Renderable] { get }
}

/// protocol for objects which have update handler closure
protocol Updatable {
    var updateHandler: (_ dt: Float) -> Void { get set }
}

typealias NonRealTimeRenderable = BaseRenderable & Updatable


/// enum ModelState to indicate which status the model has
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
