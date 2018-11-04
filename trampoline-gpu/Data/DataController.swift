
import Cocoa

protocol DataControllerDelegate {
    func resetSim(resetVirtualTime: Bool)
    var state: ModelState! { get set }
    var shouldRun: Bool { get set }
}



class DataController: FloatData2 {

    
    var mesh: CircularTrampolineMesh?
    var delegate: DataControllerDelegate?
    var dataParticleIndices: [Int]?
    var deltaY: Float = 0.2
    private var tasks = [Task]()
    private var dataParticleYMinimum: Float = -2
    private var shouldControlAutonomously: Bool = false
    private var lastDataParticleChange: Float = 0
    private var measurementLatency: Float = 0.1
    private(set) var currentDataParticles: [Particle]!
    
    private var dataParticleBytes: [Int]? {
        if let indices = dataParticleIndices {
            return indices.map { $0 * Constants.particleStride }
        } else { return nil }
    }
    var dataParticleForce: float3 { return currentDataParticles.map({ $0.force }).total }
    var dataParticleHeight: Float { return currentDataParticles[0].pos.y }
    
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
        delegate?.resetSim(resetVirtualTime: false)
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
        if let mesh = self.mesh, let bytes = dataParticleBytes {
            self.currentDataParticles = bytes.map{ mesh.particleBuffer.getInstances(atByte: $0)[0] }
        } else {
            assert(false)
        }
    }
    
    
    func update(dt: Float) {
        fetchCurrentDataParticle()
        
        assert(mesh != nil)
        assert(dataParticleIndices != nil)
        assert(currentDataParticles != nil)
 
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
        #warning("take multiple measures")
        if currentDataParticles[0].isLocked == false { toggleLock() }
        if currentDataParticles[0].pos.y <= dataParticleYMinimum { collectData(); startAutonomousControl() }
        else if lastDataParticleChange >= measurementLatency { collectData(); moveDataParticleDown(); lastDataParticleChange = 0 }

    }
    
    func collectData() {
        if let particles = currentDataParticles {
            let pos = particles[0].pos.y
            let force = particles.map { $0.force.y }.total
            self.addValue(x: pos, y: force)
        }
    }
    
    func toggleLock() {
        if currentDataParticles != nil, let mesh = self.mesh, let bytes = dataParticleBytes {
            for index in bytes.indices {
                currentDataParticles![index].isLocked.toggle()
                mesh.particleBuffer.modifyInstances(atByte: bytes[index], newValues: [currentDataParticles[index]])
            }
        }
    }

    func moveDataParticleUp() {
        if currentDataParticles != nil, let mesh = self.mesh, let bytes = dataParticleBytes {
            for index in bytes.indices {
                currentDataParticles[index].pos.y += deltaY
                mesh.particleBuffer.modifyInstances(atByte: bytes[index], newValues: [currentDataParticles[index]])
            }
        }
    }
    
    func moveDataParticleDown() {
        if currentDataParticles != nil, let mesh = self.mesh, let bytes = dataParticleBytes {
            for index in bytes.indices {
                currentDataParticles[index].pos.y -= deltaY
                mesh.particleBuffer.modifyInstances(atByte: bytes[index], newValues: [currentDataParticles[index]])
            }
        }
    }
    
    func endDataSet() {
        if let mesh = self.mesh {
            addPairsToFile(basePath: .desktopDirectory, folderPath: "TramplineOutput/", fileName: "1.txt", parameters: mesh.parameters)
        }
    }
    
    private func addPairsToFile(basePath: FileManager.SearchPathDirectory, folderPath: String, fileName: String, parameters: MeshParameters?) {
        var result = DataController.getDescriptionString(parameters: parameters)
        let (xList, yList) = averagedLists
        for index in xList.indices {
            let line = "\n\(xList[index]) \(yList[index])"
            result += line
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


