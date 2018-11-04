//
//  ViewController.swift
//  trampoline-gpu
//
//  Created by Oliver Portee on 31.10.18.
//  Copyright © 2018 Oliver Portee. All rights reserved.
//

import Cocoa


/// class to control the program and build a bridge between UI and model
class ViewController: NSViewController {

    /// MTKView for displaying the simulation
    @IBOutlet weak var simView: SimulationView!
    
    /// function called when main content view appears
    override func viewWillAppear() {
        super.viewWillAppear()
        /// set parameters of the mesh
        let parameters = MeshParameters(r1: 3.3 / 2.0,
                                        r2: 2.62 / 2.0,
                                        fineness: 0.05,
                                        n_outerSprings: 72,
                                        innerSpringConstant: 1,
                                        innerVelConstant: 0.5,
                                        outerSpringConstant: 2,
                                        outerVelConstant: 1,
                                        outerSpringLength: 0.17,
                                        n_dataParticles: 13)
   
        /// give the parameters to simulationView
        simView.setMeshParamters(parameters: parameters)
        /// start loading the model
        simView.loadModelInBackground(parameters: parameters)
    }
    /// connections to UI elements (checkboxe and labels)
    @IBOutlet weak var realTimeCheckBox: NSButtonCell!
    @IBOutlet weak var timeSlider: NSSliderCell!
    @IBOutlet weak var heightLbl: NSTextField!
    @IBOutlet weak var forceLbl: NSTextField!
    @IBOutlet weak var timeLbl: NSTextField!

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
    }
    @IBAction func innerVelConstantSliderChanged(_ sender: NSSliderCell) {
        simView.dataController?.addTask(.shouldSetInnerVelConstant(value: sender.floatValue))
    }
    @IBAction func outerSpringConstantSliderChanged(_ sender: NSSliderCell) {
        simView.dataController?.addTask(.shouldSetOuterSpringConstant(value: sender.floatValue))
    }
    @IBAction func outerVelConstantSliderChanged(_ sender: NSSliderCell) {
        simView.dataController?.addTask(.shouldSetOuterVelConstant(value: sender.floatValue))
    }
    @IBAction func gravitySliderChanged(_ sender: NSSliderCell) {
        simView.updater.gravity = sender.floatValue
    }
    @IBAction func renderMovieCheckBoxChanged(_ sender: NSButtonCell) {
        if sender.state == .on {
            var url = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask)[0]
            url.appendPathComponent("movie.mp4")
            simView.renderer.startRecording(size: simView.frame.size, url: url)
        } else {
            simView.renderer.stopRecording()
        }
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

