import simd


/// class for holding model data
class Mesh: SimulationObject {
    /// delegate for displaying
    var graphicsDelegate : Graphics? {
        didSet {
            for spring in springs {
                spring.graphicsDelegate = graphicsDelegate
            }
            for (_, particle) in particles.enumerated() {
                particle.graphicsDelegate = graphicsDelegate
            }
        }
    }
    /// all particles
    var particles = Set<Particle>()
    /// all springs
    var springs = [Spring]()
    /// description for CustomStringConvertible protocol
    var description: String {
        var string = "__________________MESH__________________\n"
        for (index, particle) in particles.enumerated() {
            string += "\(index)\t\(particle)\n"
        }
        string += "\n"
        return string
    }
    
    /// update method which updates all springs and particles
    func update(dt: Float) {
        for spring in springs {
            spring.update(dt: dt)
        }
        for (_, particle) in particles.enumerated() {
            particle.update(dt: dt)
        }
    }
    
    /// display function which displays all springs and the trampoline edge
    func display() {
        for spring in springs {
            spring.display()
        }
//        for (_, particle) in particles.enumerated() {
//            particle.display()
//        }
        graphicsDelegate?.drawTrampolineEdge(middle: simd_float3(x: 0, y: 0, z: 0), radius: 3.3 / 2.0)
    }
    
    /// static function which initializes a circular mesh
    static func makeCircularJumpingSheet(r1: Float,
                                r2: Float,
                                particleMass: Float,
                                fineness: Float,
                                n_outerSprings: Int,
                                innerSpringConstant: Float,
                                innerVelConstant: Float,
                                outerSpringConstant: Float,
                                outerVelConstant: Float,
                                outerSpringLength: Float) -> Mesh {
        
        let n_particles: Int = Int(2 * r1 / fineness)
        //
        // initializing the quadratic mesh
        print("initializing the quadratic mesh")
        //
        
        var quadraticMesh = [[Particle]]()
        for row in 0..<n_particles {
            var particleList = [Particle]()
            let z = indexToDistance(index: row, n_indices: n_particles, fineness: fineness)
            for col in 0..<n_particles {
                let x = indexToDistance(index: col, n_indices: n_particles, fineness: fineness)
                particleList.append(Particle(x: x, y: 0.0, z: z, mass: particleMass))
            }
            quadraticMesh.append(particleList)
        }
        
        
        // initializing the quadratic mesh with reversed alignment
        print("initializing the quadratic mesh with reversed alignment")
        //

        var reversedQuadraticMesh = [[Particle]]()

        for row in 0..<n_particles {
            var particleList = [Particle]()
            for col in 0..<n_particles {
                particleList.append(quadraticMesh[col][row])
            }
            reversedQuadraticMesh.append(particleList)
        }
        
        
        //
        // connecting the particles
        print("connecting the particles")
        //
        
        for row in 0..<n_particles {
            for col in 0..<n_particles - 1 {
                let p0 = quadraticMesh[row][col]
                let p1 = quadraticMesh[row][col + 1]
                p0.addDoubleConnection(with: p1, sort: SpringSort.innerNet)
            }
        }
        
        for row in 0..<n_particles - 1 {
            for col in 0..<n_particles {
                let p0 = quadraticMesh[row][col]
                let p2 = quadraticMesh[row + 1][col]
                p0.addDoubleConnection(with: p2, sort: SpringSort.innerNet)
            }
        }

        //
        // deleting particles to get circle form
        print("deleting particles to get circle form")
        //

        for row in stride(from: n_particles - 1, through: 0, by: -1) {
            for col in stride(from: n_particles - 1, through: 0, by: -1) {
                let particle = quadraticMesh[row][col]
                if simd_length(simd_float2(particle.pos.x, particle.pos.z)) > r2 {
                    quadraticMesh[row].remove(at: col).deleteAllConnections()
                }
            }
        }

        for row in stride(from: n_particles - 1, through: 0, by: -1) {
            for col in stride(from: n_particles - 1, through: 0, by: -1) {
                let particle = reversedQuadraticMesh[row][col]
                if simd_length(simd_float2(particle.pos.x, particle.pos.z)) > r2 {
                    reversedQuadraticMesh[row].remove(at: col)
                }
            }
        }
        

        //
        // searching for innerEdgeParticles
        print("searching for innerEdgeParticles")
        //

        var innerEdgeParticles = Set<Particle>()

        for particleList in quadraticMesh {
            if particleList.count > 0 {
                innerEdgeParticles.insert(particleList.first!)
                innerEdgeParticles.insert(particleList.last!)
            }
        }

        for particleList in reversedQuadraticMesh {
            if particleList.count > 0 {
                innerEdgeParticles.insert(particleList.first!)
                innerEdgeParticles.insert(particleList.last!)
            }
        }

        //
        // connecting innerEdgeParticles
        print("connecting innerEdgeParticles")
        //

        for (_, particle) in innerEdgeParticles.enumerated() {
            let nearestParticles = getNearestParticles(of: particle.pos, within: innerEdgeParticles, number: 2, containingSelf: false)
            for otherParticle in nearestParticles {
                particle.addDoubleConnection(with: otherParticle, sort: SpringSort.innerEdge)
            }
        }


        //
        // initializing outerEdgeParticles
        print("initializing outerEdgeParticles")
        //

        var outerEdgeParticles = [Particle]()
        let angleStep = 2.0 * Double.pi / Double(n_outerSprings)
        for angle in stride(from: 0, to: Double.pi * 2.0, by: angleStep) {
            outerEdgeParticles.append(Particle(x: r1 * Float(sin(angle)), y: 0.0, z: r1 * Float(cos(angle)), mass: particleMass))
        }
        for particle in outerEdgeParticles {
            particle.lock()
            let otherParticle = getNearestParticles(of: particle.pos, within: innerEdgeParticles, number: 1, containingSelf: false)[0]
            particle.addDoubleConnection(with: otherParticle, sort: SpringSort.outerEdge)
        }

        //
        // putting all Particles together
        print("putting all particles together")
        //

        
        let mesh = Mesh()

        
        for particleList in quadraticMesh {
            for particle in particleList {
                mesh.particles.insert(particle)
            }
        }
        for particle in outerEdgeParticles {
            mesh.particles.insert(particle)
        }

        
        
        for (_, particle) in mesh.particles.enumerated() {
            for otherParticle in particle.connections.keys {
                if let sort = particle.connections[otherParticle] {
                    switch sort {
                    case SpringSort.innerNet:
                        mesh.springs.append(Spring(particle, otherParticle, springConstant: innerSpringConstant, velConstant: innerVelConstant, initialLength: fineness))
                    case SpringSort.innerEdge:
                        mesh.springs.append(Spring(particle, otherParticle, springConstant: innerSpringConstant, velConstant: innerVelConstant))
                    case SpringSort.outerEdge:
                        mesh.springs.append(Spring(particle, otherParticle, springConstant: outerSpringConstant, velConstant: outerVelConstant, initialLength: outerSpringLength))
                    }
                }
            }
        }
        

        print("ready")
        let particleArray = Array(mesh.particles)
        print(particleArray.count)
        return mesh
    }
}

/// helper function for converting a index of the row/column into a real distance
func indexToDistance(index: Int, n_indices: Int, fineness: Float) -> Float {
    return (Float(index) - ((Float(n_indices - 1)) / 2.0)) * fineness
}

/// searches in the given set of particles for particles which are near to a given position
func getNearestParticles(of position: simd_float3, within particleSet: Set<Particle>, number: UInt, containingSelf: Bool) -> [Particle] {
    var result = [Particle]()
    for (_, otherParticle) in particleSet.enumerated() {
        if otherParticle.pos == position && containingSelf == false {
            continue
        }
        if result.count < number {
            result.append(otherParticle)
        } else {
            for index in result.indices {
                if simd_distance(otherParticle.pos, position) < simd_distance(result[index].pos, position) {
                    result[index] = otherParticle
                    break
                }
            }
        }
    }
    return result
}



