

import XCTest
import GLKit

class DataTest: XCTestCase {

    var data: FloatData2!
    
    override func setUp() {
        data = FloatData2()
        data.addValue(x: 0, y: [1, 3])
        data.addValue(x: 4, y: 3)
        data.addValue(x: 2, y: 1)
        data.overwriteValueIfNecessary(x: 2, y: [3, 5])
        data.overwriteValueIfNecessary(x: 4, y: 0)
        
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testAveragedLists() {
        let averagedLists: ([Float], [Float]) = ([0, 2, 4], [2, 4, 0])
        XCTAssertEqual(data.averagedLists.0, averagedLists.0)
        XCTAssertEqual(data.averagedLists.1, averagedLists.1)
    }

}

extension Float: _StaticDefaultProperty { static var defaultSelf: Float { return 1 } }

class ExtensionTest: XCTestCase {
    
    func testNSRect() {
        let rect = NSRect(x: 2, y: 5, width: 5, height: 25)
        XCTAssertEqual(rect.aspectRatio, 1.0 / 5.0)
    }
    
    func testFloat() {
        var value: Float = 5.945792847529837
        let roundedValue = value.rounded(toPlaces: 4)
        value.round(toPlaces: 3)
        XCTAssertEqual(roundedValue, 5.9458)
        XCTAssertEqual(value, 5.946)
    }
    
    func testMatrizes() {
        let initialMatrix = float4x4(float4(0, 1, 2, 3), float4(4, 5, 6, 7), float4(8, 9, 10, 11), float4(12, 13, 14, 15))
        let glkMatrix = GLKMatrix4(float4x4matrix: initialMatrix)
        let newMatrix = float4x4(glkMatrix: glkMatrix)
        XCTAssertEqual(initialMatrix, newMatrix)
    }
    
    func testBufferArrayConversion() {
        var initialArray = [Float](repeating: 1, count: 10).enumerated().map{ Float($0.offset) }
        let device = MTLCreateSystemDefaultDevice()!
        let length = initialArray.count * MemoryLayout.stride(ofValue: initialArray[0])
        let buffer = device.makeBuffer(bytes: initialArray, length: length, options: [])!
        XCTAssertEqual(buffer.getInstances(atByte: 0, countOfInstances: 4) as [Float], [0, 1, 2, 3])
        buffer.modifyInstances(atByte: 0, newValues: [3, 2, 1] as [Float])
        initialArray[0] = 3
        initialArray[1] = 2
        initialArray[2] = 1
        let newArray = Array<Float>(fromMTLBuffer: buffer)
        XCTAssertEqual(initialArray, newArray)
    }
    
    func testArrayTotal() {
        let intArray = [4, 5, 6]
        XCTAssertEqual(intArray.total, 15)
        XCTAssertEqual(intArray.average, 5)
        let floatArray: [Float] = [5.2, 5.8]
        XCTAssertEqual(floatArray.total, 11.0)
        XCTAssertEqual(floatArray.average, 5.5)
        let emptyArray: [Float] = []
        XCTAssertEqual(emptyArray.total, 0.0)
        XCTAssertEqual(emptyArray.average, 0.0)
        let vecArray = [float3(4, 5, 6), float3(-4, -5, -6)]
        XCTAssertEqual(vecArray.total, float3(0, 0, 0))
        let emptyVecArray: float3 = []
        XCTAssertEqual(emptyVecArray.total, float3(0, 0, 0))
    }
    
    
    
}

