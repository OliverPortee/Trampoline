
import simd

/// class which holds all dataParticle data (measurements)
class DoubleData {
    /// particle which will be measured
    var dataParticle: Particle? {
        willSet {
            dataParticle?.dataDelegate = nil
        }
        
        didSet {
            dataParticle!.dataDelegate = self
        }
    }
    /// dictionary containing y-force values
    var data = [Float : Float]()
    /// Bool indicating whether it should measure the dataParticle now
    var shouldCollectData = false
    /// function for receiving data (every frame)
    func sendYForceData(y: Float, force: Float) {
        if shouldCollectData {
            data[y] = force
            shouldCollectData = false
            print("collected")
        }
    }
    /// prints data
    func printData() {
        for height in data.keys {
            print(height, data[height]!)
        }
    }
    /// moves dataParticle down
    func dataPartDown() {
        dataParticle?.pos -= simd_float3(x: 0, y: 0.1, z: 0)
        print("particle down")
    }
    /// moves dataParticle up
    func dataPartUp() {
        dataParticle?.pos += simd_float3(x: 0, y: 0.1, z: 0)
        print("particle up")
    }
    /// toggles isLocked of dataParticle
    func lockUnlockDataP() {
        dataParticle?.reverseIsLocked()
        print("reversed")
    }
    
    
}
