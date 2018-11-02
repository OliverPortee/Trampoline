




class FloatData2 {
    
    private(set) var values = [Float : [Float]]()
    var averagedPairs: [Float : Float] { return values.mapValues { (yValues) -> Float in return yValues.average } }
    
    func overwriteValueIfNecessary(x: Float, y: [Float]) {
        values[x] = y
    }
    func overwriteValueIfNecessary(x: Float, y: Float) {
        overwriteValueIfNecessary(x: x, y: [y])
    }
    func addValue(x: Float, y: [Float]) {
        if values[x] == nil { values[x] = y }
        else { values[x]!.append(contentsOf: y) }
    }
    func addPairsToFile(basePath: FileManager.SearchPathDirectory, folderPath: String, fileName: String, parameters: MeshParameters?) {
        var result = FloatData2.getDescriptionString(parameters: parameters)
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


extension Collection where Element: Numeric {
    var total: Element { return reduce(0, +) }
}
extension Collection where Element: BinaryInteger {
    var average: Double { return isEmpty ? 0 : Double(total) / Double(count) }
}
extension Collection where Element: BinaryFloatingPoint {
    var average: Element { return isEmpty ? 0 : total / Element(count) }
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
