




class FloatData2 {
    
    private(set) var values = [Float : [Float]]()
    var averagedLists: ([Float], [Float]) {
        let averaged = values.mapValues { (yValues) -> Float in return yValues.average }
        let sortedX = values.keys.sorted()
        return (sortedX, sortedX.map{ averaged[$0]! })
    }
    
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
    
    func addValue(x: Float, y: Float) {
        addValue(x: x, y: [y])
    }

}






