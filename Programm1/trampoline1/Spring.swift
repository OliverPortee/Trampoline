
import simd

/// enum which contains different spring kinds
enum SpringSort {
    case innerNet, innerEdge, outerEdge
}

/// class which models a spring
class Spring: SimulationObject, CustomStringConvertible {
    /// particles
    private(set) var p1: Particle
    private(set) var p2: Particle
    /// displacement vector between the two particles' positions
    private var dpos: simd_float3 {
        return p2.pos - p1.pos
    }
    /// displacement vector between the two particles' velocities
    private var dvel: simd_float3 {
        return p2.vel - p1.vel
    }
    /// delta l - the length of spring deflection
    private var dlength: Float {
        return simd_length(dpos) - initialLength
    }
    /// calculated force which should be applied on particle p1
    /// (which is the negative of force which should be applied on particle p2)
    private var forceAtP1: simd_float3 {
        if simd_length(dpos) != 0 {
            return simd_normalize(dpos) * springConstant * dlength + velConstant * dvel
        } else {
            return simd_float3(x: 0, y: 0, z: 0)
        }
    }
    /// rigidity of spring
    private var springConstant: Float
    /// amount of damping of the spring
    private var velConstant: Float
    /// normal length
    /// length in which the wpring would not apply any forces on particles p1 and p2
    private var initialLength: Float
    /// description for CustomStringConvertible protocol
    var description: String {
        return "String( \(p1) && \(p2) )"
    }
    /// delegate for displaying
    var graphicsDelegate : Graphics?
    /// init function of Spring class
    init(_ p1: Particle, _ p2: Particle, springConstant: Float, velConstant: Float, initialLength: Float) {
        self.p1 = p1
        self.p2 = p2
        self.springConstant = springConstant
        self.velConstant = velConstant
        self.initialLength = initialLength
    }
    /// convenience init function of Spring class which sets initialLength automatically to current length of dpos
    init(_ p1: Particle, _ p2: Particle, springConstant: Float, velConstant: Float) {
        self.p1 = p1
        self.p2 = p2
        self.springConstant = springConstant
        self.velConstant = velConstant
        self.initialLength = simd_length(p1.pos - p2.pos)
    }
    /// compares two springs on equality
    static func ==(lhs: Spring, rhs: Spring) -> Bool {
        if (lhs.p1 == rhs.p1) && (lhs.p2 == rhs.p2) {
            return true
        } else if (lhs.p1 == rhs.p2) && (lhs.p2 == rhs.p1) {
            return true
        } else {
            return false 
        }
    }
    /// updates the spring
    /// applies forces to p1 and p2
    func update(dt: Float) {
        let force = forceAtP1
        p1.addForce(force)
        p2.addForce(-force)
    }
    /// displays the spring
    func display() {
        graphicsDelegate?.drawSpring(p1.pos, p2.pos)
    }
}
