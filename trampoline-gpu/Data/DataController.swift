
import Cocoa

protocol DataControllerDelegate {
    func resetSim()
    var state: ModelState! { get set }
    var shouldRun: Bool { get set }
}



class DataController: FloatData2 {

    
    var mesh: CircularTrampolineMesh?
    var delegate: DataControllerDelegate?
    var dataParticleIndex: Int?
    var deltaY: Float = 0.2
    private var tasks = [Task]()
    private var dataParticleYMinimum: Float = -6
    private var shouldControlAutonomously: Bool = false
    private var lastDataParticleChange: Float = 0
    private var measurementLatency: Float = 0.2
    private(set) var currentDataParticle: Particle!
    
    private var dataParticleByte: Int? {
        if let index = dataParticleIndex {
            return index * Constants.particleStride
        } else { return nil }
    }
    
    
    enum Task {
        case shouldCollectData
        case shouldMoveUp
        case shouldMoveDown
        case shouldToggleIsLocked
        case shouldEndDataSet
        case shouldSetInnerSpringConstant(value: Float)
        case shouldSetInnerVelConstant(value: Float)
        case shouldSetOuterSpringConstant(value: Float)
        case shouldSetOuterVelConstant(value: Float)
    }
    
    func startAutonomousControl() {
        delegate?.resetSim()
        delegate?.state = .running
        delegate?.shouldRun = true
        lastDataParticleChange = 0
        shouldControlAutonomously = true
        
    }
    
    func stopAutonomousControl() {
        endDataSet()
        shouldControlAutonomously = false
    }
    
    func addTask(_ task: Task) {
        tasks.append(task)
        shouldControlAutonomously = false 
    }
    
    private func fetchCurrentDataParticle() {
        if let mesh = self.mesh, let byte = dataParticleByte {
            let particle: Particle = mesh.particleBuffer.getInstances(atByte: byte)[0]
            self.currentDataParticle = particle
        } else {
            assert(false)
        }
    }
    
    
    func update(dt: Float) {
        fetchCurrentDataParticle()
        
        assert(mesh != nil)
        assert(dataParticleIndex != nil)
        assert(currentDataParticle != nil)
        
 
        if shouldControlAutonomously {
            lastDataParticleChange += dt
            controlAutonomously()
        } else {
            for _ in 0..<tasks.count {
                switch tasks[0] {
                case .shouldCollectData: collectData()
                case .shouldMoveUp: moveDataParticleUp()
                case .shouldMoveDown: moveDataParticleDown()
                case .shouldToggleIsLocked: toggleLock()
                case .shouldEndDataSet: endDataSet()
                case .shouldSetInnerSpringConstant(let value): setInnerSpringConstant(value: value)
                case .shouldSetInnerVelConstant(let value): setInnerVelConstant(value: value)
                case .shouldSetOuterSpringConstant(let value): setOuterSpringConstant(value: value)
                case .shouldSetOuterVelConstant(let value): setOuterVelConstant(value: value)
                }
                tasks.remove(at: 0)
            }
        }
    }
    
    func reset() {
        tasks.removeAll()
    }
    
    
    private func controlAutonomously() {
        if currentDataParticle.isLocked == false { toggleLock() }
        if currentDataParticle.pos.y <= dataParticleYMinimum { collectData(); startAutonomousControl() }
        else if lastDataParticleChange >= measurementLatency { collectData(); moveDataParticleDown(); lastDataParticleChange = 0 }

    }
    
    func collectData() {
        if let particle = currentDataParticle {
            self.addValue(x: particle.pos.y, y: particle.force.y)
        }
    }
    
    func toggleLock() {
        if var particle = currentDataParticle, let mesh = self.mesh, let byte = dataParticleByte {
            particle.isLocked.toggle()
            mesh.particleBuffer.modifyInstances(atByte: byte, newValues: [particle])
        }
    }

    func moveDataParticleUp() {
        if let mesh = self.mesh, let byte = dataParticleByte, var particle = currentDataParticle {
            particle.pos.y += deltaY
            mesh.particleBuffer.modifyInstances(atByte: byte, newValues: [particle])
        }
    }
    
    func moveDataParticleDown() {
        if let mesh = self.mesh, let byte = dataParticleByte, var particle = currentDataParticle {
            particle.pos.y -= deltaY
            mesh.particleBuffer.modifyInstances(atByte: byte, newValues: [particle])
        }
    }
    
    func endDataSet() {
        if let mesh = self.mesh {
            addPairsToFile(basePath: .desktopDirectory, folderPath: "TramplineOutput/", fileName: "1.txt", parameters: mesh.parameters)
        }
    }
    
    private func addPairsToFile(basePath: FileManager.SearchPathDirectory, folderPath: String, fileName: String, parameters: MeshParameters?) {
        var result = DataController.getDescriptionString(parameters: parameters)
        for (x, y) in averagedPairs {
            result += "\n\(x) \(y)"
        }
        print(result)
        result.writeToEndOfFile(basePath: basePath, folderPath: folderPath, fileName: fileName)
    }
    
    private static func getDescriptionString(parameters: MeshParameters?) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .medium
        let dateString = dateFormatter.string(from: Date())
        var result = "\n# \(dateString)"
        if let parameterString = parameters?.description { result += "; " + parameterString }
        return result
    }
    
    func setInnerSpringConstant(value: Float) {
        if let mesh = self.mesh {
            let byte = Constants.constantStride * ConstantsIndex.innerSpringConstantsBuffer.rawValue
            mesh.constantsBuffer.modifyInstances(atByte: byte, newValues: [value])
        }
    }
    
    func setInnerVelConstant(value: Float) {
        if let mesh = self.mesh {
            let byte = Constants.constantStride * ConstantsIndex.innerVelConstantsBuffer.rawValue
            mesh.constantsBuffer.modifyInstances(atByte: byte, newValues: [value])
        }
    }
    
    func setOuterSpringConstant(value: Float) {
        if let mesh = self.mesh {
            let byte = Constants.constantStride * ConstantsIndex.outerSpringConstant.rawValue
            mesh.constantsBuffer.modifyInstances(atByte: byte, newValues: [value])
        }
    }
    
    func setOuterVelConstant(value: Float) {
        if let mesh = self.mesh {
            let byte = Constants.constantStride * ConstantsIndex.outerVelConstant.rawValue
            mesh.constantsBuffer.modifyInstances(atByte: byte, newValues: [value])
        }
    }
    
}


