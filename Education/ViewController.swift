//
//  ViewController.swift
//  Education
//
//  Created by D'Arco Luigi on 11/07/18.
//  Copyright © 2018 D'Arco Luigi. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation
import Vision

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    //Start Voice
    let synth = AVSpeechSynthesizer()
    var lastWord: String = ""
    let label = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 21))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Start Camera
        let captureSession = AVCaptureSession()
        
        guard let captureDevice = AVCaptureDevice.default(for: .video) else { return }
        
        guard let input = try? AVCaptureDeviceInput(device: captureDevice) else { return }
        
        captureSession.addInput(input)
        
        captureSession.startRunning()
        
        let prevewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        
        view.layer.addSublayer(prevewLayer)
        prevewLayer.frame = view.frame
        
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        captureSession.addOutput(dataOutput)
        
        //Add label
        label.center = CGPoint(x: 160, y: 285)
        label.textAlignment = .center
        label.text = "Prova Label"
        self.view.addSubview(label)
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        //        print("Camera", Date())
        
        if (synth.isSpeaking) {
            return
        }
        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        guard let model = try? VNCoreMLModel(for: Inceptionv3().model) else { return }
        
        let request = VNCoreMLRequest(model: model)
        { (finishedReq, err) in
            guard let result = finishedReq.results as? [VNClassificationObservation] else { return }
            guard let firstObservation = result.first else { return }
            
            let array = firstObservation.identifier.components(separatedBy: ",")
            let str = array[0]
            
            if (firstObservation.confidence >= 0.5) {
                if (str != self.lastWord) {
                    self.text2speech(text: str)
                    print(str, firstObservation.confidence)
                    
                    DispatchQueue.main.async {
                        self.label.text = str
                    }
                    
                    self.lastWord = str
                }
            }
        }
        
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
    }
    
    //Method to speak
    func text2speech(text:String) {
        let myUtterance = AVSpeechUtterance(string: text)
        myUtterance.rate = 0.4
        myUtterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        synth.speak(myUtterance)
    }
    
}
