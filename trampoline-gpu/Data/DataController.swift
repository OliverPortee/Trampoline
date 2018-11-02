


class DataController: FloatData2 {
    
    
    
    var delegate: CircularTrampolineMesh?
    var dataParticleIndex: Int?
    var deltaY: Float = 0.2
    var tasks = [Tasks]()
    var desiredDataParticlePosition: Float = 0
    var meshSensitivity: Float = 1
    var averageCount = 20
    var dataParticleYMinimum: Float = -5
    var shouldControlAutonomously: Bool = false
    var currentDataParticleIsLocked: Bool = false
    
    var dataParticle: Particle? {
        if let mesh = self.delegate, let index = dataParticleIndex {
            return mesh.particleBuffer.getInstances(atByte: index * Constants.particleStride)[0]
        } else { return nil }
        
    }
    
    var dataParticleByte: Int? {
        if let index = dataParticleIndex {
            return index * Constants.particleStride
        } else { return nil }
    }
    
    
    enum Tasks {
        case shouldCollectData
        case shouldMoveUp
        case shouldMoveDown
        case shouldToggleIsLocked
        case shouldEndDataSet
    }
    
    
    func update() {
        for index in stride(from: tasks.count - 1, through: 0, by: -1) {
            switch tasks[index] {
            case .shouldCollectData: collectData()
            case .shouldMoveUp: moveDataParticleUp()
            case .shouldMoveDown: moveDataParticleDown()
            case .shouldToggleIsLocked: toggleLock()
            case .shouldEndDataSet: endDataSet()
            }
            tasks.remove(at: index)
        }
        
        
        if shouldControlAutonomously {
            if currentDataParticleIsLocked == false { toggleLock() }
            controlAutonomously() }
        
    }
    
    
    func velAverageIsSmallEnough() -> Bool {
        if let mesh = delegate {
            var velVals = [Float]()
            for _ in 0..<averageCount {
                let index = Int.random(in: 0..<mesh.particleCount)
                let particle: Particle = mesh.particleBuffer.getInstances(atByte: index * Constants.particleStride)[0]
                velVals.append(particle.vel.y)
            }
            if velVals.average < meshSensitivity { return true }
        }
        return false
    }
    
    func controlAutonomously() {
        if desiredDataParticlePosition <= dataParticleYMinimum { endDataSet(); return }
        else if velAverageIsSmallEnough() { moveDataParticleDown() }

    }
    
    func collectData() {
        if let particle = dataParticle {
            self.addValue(x: particle.pos.y, y: particle.force.y)
        }
    }
    
    func toggleLock() {
        if var particle = dataParticle, let mesh = self.delegate, let byte = dataParticleByte {
            particle.isLocked.toggle()
            currentDataParticleIsLocked = particle.isLocked
            mesh.particleBuffer.modifyInstances(atByte: byte, newValues: [particle])
        }
    }

    func moveDataParticleUp() {
        if let mesh = self.delegate, let byte = dataParticleByte {
            desiredDataParticlePosition += deltaY
            var dataParticle: Particle = mesh.particleBuffer.getInstances(atByte: byte)[0]
            dataParticle.pos.y = desiredDataParticlePosition
            mesh.particleBuffer.modifyInstances(atByte: byte, newValues: [dataParticle])
        }
    }
    
    func moveDataParticleDown() {
        if let mesh = self.delegate, let byte = dataParticleByte {
            desiredDataParticlePosition -= deltaY
            var dataParticle: Particle = mesh.particleBuffer.getInstances(atByte: byte)[0]
            dataParticle.pos.y = desiredDataParticlePosition
            mesh.particleBuffer.modifyInstances(atByte: byte, newValues: [dataParticle])
        }
    }
    
    func endDataSet() {
        if let mesh = self.delegate {
            addPairsToFile(basePath: .desktopDirectory, folderPath: "TramplineOutput/", fileName: "1.txt", parameters: mesh.parameters)
        }
    }
    
    func addPairsToFile(basePath: FileManager.SearchPathDirectory, folderPath: String, fileName: String, parameters: MeshParameters?) {
        var result = DataController.getDescriptionString(parameters: parameters)
        for (x, y) in averagedPairs {
            result += "\n\(x) \(y)"
        }
        result.writeToEndOfFile(basePath: basePath, folderPath: folderPath, fileName: fileName)
    }
    
    static func getDescriptionString(parameters: MeshParameters?) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .full
        let dateString = dateFormatter.string(from: Date())
        var result = "# \(dateString)"
        if let parameterString = parameters?.description { result += "; " + parameterString }
        return result
    }
    
    
}


extension String {
    @discardableResult func writeToEndOfFile(basePath: FileManager.SearchPathDirectory, folderPath: String, fileName: String) -> Bool {
        let fm = FileManager.default
        guard var baseURL = fm.urls(for: basePath, in: .userDomainMask).first else { return false }
        baseURL.appendPathComponent(folderPath)
        do { try fm.createDirectory(at: baseURL, withIntermediateDirectories: true, attributes: nil) }
        catch { return false }
        let fileURL = baseURL.appendingPathComponent(fileName)
        if !fm.fileExists(atPath: fileURL.path) {
            fm.createFile(atPath: fileURL.path, contents: nil, attributes: nil)
        }
        guard let fileHandle = try? FileHandle(forWritingTo: fileURL) else { return false }
        guard let data = self.data(using: .utf8) else { return false }
        fileHandle.seekToEndOfFile()
        fileHandle.write(data)
        fileHandle.closeFile()
        return true
    }
}
