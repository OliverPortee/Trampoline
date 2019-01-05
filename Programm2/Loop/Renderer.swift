
import Metal
import GLKit

/// size of uniforms
let alignedUniformsSize = (MemoryLayout<Uniforms>.size & ~0xFF) + 0x100
/// determines triple buffering
let maxBuffersInFlight = 3

/// generic class which manages rendering of any renderable object
class Renderer: NSObject {
    /// represents GPU in software
    var device: MTLDevice
    /// stores all commandBuffer and gives them to GPU
    var commandQueue: MTLCommandQueue
    /// buffer which contains uniforms (projection matrix, modelViewMatrix)
    var dynamicUniformBuffer: MTLBuffer
    /// object which manages triple buffering to get more efficiency
    let inFlightSemaphore = DispatchSemaphore(value: maxBuffersInFlight)
    /// pointer to struct of matrizes (see ShaderTypes.h)
    var uniforms: UnsafeMutablePointer<Uniforms>
    /// time point in video file
    var movieRenderTime: Double?
    /// bool which determines whether VideoRecorder should write frames to file
    var shouldRenderMovie = false
    /// determines location and position of uniform buffer data
    var uniformBufferIndex = 0
    var uniformBufferOffset = 0
    
    var recorder: MetalVideoRecorder?
    var recordTime: Double = 0
    
    /**
     Init function of Renderer
     - Parameters:
         - device: device which MeshUpdater should use for GPU computations
         - library: library which contains metal shading language source code and which is used to connect with metal shaders
    */
    init(device: MTLDevice, commandQueue: MTLCommandQueue) {
        self.device = device
        self.commandQueue = commandQueue
        let uniformBufferSize = alignedUniformsSize * maxBuffersInFlight
        /// creates empty buffer for metrizes
        self.dynamicUniformBuffer = self.device.makeBuffer(length: uniformBufferSize, options: [MTLResourceOptions.storageModeShared])!
        uniforms = UnsafeMutableRawPointer(dynamicUniformBuffer.contents()).bindMemory(to: Uniforms.self, capacity: 1)
        /// init of superclass NSObject
        super.init()
    }
    
    func startRecording(url: URL, size: CGSize) {
        self.recorder = MetalVideoRecorder(outputURL: url, size: size)
        recorder?.startRecording()
        self.recordTime = 0.0
    }
    
    func endRecording(_ completionHandler: @escaping () -> ()) {
        if self.recorder != nil { self.recorder?.endRecording(completionHandler) }
    }
    
    /// private function to render a Renderable
    private func renderRenderable(_ renderObject: Renderable, commandBuffer: MTLCommandBuffer, renderPassDescriptor: MTLRenderPassDescriptor) {
        var renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
        renderEncoder.setRenderPipelineState(renderObject.renderPipelineState)
        renderObject.setBufferHandlerWhenRendering(&renderEncoder)
        renderEncoder.setVertexBuffer(dynamicUniformBuffer, offset: 0, index: BufferIndex.UniformsBufferIndex.rawValue)
        renderEncoder.drawPrimitives(type: renderObject.primitiveType, vertexStart: 0, vertexCount: renderObject.vertexCount)
        renderEncoder.endEncoding()
    }
    
    /**
     Function which manages the rendering process of one frame
     - Parameters:
     - renderObject: BaseRenderable which should be rendered
     - drawable: CAMetalDrawable which is a abstract representation of the NSView's display ressource
     - renderOnlyOtherRenderObjects: Bool which determines whether attached renderObjects should be rendered only
     - dt: frametime (i. e. 1 / framerate)
    */
    func renderFrame(renderObject: BaseRenderable, drawable: CAMetalDrawable, renderOnlyOtherRenderObjects: Bool, dt: Double) {//, texture: MTLTexture?) {
        var shouldClear = true
        func getRenderPassDescriptor(drawable: CAMetalDrawable, clearColor: MTLClearColor) -> MTLRenderPassDescriptor {
            if shouldClear {
                let renderPassDescriptor = MTLRenderPassDescriptor()
                renderPassDescriptor.colorAttachments[0].texture = drawable.texture
                renderPassDescriptor.colorAttachments[0].loadAction = .clear
                renderPassDescriptor.colorAttachments[0].clearColor = clearColor
                renderPassDescriptor.colorAttachments[0].storeAction = .store
                shouldClear = false
                return renderPassDescriptor
            } else {
                let renderPassDescriptor = MTLRenderPassDescriptor()
                renderPassDescriptor.colorAttachments[0].texture = drawable.texture
                renderPassDescriptor.colorAttachments[0].storeAction = .store
                return renderPassDescriptor
            }
        }
        
//        _ = inFlightSemaphore.wait(timeout: DispatchTime.distantFuture)
//        let semaphore = inFlightSemaphore
        /// commandBuffer contains all render commands the GPU should execute
        let commandBuffer = self.commandQueue.makeCommandBuffer()!
//        commandBuffer.addCompletedHandler { (_) in semaphore.signal() }

        
        /// sets location and position of uniformBuffer
        uniformBufferIndex = (uniformBufferIndex + 1) % maxBuffersInFlight
        uniformBufferOffset = alignedUniformsSize * uniformBufferIndex
        /// binds uniforms object to uniformBuffer
        uniforms = UnsafeMutableRawPointer(dynamicUniformBuffer.contents() + uniformBufferOffset).bindMemory(to: Uniforms.self, capacity: 1)
        /// sets the matrizes
        uniforms[0].projectionMatrix = renderObject.projectionMatrix
        uniforms[0].modelViewMatrix = renderObject.modelViewMatrix

        if renderOnlyOtherRenderObjects == false {
            /// renders BaseRenderable
            let renderPassDescriptor = getRenderPassDescriptor(drawable: drawable, clearColor: renderObject.clearColor)
            renderRenderable(renderObject, commandBuffer: commandBuffer, renderPassDescriptor: renderPassDescriptor)
        }
        /// renders attached Renderables
        for otherRenderObject in renderObject.otherRendering {
            let renderPassDescriptor = getRenderPassDescriptor(drawable: drawable, clearColor: renderObject.clearColor)
            renderRenderable(otherRenderObject, commandBuffer: commandBuffer, renderPassDescriptor: renderPassDescriptor)
        }
//
//        if let texture = texture {
//            let blit = commandBuffer.makeBlitCommandEncoder()!
//            blit.synchronize(resource: drawable.texture)
//            blit.copy(from: drawable.texture, sourceSlice: 0, sourceLevel: 0, sourceOrigin: MTLOrigin(x: 0, y: 0, z: 0), sourceSize: MTLSize(width: drawable.texture.width, height: drawable.texture.height, depth: drawable.texture.depth), to: texture, destinationSlice: 0, destinationLevel: 0, destinationOrigin: MTLOrigin(x: 0, y: 0, z: 0))
//            blit.endEncoding()
//        }
        if let blitCommandEncoder = commandBuffer.makeBlitCommandEncoder() {
            blitCommandEncoder.synchronize(resource: drawable.texture)
            blitCommandEncoder.endEncoding()
        }
        if let r = self.recorder {
            recordTime += dt
            commandBuffer.addCompletedHandler { (_) in
                r.writeFrame(forTexture: drawable.texture, time: self.recordTime)
            }
        }
        /// shows rendered content
        commandBuffer.present(drawable)
        

        /// ends rendering process
        commandBuffer.commit()
//        commandBuffer.waitUntilCompleted()
        
        

    }
    
}





//extension MTLTexture {
//
//    func bytes() -> UnsafeMutableRawPointer {
//        let width = self.width
//        let height   = self.height
//        let rowBytes = self.width * 4
//        let p = malloc(width * height * 4)
//
//        self.getBytes(p!, bytesPerRow: rowBytes, from: MTLRegionMake2D(0, 0, width, height), mipmapLevel: 0)
//
//        return p!
//    }
//
//    func toImage() -> CGImage? {
//        let p = bytes()
//
//        let pColorSpace = CGColorSpaceCreateDeviceRGB()
//
//        let rawBitmapInfo = CGImageAlphaInfo.noneSkipFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
//        let bitmapInfo:CGBitmapInfo = CGBitmapInfo(rawValue: rawBitmapInfo)
//
//        let selftureSize = self.width * self.height * 4
//        let rowBytes = self.width * 4
//        let releaseMaskImagePixelData: CGDataProviderReleaseDataCallback = { (info: UnsafeMutableRawPointer?, data: UnsafeRawPointer, size: Int) -> () in
//            return
//        }
//        let provider = CGDataProvider(dataInfo: nil, data: p, size: selftureSize, releaseData: releaseMaskImagePixelData)
//        let cgImageRef = CGImage(width: self.width, height: self.height, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: rowBytes, space: pColorSpace, bitmapInfo: bitmapInfo, provider: provider!, decode: nil, shouldInterpolate: true, intent: CGColorRenderingIntent.defaultIntent)!
//
//        return cgImageRef
//    }
//}
