


import Foundation
import Metal
import GLKit


class Node {
    
    
    var device: MTLDevice

    var positionX: Float = 0 { didSet{ updateModelMatrix() } }
    var positionY: Float = 0 { didSet{ updateModelMatrix() } }
    var positionZ: Float = 0 { didSet{ updateModelMatrix() } }
    var rotationX: Float = 0 { didSet{ updateModelMatrix() } }
    var rotationY: Float = 0 { didSet{ updateModelMatrix() } }
    var rotationZ: Float = 0 { didSet{ updateModelMatrix() } }
    var scale: Float = 1 { didSet{ updateModelMatrix() } }
    
    private var modelMatrix: GLKMatrix4
    var parentModelMatrix: float4x4 { didSet{ updateModelMatrix() } }
    var projectionMatrix: float4x4 // protocol Renderable
    var modelViewMatrix: float4x4 // protocol Renderable
    
    
    init(device: MTLDevice, projectionMatrix: GLKMatrix4, parentModelMatrix: GLKMatrix4) {
        self.device = device
        self.modelMatrix = GLKMatrix4Identity
        self.parentModelMatrix = float4x4(glkMatrix: parentModelMatrix)
        self.projectionMatrix = float4x4(glkMatrix: projectionMatrix)
        self.modelViewMatrix = float4x4(glkMatrix: GLKMatrix4Identity)
        updateModelMatrix()
        
    }
    
    func updateModelMatrix() {
        
        modelMatrix = GLKMatrix4Identity
        modelMatrix = GLKMatrix4Translate(modelMatrix, positionX, positionY, positionZ)
        modelMatrix = GLKMatrix4RotateX(modelMatrix, rotationX)
        modelMatrix = GLKMatrix4RotateY(modelMatrix, rotationY)
        modelMatrix = GLKMatrix4RotateZ(modelMatrix, rotationZ)
        modelMatrix = GLKMatrix4Scale(modelMatrix, scale, scale, scale)
        updateModelViewMatrix()
        
    }
    
    
    func updateModelViewMatrix() {
        modelViewMatrix = parentModelMatrix * float4x4(glkMatrix: modelMatrix)
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

