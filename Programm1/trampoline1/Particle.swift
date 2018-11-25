import simd

/// class whose objects represent particles
class Particle: SimulationObject, Hashable {
    /// position of particle in cartesian coordinate system
    var pos: simd_float3
    /// velocity of particle
    private(set) var vel: simd_float3
    /// force of particle
    private var force: simd_float3
    /// mass of particle
    private var mass: Float
    /// Bool indicating whether particle is capable of moving and changing position
    private(set) var isLocked = false
    /// connections to other particles (only for initializing the mesh)
    private(set) var connections = [Particle: SpringSort]()
    /// for protocol Hashable to put particles into a Set
    private(set) var hashValue: Int
    /// running index of particle for Hashable protocol
    private static var IDFactory = 0
    /// description for CustomStringConvertible
    var description: String {
        return "Particle( \(pos),\t isLocked: \(isLocked),\t hashValue: \(hashValue) )"
    }
    /// delegate for displaying the particle
    var graphicsDelegate : Graphics?
    /// delegate for sending current pos.y and force
    /// when this delegate is set, the particle will send its pos.y and force every update call
    /// the delegate itself has to decide whether or how to process that data
    var dataDelegate : DoubleData?

    /// init function Particle class, setting vel and force to zero
    init(x: Float, y: Float, z: Float, mass: Float) {
        pos = simd_float3(x: x, y: y, z: z)
        vel = simd_float3(x: 0, y: 0, z: 0)
        force = simd_float3(x: 0, y: 0, z: 0)
        self.mass = mass
        hashValue = Particle.getUniqueID()
    }
    
    /// deinits the particle and, therefore, removes all connections with other particles
    deinit {
        deleteAllConnections()
    }
    
    /// update function which uses euler integration to move particle
    func update(dt: Float) {
        if isLocked == false {
            vel += (force / mass + World.gravity) * dt * dt / 2.0
            pos += vel * dt
        }
        /// send pos.y and force if dataDelegate is set
        dataDelegate?.sendYForceData(y: pos.y, force: force.y)
        /// resets force
        force = simd_float3(x: 0, y: 0, z: 0)
    }
    /// displays the particle
    func display() {
        graphicsDelegate?.drawParticle(pos)
    }
    /// compares two particles on equality
    static func ==(lhs: Particle, rhs: Particle) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
    /// function to apply outer force (used by springs)
    func addForce(_ newForce: simd_float3) {
        force += newForce
    }
    /// locks the particle so it cannot move
    func lock() {
        isLocked = true
    }
    /// unlocks the particle so it con move
    func unlock() {
        isLocked = false
    }
    /// toggles isLocked of particle
    func reverseIsLocked() {
        isLocked = !isLocked
    }
    /// connects two particles to each other
    func addDoubleConnection(with particle: Particle, sort: SpringSort) {
        assert(particle != self)
        connections[particle] = sort
        particle.addSingleConnection(with: self, sort: sort)
    }
    /// connects one particle to another particle
    func addSingleConnection(with particle: Particle, sort: SpringSort) {
        connections[particle] = sort
    }
    /// removes one connection with specific particle
    func deleteConnection(with particle: Particle) {
        connections[particle] = nil
    }
    /// removes all connections with other particles
    func deleteAllConnections() {
        for particle in connections.keys {
            particle.deleteConnection(with: self)
        }
    }
    /// returns new running index of particle
    private static func getUniqueID() -> Int {
        Particle.IDFactory += 1
        return Particle.IDFactory
    }
}
