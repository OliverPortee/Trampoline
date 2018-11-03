//
//  Extensions.swift
//  trampoline-gpu
//
//  Created by Oliver Portee on 03.11.18.
//  Copyright © 2018 Oliver Portee. All rights reserved.
//

import Foundation
import GLKit



public extension NSRect {
    var aspectRatio: Float { return Float(self.width / self.height) }
}

extension Float {
    
    func rounded(toPlaces places: Int) -> Float {
        assert(places >= 0)
        let divisor = pow(10.0, Float(places))
        return (self * divisor).rounded() / divisor
    }
    
    mutating func round(toPlaces places: Int) {
        assert(places >= 0)
        let divisor = pow(10.0, Float(places))
        self = (self * divisor).rounded() / divisor
    }
}


extension float4x4 {
    init(glkMatrix: GLKMatrix4) {
        self.init(columns: (float4(x: glkMatrix.m00, y: glkMatrix.m01, z: glkMatrix.m02, w: glkMatrix.m03),
                            float4(x: glkMatrix.m10, y: glkMatrix.m11, z: glkMatrix.m12, w: glkMatrix.m13),
                            float4(x: glkMatrix.m20, y: glkMatrix.m21, z: glkMatrix.m22, w: glkMatrix.m23),
                            float4(x: glkMatrix.m30, y: glkMatrix.m31, z: glkMatrix.m32, w: glkMatrix.m33)))
    }
}


extension GLKMatrix4 {
    init(float4x4matrix matrix: float4x4) {
        self.init(m: (matrix[0, 0], matrix[0, 1], matrix[0, 2], matrix[0, 3],
                      matrix[1, 0], matrix[1, 1], matrix[1, 2], matrix[1, 3],
                      matrix[2, 0], matrix[2, 1], matrix[2, 2], matrix[2, 3],
                      matrix[3, 0], matrix[3, 1], matrix[3, 2], matrix[3, 3]))
    }
}

protocol _StaticDefaultProperty { static var defaultSelf: Self { get } }

extension Array where Element: _StaticDefaultProperty {
    init(fromMTLBuffer buffer: MTLBuffer) {
        assert(buffer.length % MemoryLayout<Element>.stride == 0)
        let countOfInstances = buffer.length / MemoryLayout<Element>.stride
        self.init(repeating: Element.defaultSelf, count: countOfInstances)
        let result = buffer.contents().bindMemory(to: Element.self, capacity: countOfInstances)
        for index in 0..<countOfInstances { self[index] = result[index] }
    }
}

extension MTLBuffer {
    func getInstances<T>(atByte byte: Int, countOfInstances: Int = 1) -> [T] {
        assert(byte % MemoryLayout<T>.stride == 0)
        let result = contents().advanced(by: byte).bindMemory(to: T.self, capacity: countOfInstances)
        return Array(UnsafeBufferPointer(start: result, count: countOfInstances))
    }
    
    func modifyInstances<T>(atByte byte: Int, newValues: [T]) {
        let tStride = MemoryLayout<T>.stride
        let count = newValues.count
        assert(byte % tStride == 0)
        assert(byte + tStride * count <= length)
        
        contents().advanced(by: byte).copyMemory(from: newValues, byteCount: tStride * count)
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
        catch let error { print(error); return false }
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
