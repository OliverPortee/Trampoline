


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


