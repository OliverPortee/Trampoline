



/// class for storing Floats in a dictionaray: [Float : [Float]]
class FloatData2 {
    
    private(set) var content = [Float : [Float]]()
    
    /// averages values in value dict, returns sorted list of keys and values
    var averagedLists: ([Float], [Float]) {
        let averaged = content.mapValues { (yValues) -> Float in return yValues.average }
        let sortedX = content.keys.sorted()
        return (sortedX, sortedX.map{ averaged[$0]! })
    }
    
    /// adds new data to content and overwrites if key already exists
    func overwriteValueIfNecessary(x: Float, y: [Float]) {
        content[x] = y
    }
    
    /// adds new data to content and overwrites if key already exists
    func overwriteValueIfNecessary(x: Float, y: Float) {
        overwriteValueIfNecessary(x: x, y: [y])
    }
    
    /// adds new kex-value pair to content appending value if key already exists; value is array
    func addValues(x: Float, y: [Float]) {
        if content[x] == nil { content[x] = y }
        else { content[x]!.append(contentsOf: y) }
    }
    
    /// adds new key-value pair to content appending value if key already exists; value is single value
    func addValue(x: Float, y: Float) {
        addValues(x: x, y: [y])
    }

}






