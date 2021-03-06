
import Cocoa

/// class which builds a bridge between Model and UI;
/// responsible for measuring height and force of data particles;
/// subclasses FloatData2 which stores measured data
class DataController: FloatData2 {
    /// model of the simulation
    var mesh: CircularTrampolineMesh?
    /// delegate (i. e. SimulationView) for receiving events like resetting model
    var delegate: DataControllerDelegate?

    /// buttons "Up" and "Down" change the height of data particles by deltaY
    var deltaY: Float = 0.2
    /// array of outstanding tasks the dataController is supposed to do (e. g. move dataParticles, see enum Tasks); like a command buffer
    private var tasks = [Task]()
    /// when measurementProgram (autonomous control) moves dataParticles bejond dataParticleYMinimum, the model is reset
    private var dataParticleYMinimum: Float = -3
    /// enum indicating whether dataController should measure height and force of dataParticles autonomously
    private var measurementState: MeasruementState = MeasruementState.noMeasurement { didSet{ lastStateChange = 0 } }
    /// time since state has been changed the last time
    private var lastStateChange: Float = 0
    /// length of measurement time in autonomous control
    private var measurementLatency: Float = 0.1
    /// length of waiting time in autonomous control
    private var waitingLatency: Float = 0.1
    /// array of representatives of dataParticles; only valid for one frame (after that, they are reinitialized again)
    private(set) var currentDataParticles: [Particle]!
    /// indices of data particles in particleArray of model mesh
    var dataParticleIndices: [Int]?
    /// returns array of bytes which represent the byte positions of the dataParticles in the particleBuffer
    private var dataParticleBytes: [Int]? {
        if let indices = dataParticleIndices {
            return indices.map { $0 * StrideConstants.particleStride }
        } else { return nil }
    }
    /// returns force of dataParticles
    var dataParticleForce: float3 { return currentDataParticles.map({ $0.force }).total }
    /// returns height of dataParticles (y value of pos vector)
    var dataParticleHeight: Float { return currentDataParticles[0].pos.y }
    /// enum which represents all possible tasks the dataController can do
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
    /// starts autonomous measurement program
    func startAutonomousControl() {
        delegate?.resetSim(resetVirtualTime: false)
        delegate?.state = .running
        delegate?.shouldRun = true
        lastStateChange = 0
        measurementState = .shouldMeasure
        
    }
    /// stops autonomous measurement program
    func stopAutonomousControl() {
        endDataSet()
        measurementState = .noMeasurement
    }
    /// add a task (see enum Task)
    func addTask(_ task: Task) {
        tasks.append(task)
    }
    /// updates currentDataParticles for this frame
    private func fetchCurrentDataParticle() {
        if let mesh = self.mesh, let bytes = dataParticleBytes {
            self.currentDataParticles = bytes.map{ mesh.particleBuffer.getInstances(atByte: $0)[0] }
        } else {
            assert(false)
        }
    }
    /// called only by updater between updateSprings and updateParticles; manages outstanding tasks
    func update(dt: Float) {
        fetchCurrentDataParticle()
        
        assert(mesh != nil)
        assert(dataParticleIndices != nil)
        assert(currentDataParticles != nil)
 
        if measurementState != .noMeasurement {
            lastStateChange += dt
            controlAutonomously()
            tasks.removeAll()
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
    
    
    /// resets dataController
    func reset() {
        tasks.removeAll()
    }
    
    /// manages autonomous control:
    /// locks dataParticles if not already locked, moves the dataParticles down when time has come, resets model
    private func controlAutonomously() {
        switch measurementState {
        case .noMeasurement: return
        case .isWaiting:
            if lastStateChange > waitingLatency { measurementState = .shouldMeasure }
        case .shouldMeasure:
            if lastStateChange > measurementLatency { measurementState = .isWaiting; moveDataParticleDown() }
            if currentDataParticles[0].isLocked == false { toggleLock() }
            collectData()
            if currentDataParticles[0].pos.y <= dataParticleYMinimum { startAutonomousControl() }
        }
    }
    /// saves current height and force of dataParticles
    func collectData() {
        if let particles = currentDataParticles {
            let pos = particles[0].pos.y
            let force = particles.map { $0.force.y }.total
            self.addValue(x: pos, y: force)
        }
    }
    /// toggles isLocked of dataParticles
    func toggleLock() {
        if currentDataParticles != nil, let mesh = self.mesh, let bytes = dataParticleBytes {
            for index in bytes.indices {
                currentDataParticles![index].isLocked.toggle()
                mesh.particleBuffer.modifyInstances(atByte: bytes[index], newValues: [currentDataParticles[index]])
            }
        }
    }
    /// movesDataParticles up by deltaY
    func moveDataParticleUp() {
        if currentDataParticles != nil, let mesh = self.mesh, let bytes = dataParticleBytes {
            for index in bytes.indices {
                currentDataParticles[index].pos.y += deltaY
                currentDataParticles[index].lastPos.y += deltaY
                mesh.particleBuffer.modifyInstances(atByte: bytes[index], newValues: [currentDataParticles[index]])
            }
        }
    }
    /// movesDataParticles down by deltaY
    func moveDataParticleDown() {
        if currentDataParticles != nil, let mesh = self.mesh, let bytes = dataParticleBytes {
            for index in bytes.indices {
                currentDataParticles[index].pos.y -= deltaY
                currentDataParticles[index].lastPos.y -= deltaY
                mesh.particleBuffer.modifyInstances(atByte: bytes[index], newValues: [currentDataParticles[index]])
            }
        }
    }
    /// called when measured data should be saved
    func endDataSet() {
        if let mesh = self.mesh {
            addPairsToFile(basePath: .desktopDirectory, folderPath: "TramplineOutput/", fileName: "2.txt", parameters: mesh.parameters)
        }
    }
    /// writes data to file
    private func addPairsToFile(basePath: FileManager.SearchPathDirectory, folderPath: String, fileName: String, parameters: CircularMeshParameters?) {
        var result = DataController.getDescriptionString(parameters: parameters)
        let (xList, yList) = averagedLists
        for index in xList.indices {
            let line = "\n\(xList[index]) \(yList[index])"
            result += line
        }
        print(result)
        result.writeToEndOfFile(basePath: basePath, folderPath: folderPath, fileName: fileName)
    }
    /// returns description of dataSet (date, time, meshParameters)
    private static func getDescriptionString(parameters: CircularMeshParameters?) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .medium
        let dateString = dateFormatter.string(from: Date())
        var result = "\n# \(dateString)"
        if let parameterString = parameters?.description { result += "; " + parameterString }
        return result
    }
    /// changes value of innerSpringConstant in constantsBuffer of mesh
    func setInnerSpringConstant(value: Float) {
        if let mesh = self.mesh {
            let byte = StrideConstants.constantStride * ConstantsIndex.innerSpringConstantsBuffer.rawValue
            mesh.constantsBuffer.modifyInstances(atByte: byte, newValues: [value])
        }
    }
    /// changes value of innerVelConstant in constantsBuffer of mesh
    func setInnerVelConstant(value: Float) {
        if let mesh = self.mesh {
            let byte = StrideConstants.constantStride * ConstantsIndex.innerVelConstantsBuffer.rawValue
            mesh.constantsBuffer.modifyInstances(atByte: byte, newValues: [value])
        }
    }
    /// changes value of outerSpringConstant in constantsBuffer of mesh
    func setOuterSpringConstant(value: Float) {
        if let mesh = self.mesh {
            let byte = StrideConstants.constantStride * ConstantsIndex.outerSpringConstant.rawValue
            mesh.constantsBuffer.modifyInstances(atByte: byte, newValues: [value])
        }
    }
    /// changes value of outerVelConstant in constantsBuffer of mesh
    func setOuterVelConstant(value: Float) {
        if let mesh = self.mesh {
            let byte = StrideConstants.constantStride * ConstantsIndex.outerVelConstant.rawValue
            mesh.constantsBuffer.modifyInstances(atByte: byte, newValues: [value])
        }
    }
    
}


