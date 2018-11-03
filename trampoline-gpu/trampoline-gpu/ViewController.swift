//
//  ViewController.swift
//  trampoline-gpu
//
//  Created by Oliver Portee on 31.10.18.
//  Copyright © 2018 Oliver Portee. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    
    @IBOutlet weak var simView: SimulationView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        let parameters = MeshParameters(r1: 3.3 / 2.0,
                                        r2: 2.62 / 2.0,
                                        fineness: 0.05,
                                        n_outerSprings: 72,
                                        innerSpringConstant: 1,
                                        innerVelConstant: 0.5,
                                        outerSpringConstant: 2,
                                        outerVelConstant: 1,
                                        outerSpringLength: 0.17)
   
        
        simView.setMeshParamters(parameters: parameters)
        simView.loadModelInBackground(parameters: parameters)
    }
    
    @IBOutlet weak var realTimeCheckBox: NSButtonCell!
    @IBOutlet weak var timeSlider: NSSliderCell!
    @IBOutlet weak var heightLbl: NSTextField!
    @IBOutlet weak var forceLbl: NSTextField!
    
    
    
    @IBAction func deltaHeightSliderChanged(_ sender: NSSliderCell) { simView.dataController?.deltaY = sender.floatValue }
    @IBAction func timeSliderChanged(_ sender: NSSliderCell) {
        if realTimeCheckBox.state == .off { simView.desiredVirtualTime = sender.floatValue }
    }
    @IBAction func realTimeCheckBoxChanged(_ sender: NSButtonCell) {
        if sender.state == .off { simView.desiredVirtualTime = timeSlider.floatValue }
        else { simView.desiredVirtualTime = nil }
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
    
    @IBAction func renderMovieBtn(_ sender: NSButton) { simView.renderMovie() }
    @IBAction func startSimBtn(_ sender: NSButton) { simView.shouldRun = true }
    @IBAction func stopSimBtn(_ sender: NSButton) { simView.shouldRun = false }
    @IBAction func resetSimBtn(_ sender: NSButton) { simView.resetSim() }
    @IBAction func toggleLockBtn(_ sender: NSButton) { if simView.state == .running { simView.dataController?.addTask(.shouldToggleIsLocked) } }
    @IBAction func upBtn(_ sender: NSButton) { if simView.state == .running { simView.dataController?.addTask(.shouldMoveUp) } }
    @IBAction func downBtn(_ sender: NSButton) { if simView.state == .running { simView.dataController?.addTask(.shouldMoveDown) } }
    @IBAction func collectBtn(_ sender: NSButton) { if simView.state == .running { simView.dataController?.addTask(.shouldCollectData) } }
    @IBAction func endBtn(_ sender: NSButton) { if simView.state == .running { simView.dataController?.addTask(.shouldEndDataSet) } }
    @IBAction func startProgramBtn(_ sender: NSButton) { if simView.state == .running { simView.dataController?.startAutonomousControl() } }
    @IBAction func stopProgram(_ sender: NSButton) { if simView.state == .running { simView.dataController?.stopAutonomousControl() } }
    
    
    func showHeight(_ value: Float) { heightLbl.floatValue = value }
    func showForce(_ value: Float) { forceLbl.floatValue = value }
    
}

