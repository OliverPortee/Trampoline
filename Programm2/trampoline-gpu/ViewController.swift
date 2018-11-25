

import Cocoa


/// class to control the program and build a bridge between UI and model
class ViewController: NSViewController {

    /// MTKView for displaying the simulation
    @IBOutlet weak var simView: SimulationView!
    
    /// function called when main content view appears
    override func viewWillAppear() {
        super.viewWillAppear()


        /// set parameters of the mesh
        let parameters = CircularMeshParameters(r1: 3.3 / 2.0,
                                        r2: 1.31,
                                        fineness: 0.03,
                                        n_outerSprings: 72,
                                        innerSpringConstant: 4000,
                                        innerVelConstant: 1,
                                        outerSpringConstant: 2264,
                                        outerVelConstant: 1,
                                        outerSpringLength: 0.17,
                                        n_dataParticles: 9)
        /// set default value of sliders
        heightSlider.floatValue = 0.2
        timeSlider.floatValue = 0.00004
        innerSpringSlider.floatValue = 4000
        innerVelSlider.floatValue = 1
        outerSpringSlider.floatValue = 2264
        outerVelSlider.floatValue = 1
        gravitySlider.floatValue = 0
        simView.desiredVirtualFrameTime = Double(timeSlider.floatValue)
        simView.updater.gravity = 0
        /// give the parameters to simulationView
        simView.setMeshParamters(parameters: parameters)
        /// start loading the model
        simView.loadModelInBackground(parameters: parameters)
    }
    /// connections to UI elements (checkboxe, labels and sliders)
    @IBOutlet weak var realTimeCheckBox: NSButtonCell!
    @IBOutlet weak var heightLbl: NSTextField!
    @IBOutlet weak var forceLbl: NSTextField!
    @IBOutlet weak var timeLbl: NSTextField!
    @IBOutlet weak var heightSlider: NSSlider!
    @IBOutlet weak var timeSlider: NSSlider!
    @IBOutlet weak var innerSpringSlider: NSSlider!
    @IBOutlet weak var innerVelSlider: NSSlider!
    @IBOutlet weak var outerSpringSlider: NSSlider!
    @IBOutlet weak var outerVelSlider: NSSlider!
    @IBOutlet weak var gravitySlider: NSSlider!
    
    /// glue code to respond to events triggered by the user (sliders and checkboxes)
    @IBAction func deltaHeightSliderChanged(_ sender: NSSliderCell) { simView.dataController?.deltaY = sender.floatValue }
    @IBAction func timeSliderChanged(_ sender: NSSliderCell) {
        if realTimeCheckBox.state == .off { simView.desiredVirtualFrameTime = sender.doubleValue }
    }
    @IBAction func realTimeCheckBoxChanged(_ sender: NSButtonCell) {
        if sender.state == .off { simView.desiredVirtualFrameTime = timeSlider.doubleValue }
        else { simView.desiredVirtualFrameTime = nil }
    }
    @IBAction func innerSpringConstantSliderChanged(_ sender: NSSliderCell) {
        simView.dataController?.addTask(.shouldSetInnerSpringConstant(value: sender.floatValue))
        simView?.mesh.parameters.innerSpringConstant = sender.floatValue
    }
    @IBAction func innerVelConstantSliderChanged(_ sender: NSSliderCell) {
        simView.dataController?.addTask(.shouldSetInnerVelConstant(value: sender.floatValue))
        simView?.mesh.parameters.innerVelConstant = sender.floatValue
    }
    @IBAction func outerSpringConstantSliderChanged(_ sender: NSSliderCell) {
        simView.dataController?.addTask(.shouldSetOuterSpringConstant(value: sender.floatValue))
        simView?.mesh.parameters.outerSpringConstant = sender.floatValue
}
    @IBAction func outerVelConstantSliderChanged(_ sender: NSSliderCell) {
        simView.dataController?.addTask(.shouldSetOuterVelConstant(value: sender.floatValue))
        simView?.mesh.parameters.outerVelConstant = sender.floatValue
}
    @IBAction func gravitySliderChanged(_ sender: NSSliderCell) {
        simView.updater.gravity = sender.floatValue
    }

    /// more event processing (buttons)
    @IBAction func startSimBtn(_ sender: NSButton) { simView.shouldRun = true }
    @IBAction func stopSimBtn(_ sender: NSButton) { simView.shouldRun = false }
    @IBAction func resetSimBtn(_ sender: NSButton) { simView.resetSim(resetVirtualTime: true) }
    @IBAction func toggleLockBtn(_ sender: NSButton) { if simView.state == .running { simView.dataController?.addTask(.shouldToggleIsLocked) } }
    @IBAction func upBtn(_ sender: NSButton) { if simView.state == .running { simView.dataController?.addTask(.shouldMoveUp) } }
    @IBAction func downBtn(_ sender: NSButton) { if simView.state == .running { simView.dataController?.addTask(.shouldMoveDown) } }
    @IBAction func collectBtn(_ sender: NSButton) { if simView.state == .running { simView.dataController?.addTask(.shouldCollectData) } }
    @IBAction func endBtn(_ sender: NSButton) { if simView.state == .running { simView.dataController?.addTask(.shouldEndDataSet) } }
    @IBAction func startProgramBtn(_ sender: NSButton) { if simView.state == .running { simView.dataController?.startAutonomousControl() } }
    @IBAction func stopProgram(_ sender: NSButton) { if simView.state == .running { simView.dataController?.stopAutonomousControl() } }
    
    /// functions to update the labels which show height and force of the dataParticles and the time 
    func showHeight(_ value: String) { heightLbl.stringValue = value }
    func showForce(_ value: String) { forceLbl.stringValue = value }
    func showTime(_ value: String) { timeLbl.stringValue = value }
    
    
    
}

