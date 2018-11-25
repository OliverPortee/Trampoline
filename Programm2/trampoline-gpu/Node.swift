


import Foundation
import Metal
import GLKit


/// general class to manages matrizes of a object
class Node {
    
    var device: MTLDevice
    /// vars to store position and rotation and to update the model matrix when values change
    var positionX: Float = 0 { didSet{ updateModelMatrix() } }
    var positionY: Float = 0 { didSet{ updateModelMatrix() } }
    var positionZ: Float = 0 { didSet{ updateModelMatrix() } }
    var rotationX: Float = 0 { didSet{ updateModelMatrix() } }
    var rotationY: Float = 0 { didSet{ updateModelMatrix() } }
    var rotationZ: Float = 0 { didSet{ updateModelMatrix() } }
    var scale: Float = 1 { didSet{ updateModelMatrix() } }
    
    /// matrix representing transformations within the model's local coordinate system
    private var modelMatrix: GLKMatrix4
    /// matrix representing transformations from generell coordinate system to model system
    var parentModelMatrix: float4x4 { didSet{ updateModelMatrix() } }
    /// projection matrix representing the perspective projection by describing how the space is pushed into a frustum
    var projectionMatrix: float4x4
    /// model view matrix combining transformations from model matrix and parent model matrix
    var modelViewMatrix: float4x4
    
    // init function of the Node
    init(device: MTLDevice, projectionMatrix: GLKMatrix4, parentModelMatrix: GLKMatrix4) {
        self.device = device
        self.modelMatrix = GLKMatrix4Identity
        self.parentModelMatrix = float4x4(glkMatrix: parentModelMatrix)
        self.projectionMatrix = float4x4(glkMatrix: projectionMatrix)
        self.modelViewMatrix = float4x4(glkMatrix: GLKMatrix4Identity)
        updateModelMatrix()
    }
    
    /// updates the model matrix and calls updateModelViewMatrix at the end
    func updateModelMatrix() {
        
        modelMatrix = GLKMatrix4Identity
        modelMatrix = GLKMatrix4Translate(modelMatrix, positionX, positionY, positionZ)
        modelMatrix = GLKMatrix4RotateX(modelMatrix, rotationX)
        modelMatrix = GLKMatrix4RotateY(modelMatrix, rotationY)
        modelMatrix = GLKMatrix4RotateZ(modelMatrix, rotationZ)
        modelMatrix = GLKMatrix4Scale(modelMatrix, scale, scale, scale)
        updateModelViewMatrix()
        
    }
    
    // udpates modelViewMatrix
    func updateModelViewMatrix() {
        modelViewMatrix = parentModelMatrix * float4x4(glkMatrix: modelMatrix)
    }

}


