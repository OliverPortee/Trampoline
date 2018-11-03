




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
    
    func addValue(x: Float, y: Float) {
        addValue(x: x, y: [y])
    }

}






