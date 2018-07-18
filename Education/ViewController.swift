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
    
    @IBOutlet weak var challengeShowContainer: UIView!
    @IBOutlet weak var challengeTitleLabel: UILabel!
    @IBOutlet weak var challengeNameLabel: UILabel!
    @IBOutlet weak var challengePointsLabel: UILabel!
    
    @IBOutlet weak var wordLabel: UILabel!
    @IBOutlet weak var settingsButton: UIButton!
    @IBOutlet weak var challengesButton: UIButton!
    @IBOutlet weak var currentImage: UIImageView!
    @IBOutlet weak var squareFrame: UIView!
    
    let modelSize = 299
    let synth = AVSpeechSynthesizer()
    var lastWord: String?
    var captureSession : AVCaptureSession!
    var ciContext : CIContext!
    lazy var model : VNCoreMLModel? =
        {
            return try? VNCoreMLModel(for: Inceptionv3().model)
    }()
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ciContext = CIContext()
        
        //Start Camera
        captureSession = AVCaptureSession()
        guard let captureDevice = AVCaptureDevice.default(for: .video) else { return }
        guard let input = try? AVCaptureDeviceInput(device: captureDevice) else { return }
        captureSession.addInput(input)
        captureSession.sessionPreset = .hd4K3840x2160
        
        let bounds = view.layer.bounds
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.bounds = bounds
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.position = CGPoint(x: 0, y: 0)
        
        view.layer.addSublayer(previewLayer)
        previewLayer.frame = view.frame
        
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        captureSession.addOutput(dataOutput)
        
        //currentImage.transform = CGAffineTransform.init(rotationAngle: 1.5708)
        
        squareFrame.backgroundColor = UIColor.clear
        squareFrame.layer.borderWidth = 2
        squareFrame.layer.borderColor = UIColor.red.cgColor
        
        challengeShowContainer.layer.cornerRadius = 10
        
//        view.bringSubview(toFront: settingsButton)
        view.bringSubview(toFront: wordLabel)
        view.bringSubview(toFront: currentImage)
        view.bringSubview(toFront: squareFrame)
//        view.bringSubview(toFront: challengesButton)
        view.bringSubview(toFront: challengeShowContainer)
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        captureSession.startRunning()
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        captureSession.stopRunning()
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if (synth.isSpeaking) {
            return
        }
        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        var squareImage = UIImage(pixelBuffer: pixelBuffer) // getSquareFrameContent(buffer: pixelBuffer)
        let word = getStringFromBuffer(buffer: UIImage.buffer(from: squareImage!)!) ?? ""
        
        if(!word.isEmpty && word != lastWord)
        {
            lastWord = word
            let result_seen = ChallengeManager.itemSeen(item: word)
            if(result_seen.isChallenge){
                print("Sfida completata: \(word)")
                showChallengeComplete(challengeName: word, challengeTitle: "Challenge complete!" , points: result_seen.points)
            }
            else{
                switch result_seen.points{
                case 0:
                    print("Hai già visto questo oggetto oggi")
                    showChallengeComplete(challengeName: word, challengeTitle: "Già visto" , points: result_seen.points)
                case 1:
                    print("Hai già visto questo oggetto, ma è la prima volta che lo vedi oggi")
                    showChallengeComplete(challengeName: word, challengeTitle: "First time today" , points: result_seen.points)
                case 5:
                    print("Hai visto questo oggetto per la prima volta")
                    showChallengeComplete(challengeName: word, challengeTitle: "New object!" , points: result_seen.points)
                default:
                    break
                }
            }
            let search4 = self.fourSearch(image: squareImage!, word: word)
            squareImage = search4 == nil ? squareImage : UIImage(pixelBuffer: search4!)
//            squareImage = binarySquare(image: squareImage!, word: word)
            let objectColor = getObjectColor(image: squareImage!)
            DispatchQueue.main.async {
                
                self.setLabelText(text: word, color: objectColor)
                self.currentImage.image = squareImage
                self.text2speech(text: word)
            }
        }
    }
    func showChallengeComplete(challengeName:String, challengeTitle:String, points:Int32)
    {
        DispatchQueue.main.async {
            self.challengeNameLabel.text = challengeName
            self.challengeTitleLabel.text = challengeTitle
            self.challengeShowContainer.isHidden = false
            self.challengePointsLabel.text = "+\(points)"
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now()+3) {
            self.challengeShowContainer.isHidden = true
            self.challengeNameLabel.text = ""
            self.challengeTitleLabel.text = ""
            self.challengePointsLabel.text = ""
        }
    }
    func setLabelText(text:String, color:UIColor) {
        let fontSize = SettingsManager.fontSize
        wordLabel.text = text
        wordLabel.font = wordLabel.font.withSize(CGFloat(Float(fontSize)))
        wordLabel.textColor = color
    }
    //Method to speak
    func text2speech(text:String) {
        let isenable = SettingsManager.isSoundOn
        if !isenable{
            return
        }
        let myUtterance = AVSpeechUtterance(string: text)
        myUtterance.rate = SettingsManager.voiceRate
        let voiceLanguage = SettingsManager.isSoundVoiceFemale
        myUtterance.voice = AVSpeechSynthesisVoice(language: voiceLanguage ? "en-US" : "en-GB")
        synth.speak(myUtterance)
    }
    func getSquareFrameContent(buffer:CVPixelBuffer) -> UIImage?
    {
        var rotatedImage = UIImage(pixelBuffer: buffer)
        rotatedImage = UIImage.imageRotatedByDegrees(oldImage:rotatedImage!, deg: 90)
        
        let viewBounds = self.view.bounds
        
        let heightRatio = Float(rotatedImage!.size.height)/Float(viewBounds.height)
        let widthRatio = Float(rotatedImage!.size.width)/Float(viewBounds.width)
        
        let frameHeight = Float(squareFrame.frame.height) * heightRatio
        let frameWidth = Float(squareFrame.frame.width) * widthRatio
        
        let xFrame = Float(squareFrame.frame.origin.x) * widthRatio
        let yFrame = Float(squareFrame.frame.origin.y) * heightRatio
        
//        print("x:\(xFrame) y:\(yFrame) width:\(frameWidth) height:\(frameHeight)")
        
        let cropRectangle = CGRect(x: Int(xFrame), y: Int(yFrame), width: Int(frameWidth), height: Int(frameHeight))
        let cropped = rotatedImage?.croppedInRect(rect: cropRectangle)
        
        return cropped
    }
    func fourSearch(image:UIImage, word:String) -> CVPixelBuffer?{
//        if(Int(image.size.height) < modelSize || Int(image.size.width) < modelSize)
//        {
//            return nil
//        }
        let middleY = image.size.height/2
        let middleX = image.size.width/2
        
        let crop1 = image.croppedInRect(rect: CGRect(x: 0, y: 0, width: middleX, height: middleY))
        let crop1Buffer = UIImage.buffer(from: crop1)
        if(containObject(buffer: crop1Buffer!, word: word))
        {
            let search = fourSearch(image: crop1, word: word)
            return search == nil ? crop1Buffer : search
        }
        
        let crop2 = image.croppedInRect(rect: CGRect(x: middleX, y: 0, width: middleX, height: middleY))
        let crop2Buffer = UIImage.buffer(from: crop2)
        if(containObject(buffer: crop2Buffer!, word: word))
        {
            let search = fourSearch(image: crop2, word: word)
            return search == nil ? crop2Buffer : search
        }
        
        let crop3 = image.croppedInRect(rect: CGRect(x: 0, y: middleY, width: middleX, height: middleY))
        let crop3Buffer = UIImage.buffer(from: crop3)
        if(containObject(buffer: crop3Buffer!, word: word))
        {
            let search = fourSearch(image: crop3, word: word)
            return search == nil ? crop3Buffer : search
        }
        
        let crop4 = image.croppedInRect(rect: CGRect(x: middleX, y: middleY, width: middleX, height: middleY))
        let crop4Buffer = UIImage.buffer(from: crop4)
        if(containObject(buffer: crop4Buffer!, word: word))
        {
            let search = fourSearch(image: crop4, word: word)
            return search == nil ? crop4Buffer : search
        }
        return nil
    }
    func binarySquare(image:UIImage, word:String) -> UIImage
    {
        let foundV = binarySquareV(image: image, word: word)
        if foundV != nil
        {
            let foundH = binarySquareH(image: foundV!, word: word)
            return foundH != nil ? foundH! : foundV!
        }
        return image
    }
    func binarySquareV(image:UIImage, word:String) -> UIImage?
    {
        let middleX = image.size.width/2
        if(Int(image.size.height) < modelSize || Int(image.size.width) < modelSize || Int(middleX) < modelSize)
        {
            return nil
        }
        let crop1 = image.croppedInRect(rect: CGRect(x: 0, y: 0, width: middleX, height: image.size.height))
        let crop1Buffer = UIImage.buffer(from: crop1)
        if(containObject(buffer: crop1Buffer!, word: word))
        {
            return crop1
        }
        
        let crop2 = image.croppedInRect(rect: CGRect(x: middleX, y: 0, width: middleX, height: image.size.height))
        let crop2Buffer = UIImage.buffer(from: crop2)
        if(containObject(buffer: crop2Buffer!, word: word))
        {
            return crop2
            
        }
        return image
    }
    func binarySquareH(image:UIImage, word:String) -> UIImage?
    {
        let middleY = image.size.height/2
        if(Int(image.size.height) < modelSize || Int(image.size.width) < modelSize || Int(middleY) < modelSize)
        {
            return nil
        }
        let crop1 = image.croppedInRect(rect: CGRect(x: 0, y: 0, width: image.size.width, height: middleY))
        let crop1Buffer = UIImage.buffer(from: crop1)
        if(containObject(buffer: crop1Buffer!, word: word))
        {
            return crop1
        }
        
        let crop2 = image.croppedInRect(rect: CGRect(x: 0, y: middleY, width: image.size.width, height: middleY))
        let crop2Buffer = UIImage.buffer(from: crop2)
        if(containObject(buffer: crop2Buffer!, word: word))
        {
            return crop2
            
        }
        return image
    }
    func getStringFromBuffer(buffer:CVPixelBuffer) -> String?
    {
        var stringResult : String? = nil
        let request = VNCoreMLRequest(model: model!)
        {
            (finishedReq, err) in
            
            guard let result = finishedReq.results as? [VNClassificationObservation] else { return }
            guard let firstObservation = result.first else { return }
//            print("Screen position: \(firstObservation.accessibilityFrame)")
            let array = firstObservation.identifier.components(separatedBy: ",")
            let str = array[0]
            
            let confidence = firstObservation.confidence
            if (confidence >= 0.75 ) {
                stringResult = str
            }
        }
        try? VNImageRequestHandler(cvPixelBuffer: buffer, options: [:]).perform([request])
        
        return stringResult
    }
    func containObject(buffer:CVPixelBuffer, word:String) -> Bool
    {
        let found = getStringFromBuffer(buffer: buffer) ?? ""
        return found == word
    }
    func getObjectColor(image:UIImage) -> UIColor
    {
        let middleX = image.size.width/2
        let middleY = image.size.height/2
        
        let color = image.getPixelColor(x: Int(middleX), y: Int(middleY))
//        print("Color: "+color.description)
        return color
    }
}
extension UIImage {
    func croppedInRect(rect: CGRect) -> UIImage {
        func rad(_ degree: Double) -> CGFloat {
            return CGFloat(degree / 180.0 * .pi)
        }
        
        var rectTransform: CGAffineTransform
        switch imageOrientation {
        case .left:
            rectTransform = CGAffineTransform(rotationAngle: rad(90)).translatedBy(x: 0, y: -self.size.height)
        case .right:
            rectTransform = CGAffineTransform(rotationAngle: rad(-90)).translatedBy(x: -self.size.width, y: 0)
        case .down:
            rectTransform = CGAffineTransform(rotationAngle: rad(-180)).translatedBy(x: -self.size.width, y: -self.size.height)
        default:
            rectTransform = .identity
        }
        rectTransform = rectTransform.scaledBy(x: self.scale, y: self.scale)
        
        let imageRef = self.cgImage!.cropping(to: rect.applying(rectTransform))
        let result = UIImage(cgImage: imageRef!, scale: self.scale, orientation: self.imageOrientation)
        return result
    }
    static func imageRotatedByDegrees(oldImage: UIImage, deg degrees: CGFloat) -> UIImage {
        //Calculate the size of the rotated view's containing box for our drawing space
        let rotatedViewBox: UIView = UIView(frame: CGRect(x: 0, y: 0, width: oldImage.size.width, height: oldImage.size.height))
        let t: CGAffineTransform = CGAffineTransform(rotationAngle: degrees * CGFloat.pi / 180)
        rotatedViewBox.transform = t
        let rotatedSize: CGSize = rotatedViewBox.frame.size
        //Create the bitmap context
        UIGraphicsBeginImageContext(rotatedSize)
        let bitmap: CGContext = UIGraphicsGetCurrentContext()!
        //Move the origin to the middle of the image so we will rotate and scale around the center.
        bitmap.translateBy(x: rotatedSize.width / 2, y: rotatedSize.height / 2)
        //Rotate the image context
        bitmap.rotate(by: (degrees * CGFloat.pi / 180))
        //Now, draw the rotated/scaled image into the context
        bitmap.scaleBy(x: 1.0, y: -1.0)
        bitmap.draw(oldImage.cgImage!, in: CGRect(x: -oldImage.size.width / 2, y: -oldImage.size.height / 2, width: oldImage.size.width, height: oldImage.size.height))
        let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
    }
    static func buffer(from image: UIImage) -> CVPixelBuffer? {
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        var pixelBuffer : CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(image.size.width), Int(image.size.height), kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)
        guard (status == kCVReturnSuccess) else {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)
        
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: pixelData, width: Int(image.size.width), height: Int(image.size.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
        
        context?.translateBy(x: 0, y: image.size.height)
        context?.scaleBy(x: 1.0, y: -1.0)
        
        UIGraphicsPushContext(context!)
        image.draw(in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
        UIGraphicsPopContext()
        CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        
        return pixelBuffer
    }
    func getPixelColor(x:Int, y:Int) -> UIColor {
        return getPixelColor(pos: CGPoint(x: x, y: y))
    }
    func getPixelColor(pos: CGPoint) -> UIColor {
        
        let pixelData = self.cgImage!.dataProvider!.data
        let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
        
        let pixelInfo: Int = ((Int(self.size.width) * Int(pos.y)) + Int(pos.x)) * 4
        
        let r = CGFloat(data[pixelInfo]) / CGFloat(255.0)
        let g = CGFloat(data[pixelInfo+1]) / CGFloat(255.0)
        let b = CGFloat(data[pixelInfo+2]) / CGFloat(255.0)
        let a = CGFloat(data[pixelInfo+3]) / CGFloat(255.0)
        
        return UIColor(red: r, green: g, blue: b, alpha: a)
    }
}
