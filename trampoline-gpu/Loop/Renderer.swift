

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
    /// VideoRecorder which writes creates mp4 files from rendered objects
    private var recorder: VideoRecorder?
    /// time point in video file
    var movieRenderTime: Double?
    /// bool which determines whether VideoRecorder should write frames to file
    var shouldRenderMovie = false
    /// determines location and position of uniform buffer data
    var uniformBufferIndex = 0
    var uniformBufferOffset = 0
    
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
    
    /// starts videoRecorder with size of video and desired path to file
    func startRecording(size: CGSize, url: URL) {
        self.recorder = VideoRecorder(outputURL: url, size: size)
        self.recorder!.startRecording()
        movieRenderTime = 0
    }
    /// stops videoRecorder
    func stopRecording() {
        self.recorder?.endRecording { print("finished movie") }
        self.recorder = nil
        movieRenderTime = nil
    }
    
    /// private function to render a Renderable
    private func renderRenderable(_ renderObject: Renderable, commandBuffer: MTLCommandBuffer, renderPassDescriptor: MTLRenderPassDescriptor) {
        var renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
        renderEncoder.setRenderPipelineState(renderObject.renderPipelineState)
        renderObject.setBufferHandlerWhenRendering(&renderEncoder)
        #warning("TODO: correct in draw to texture and let renderObject do this task")
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
    func renderFrame(renderObject: BaseRenderable, drawable: CAMetalDrawable, renderOnlyOtherRenderObjects: Bool, dt: Double) {
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

        #warning("video recorder does not work yet")
        if let recorder = self.recorder, movieRenderTime != nil {
            movieRenderTime! += dt
            let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: MTLPixelFormat.bgra8Unorm, width: Int(drawable.texture.width), height: Int(drawable.texture.height), mipmapped: false)
            textureDescriptor.usage = .renderTarget
            textureDescriptor.storageMode = .managed
            let newTexture = device.makeTexture(descriptor: textureDescriptor)!
            copyTexture(buffer: commandBuffer, from: drawable.texture, to: newTexture)
            recorder.writeFrame(forTexture: newTexture, time: movieRenderTime!)
        }
        /// shows rendered content
        commandBuffer.present(drawable)
        /// ends rendering process
        commandBuffer.commit()

    }
    
    #warning("remove functions?")
    /// functions for copying textures
    func copyTexture(encoder: MTLBlitCommandEncoder, from: MTLTexture, to: MTLTexture) {
        let width = min(from.width, to.width)
        let height = min(from.height, to.height)
        let depth = min(from.depth, to.depth)
        let size = MTLSize(width: width, height: height, depth: depth)
        encoder.copy(from: from, sourceSlice: 0, sourceLevel: 0, sourceOrigin: MTLOriginMake(0, 0, 0), sourceSize: size,
                     to: to, destinationSlice: 0, destinationLevel: 0, destinationOrigin: MTLOriginMake(0, 0, 0))
    }
    func copyTexture(buffer: MTLCommandBuffer, from: MTLTexture, to: MTLTexture) {
        guard let blit = buffer.makeBlitCommandEncoder() else {
            return
        }
        copyTexture(encoder: blit, from: from, to: to)
        blit.synchronize(resource: to)
        blit.endEncoding()
    }
}













