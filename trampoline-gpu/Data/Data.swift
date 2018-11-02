




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


extension Collection where Element: Numeric {
    var total: Element { return reduce(0, +) }
}
extension Collection where Element: BinaryInteger {
    var average: Double { return isEmpty ? 0 : Double(total) / Double(count) }
}
extension Collection where Element: BinaryFloatingPoint {
    var average: Element { return isEmpty ? 0 : total / Element(count) }
}



