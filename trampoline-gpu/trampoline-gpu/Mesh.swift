

import MetalKit
import GLKit
import simd




/// Mesh class representing the mesh of the trampoline jumping sheet
class Mesh: Node, NonRealTimeRenderable {
    /// MTLBuffer objects storing particles, springs and constants (spring and vel constants)
    private(set) var particleBuffer: MTLBuffer! // [Particle]
    private(set) var springBuffer: MTLBuffer! // [Spring]
    private(set) var constantsBuffer: MTLBuffer! // [Float]
    /// computed properties which return number of vertices, springs and particles
    var vertexCount: Int { return (springBuffer.length * 2) / StrideConstants.springStride }
    var springCount: Int { return springBuffer.length / StrideConstants.springStride }
    var particleCount: Int { return particleBuffer.length / StrideConstants.particleStride }
    /// background color
    var clearColor: MTLClearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
    /// returns particleArray by converting particleBuffer to array; expensive
    var particleArray: [Particle] { return Array<Particle>(fromMTLBuffer: particleBuffer) }
    /// returns springArray by converting springBuffer to array; expensive
    var springArray: [Spring] { return Array<Spring>(fromMTLBuffer: springBuffer) }
    /// closure which may execute actions when mesh should update
    var updateHandler: (_ dt: Float) -> Void
    /// MTLPrimitiveType
    var primitiveType: MTLPrimitiveType = .line
    /// attached Renderable objects (i. e. blue trampoline edge)
    var otherRendering: [Renderable] = [Renderable]()
    /// MTLRenderPipelineState which connects to particle_vertex_shader and fragment_shader in Shaders.metal
    var renderPipelineState: MTLRenderPipelineState
    /// closure which sets the needed buffers into the renderCommandEncoder
    var setBufferHandlerWhenRendering: (inout MTLRenderCommandEncoder) -> Void {
        return {(_ renderEncoder) in
            renderEncoder.setVertexBuffer(self.particleBuffer, offset: 0, index: BufferIndex.ParticleBufferIndex.rawValue)
            renderEncoder.setVertexBuffer(self.springBuffer, offset: 0, index: BufferIndex.SpringBufferIndex.rawValue)
        }
    }

    /// init function of mesh
    init(device: MTLDevice, projectionMatrix: GLKMatrix4, parentModelMatrix: GLKMatrix4, updateHandler: @escaping (_ dt: Float) -> Void) {
        self.updateHandler = updateHandler
        /// creates required metal objects and connects to shader functions
        let library = device.makeDefaultLibrary()!
        let vertexFuntion = library.makeFunction(name: "particle_vertex_shader")!
        let fragmentFunction = library.makeFunction(name: "fragment_shader")!
        let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
        renderPipelineDescriptor.vertexFunction = vertexFuntion
        renderPipelineDescriptor.fragmentFunction = fragmentFunction
        renderPipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        self.renderPipelineState = try! device.makeRenderPipelineState(descriptor: renderPipelineDescriptor)
        /// initialize Node
        super.init(device: device, projectionMatrix: projectionMatrix, parentModelMatrix: parentModelMatrix)
    }
    /// initiates buffers from arrays
    func initiateBuffers(particles: [Particle], springs: [Spring], constants: [Float]) {
        particleBuffer = device.makeBuffer(bytes: particles, length: particles.count * StrideConstants.particleStride, options: [])!
        springBuffer = device.makeBuffer(bytes: springs, length: springs.count * StrideConstants.springStride, options: [])!
        constantsBuffer = device.makeBuffer(bytes: constants, length: constants.count * StrideConstants.constantStride, options: [])!
    }
    
    
}


/// class to attach other Renderables to BaseRenderable (i. e. it provides data for displaying blue trampoline edge)
class HelperGraphics: Renderable {
    var vertexCount: Int { return self.vertexBuffer.length / StrideConstants.vertexInStride }
    var vertexBuffer: MTLBuffer!
    var setBufferHandlerWhenRendering: (inout MTLRenderCommandEncoder) -> Void {
        return { (renderCommandEncoder) in
            renderCommandEncoder.setVertexBuffer(self.vertexBuffer, offset: 0, index: BufferIndex.OtherRenderingBufferIndex.rawValue)
        }
    }
    var primitiveType: MTLPrimitiveType = .line
    var renderPipelineState: MTLRenderPipelineState
    
    init(fromParameters parameters: MeshParameters, device: MTLDevice, smoothness: Float = 10) {
        var vertexArray = [VertexIn]()
        let radius = parameters.r1
        /// gets vertices in circle
        for angle in stride(from: 0, through: 2 * Float.pi + 1.0 / smoothness, by: 1.0 / smoothness) {
            let x = radius * sin(angle)
            let z = radius * cos(angle)
            let vertexIn = VertexIn(position: float3(x: x, y: 0, z: z), color: float3(0, 0.5, 1))
            vertexArray.append(vertexIn)
            if angle != 0 { vertexArray.append(vertexIn) }
        }
        vertexArray.removeLast()
        /// creates required metal objects and connects to shader functions
        let library = device.makeDefaultLibrary()!
        let vertexFuntion = library.makeFunction(name: "basic_vertex_shader")!
        let fragmentFunction = library.makeFunction(name: "fragment_shader")!
        let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
        renderPipelineDescriptor.vertexFunction = vertexFuntion
        renderPipelineDescriptor.fragmentFunction = fragmentFunction
        renderPipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        self.renderPipelineState = try! device.makeRenderPipelineState(descriptor: renderPipelineDescriptor)
        self.vertexBuffer = device.makeBuffer(bytes: vertexArray, length: vertexArray.count * StrideConstants.vertexInStride, options: [])!
    }
    
}

/// subclass of Mesh which makes the mesh circular
class CircularTrampolineMesh: Mesh {
    
    /// meshParamters
    private(set) var parameters: MeshParameters!
    /// array of dataParticle indices
    private(set) var middleParticleIndices: [Int]!
    /// init function of CircularTrampolineMesh
    override init(device: MTLDevice, projectionMatrix: GLKMatrix4, parentModelMatrix: GLKMatrix4, updateHandler: @escaping (_ dt: Float) -> Void) {
        super.init(device: device, projectionMatrix: projectionMatrix, parentModelMatrix: parentModelMatrix, updateHandler: updateHandler)
    }
    /// method to set parameters
    func initParameters(_ parameters: MeshParameters) {
        self.parameters = parameters
        self.otherRendering.append(HelperGraphics(fromParameters: parameters, device: device))
    }
}


/// extension to CircularTrampolineMesh to initiate particles and springs
extension CircularTrampolineMesh {
    
    /// class to help initializing the model; all HelperParticle instances will be converted to Particle instances
    class HelperParticle: Equatable {
        var pos: float3
        var vel: float3
        var force: float3
        var mass: Float
        var isLocked: Bool
        
        init(pos: float3, vel: float3, force: float3, mass: Float, isLocked: Bool) {
            self.pos = pos
            self.vel = vel
            self.force = force
            self.mass = mass
            self.isLocked = isLocked
        }
        
        convenience init(x: Float, y: Float, z: Float, mass: Float, isLocked: Bool) {
            self.init(pos: float3(x: x, y: y, z: z), vel: float3(0, 0, 0), force: float3(0, 0, 0), mass: mass, isLocked: isLocked)
        }
        
        static func == (lhs: HelperParticle, rhs: HelperParticle) -> Bool {
            return (lhs.pos == rhs.pos) && (lhs.vel == rhs.vel) && (lhs.force == rhs.force) && (lhs.mass == rhs.mass) && (lhs.isLocked == rhs.isLocked)
        }
        
        static var defaultParticle: HelperParticle {
            return HelperParticle(x: 0, y: 0, z: 0, mass: 1, isLocked: true)
        }
        
        var particle: Particle {
            return Particle(pos: self.pos, vel: self.vel, force: self.force, mass: self.mass, isLocked: self.isLocked)
        }
        
    }
    
    
    /// class to help initializing the model; all HelperSpring instances will be converted to Spring instances
    class HelperSpring {
        weak var p1: HelperParticle?
        weak var p2: HelperParticle?
        var springConstant: Float
        var velConstant: Float
        var initialLength: Float
        
        init(p1: HelperParticle, p2: HelperParticle, springConstant: Float, velConstant: Float, initialLength: Float) {
            self.p1 = p1
            self.p2 = p2
            self.springConstant = springConstant
            self.velConstant = velConstant
            self.initialLength = initialLength
        }
        
        convenience init(p1: HelperParticle, p2: HelperParticle, springConstant: Float, velConstant: Float) {
            self.init(p1: p1, p2: p2, springConstant: springConstant, velConstant: velConstant, initialLength: length(p1.pos - p2.pos))
        }
        
        
        var isValidSpring: Bool {
            return p1 != nil && p2 != nil
        }
    }

    /// method to get particleArray, springArray, and constantsArray
    func makeCircularJumpingSheet(parameters: MeshParameters) -> ([Particle], [Spring], [Float]) {
        // helper function
        func indexToDistance(index: Int, n_indices: Int, fineness: Float) -> Float {
            return (Float(index) - ((Float(n_indices - 1)) / 2.0)) * fineness
        }
        /// function to get near particles in an array
        func getNearestHelperParticles(ofPosition pos: float3, withinArray particles: [HelperParticle], count: Int, containingSelf: Bool) -> [HelperParticle] {
            var result = particles.sorted { distance($0.pos, pos) < distance($1.pos, pos) }
            if !containingSelf {
                result.removeAll { $0.pos == pos }
            }
            return Array(result.prefix(count))
        }

        let n_particles: Int = Int(2 * parameters.r1 / parameters.fineness)
        //
        // initializing the quadratic mesh
        print("initializing the quadratic mesh")
        //
        
        var quadraticMesh = [[HelperParticle]]()
        for row in 0..<n_particles {
            var particleList = [HelperParticle]()
            let z = indexToDistance(index: row, n_indices: n_particles, fineness: parameters.fineness)
            for col in 0..<n_particles {
                let x = indexToDistance(index: col, n_indices: n_particles, fineness: parameters.fineness)
                particleList.append(HelperParticle(x: x, y: 0.0, z: z, mass: parameters.particleMass, isLocked: false))
            }
            quadraticMesh.append(particleList)
        }
 
        // initializing the quadratic mesh with reversed alignment
        print("initializing the quadratic mesh with reversed alignment")
        //
        
        var reversedQuadraticMesh = [[HelperParticle]]()
        
        for row in 0..<n_particles {
            var particleList = [HelperParticle]()
            for col in 0..<n_particles {
                particleList.append(quadraticMesh[col][row])
            }
            reversedQuadraticMesh.append(particleList)
        }

        //
        // connecting the particles
        print("connecting the particles")
        //
        
        var connections = [HelperSpring]()
        
        
        for row in 0..<n_particles {
            for col in 0..<n_particles - 1 {
                let p1 = quadraticMesh[row][col]
                let p2 = quadraticMesh[row][col + 1]
                connections.append(HelperSpring(p1: p1, p2: p2, springConstant: parameters.innerSpringConstant, velConstant: parameters.innerVelConstant))
                
            }
        }
        
        for row in 0..<n_particles - 1 {
            for col in 0..<n_particles {
                let p1 = quadraticMesh[row][col]
                let p2 = quadraticMesh[row + 1][col]
                connections.append(HelperSpring(p1: p1, p2: p2, springConstant: parameters.innerSpringConstant, velConstant: parameters.innerVelConstant))
            }
        }
        
        //
        // deleting particles to get circle form
        print("deleting particles to get circle form")
        //
        
        for row in stride(from: n_particles - 1, through: 0, by: -1) {
            for col in stride(from: n_particles - 1, through: 0, by: -1) {
                let particle = quadraticMesh[row][col]
                if length(float2(particle.pos.x, particle.pos.z)) > parameters.r2 {
                    quadraticMesh[row].remove(at: col)
                    
                }
            }
        }
        
        for row in stride(from: n_particles - 1, through: 0, by: -1) {
            for col in stride(from: n_particles - 1, through: 0, by: -1) {
                let particle = reversedQuadraticMesh[row][col]
                if simd_length(simd_float2(particle.pos.x, particle.pos.z)) > parameters.r2 {
                    reversedQuadraticMesh[row].remove(at: col)
                }
            }
        }

        //
        // searching for innerEdgeParticles
        print("searching for innerEdgeParticles")
        //
        
        var innerEdgeParticles = [HelperParticle]()
        
        for particleList in quadraticMesh {
            if particleList.count > 0 {
                innerEdgeParticles.append(particleList.first!)
                innerEdgeParticles.append(particleList.last!)
            }
        }
        
        for particleList in reversedQuadraticMesh {
            if particleList.count > 0 {
                innerEdgeParticles.append(particleList.first!)
                innerEdgeParticles.append(particleList.last!)
            }
        }
        
        innerEdgeParticles = innerEdgeParticles.reduce(into: []) { (result, particle) in
            if !result.contains { $0 == particle } {
                result.append(particle)
            }
        }
   
        //
        // connecting innerEdgeParticles
        print("connecting innerEdgeParticles")
        //
        
        for particle in innerEdgeParticles {
            let nearestParticles = getNearestHelperParticles(ofPosition: particle.pos, withinArray: innerEdgeParticles, count: 2, containingSelf: false)
            for otherParticle in nearestParticles {
                connections.append(HelperSpring(p1: particle, p2: otherParticle, springConstant: parameters.innerSpringConstant, velConstant: parameters.innerVelConstant))
            }
        }

        //
        // initializing outerEdgeParticles
        print("initializing outerEdgeParticles")
        //
        
        var outerEdgeParticles = [HelperParticle]()
        let angleStep = 2.0 * Float.pi / Float(parameters.n_outerSprings)
        for angle in stride(from: 0, to: Float.pi * 2.0, by: angleStep) {
            outerEdgeParticles.append(HelperParticle(x: parameters.r1 * sin(angle), y: 0.0, z: parameters.r1 * cos(angle), mass: parameters.particleMass, isLocked: true))
        }
        for particle in outerEdgeParticles {
            let otherParticle = getNearestHelperParticles(ofPosition: particle.pos, withinArray: innerEdgeParticles, count: 1, containingSelf: false)[0]
            connections.append(HelperSpring(p1: particle, p2: otherParticle, springConstant: parameters.outerSpringConstant, velConstant: parameters.outerVelConstant, initialLength: parameters.outerSpringLength))
        }
        
        //
        // putting all Particles together
        print("putting all particles together")
        //

        var helperParticles = [HelperParticle]()
        
        for particleList in quadraticMesh {
            for particle in particleList {
                helperParticles.append(particle)
            }
        }
        for particle in outerEdgeParticles {
            helperParticles.append(particle)
        }
        
        
        connections.removeAll { $0.isValidSpring == false }
        
        
        /// converting helper class instances into required instances
        var springs = [Spring]()
        let constantsMaxIndex = [ConstantsIndex.innerSpringConstantsBuffer.rawValue, ConstantsIndex.innerVelConstantsBuffer.rawValue, ConstantsIndex.outerSpringConstant.rawValue, ConstantsIndex.outerVelConstant.rawValue].max()!
        var constants = [Float](repeating: 0, count: constantsMaxIndex + 1)
        constants[ConstantsIndex.innerSpringConstantsBuffer.rawValue] = parameters.innerSpringConstant
        constants[ConstantsIndex.innerVelConstantsBuffer.rawValue] = parameters.innerVelConstant
        constants[ConstantsIndex.outerSpringConstant.rawValue] = parameters.outerSpringConstant
        constants[ConstantsIndex.outerVelConstant.rawValue] = parameters.outerVelConstant
        
        /// search for particles to get particle indices in spring class
        for index in connections.indices {
            let spring = connections[index]
            let p1Index = Int32(helperParticles.firstIndex { $0 == spring.p1! }!)
            let p2Index = Int32(helperParticles.firstIndex { $0 == spring.p2! }!)
            let springConstantIndex = Int32(constants.firstIndex { $0 == spring.springConstant }!)
            let velConstantIndex = Int32(constants.firstIndex { $0 == spring.velConstant }!)

            springs.append(Spring(indices: int2(p1Index, p2Index), initialLength: spring.initialLength, constantsIndices: int2(springConstantIndex, velConstantIndex)))
        }
        var particles = [Particle]()
        
        /// searching for dataParticles
        let middleParticles = getNearestHelperParticles(ofPosition: float3(0, 0, 0), withinArray: helperParticles, count: parameters.n_dataParticles, containingSelf: true)
        self.middleParticleIndices = middleParticles.map { (middleParticle) -> Int in
            helperParticles.firstIndex { middleParticle == $0 }!
        }
        
        for hp in helperParticles {
            particles.append(Particle(pos: hp.pos, vel: hp.vel, force: hp.force, mass: hp.mass, isLocked: hp.isLocked))
        }
        
        print("completed makeCircularJumpingSheet")
        
        self.initiateBuffers(particles: particles, springs: springs, constants: constants)
      
        return (particles, springs, constants)
    }
    
}
