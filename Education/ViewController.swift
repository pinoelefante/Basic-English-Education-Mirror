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
import Speech

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate, SFSpeechRecognizerDelegate {
    
    @IBOutlet weak var challengeShowContainer: UIView!
    @IBOutlet weak var challengeTitleLabel: UILabel!
    @IBOutlet weak var challengeNameLabel: UILabel!
    @IBOutlet weak var challengePointsLabel: UILabel!
    
    @IBOutlet weak var wordLabel: UILabel!
    @IBOutlet weak var settingsButton: UIButton!
    @IBOutlet weak var challengesButton: UIButton!
    @IBOutlet weak var currentImage: UIImageView!
    @IBOutlet weak var squareFrame: UIView!
    @IBOutlet weak var listenRepeatContainer: UIView!
    @IBOutlet weak var listenRepeatLabel: UILabel!
    @IBOutlet weak var micStatusLabel: UILabel!
    @IBOutlet weak var micButton: UIButton!
    
    let modelSize = 299
    lazy var synth = AVSpeechSynthesizer()
    var lastWord: String?
    var captureSession : AVCaptureSession!
    lazy var model : VNCoreMLModel? = try? VNCoreMLModel(for: Inceptionv3().model)
    var showingListenRepeat : Bool = false {
        willSet
        {
            listenRepeatContainer.isHidden = !newValue
        }
    }
    var mic_listening = false {
        willSet {
            micButton.layer.borderWidth = newValue ? 2 : 0
            
        }
    }
    
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    private let audioEngine = AVAudioEngine()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Start Camera
        captureSession = AVCaptureSession()
        guard let captureDevice = AVCaptureDevice.default(for: .video) else { return }
        guard let input = try? AVCaptureDeviceInput(device: captureDevice) else { return }
        captureSession.addInput(input)
        captureSession.sessionPreset = .hd4K3840x2160
        
        speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "en-US"))
        speechRecognizer?.delegate = self
        
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
        
        listenRepeatContainer.layer.cornerRadius = 10
        
        micButton.layer.cornerRadius = 15
        micButton.layer.borderColor = UIColor.blue.cgColor
        
//        view.bringSubview(toFront: settingsButton)
        view.bringSubview(toFront: wordLabel)
        view.bringSubview(toFront: currentImage)
        view.bringSubview(toFront: squareFrame)
//        view.bringSubview(toFront: challengesButton)
        view.bringSubview(toFront: challengeShowContainer)
        view.bringSubview(toFront: listenRepeatContainer)
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        captureSession.startRunning()
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        captureSession.stopRunning()
        showingListenRepeat = false
        lastWord = ""
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if (synth.isSpeaking || showingListenRepeat) {
            return
        }
        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        var squareImage = getSquareFrameContent(buffer: pixelBuffer)
        let word = getStringFromBuffer(buffer: UIImage.buffer(from: squareImage!)!) ?? ""
        
        if(!word.isEmpty && word != lastWord)
        {
            lastWord = word
            let result_seen = ChallengeManager.itemSeen(item: word)
            SettingsManager.points+=Int(result_seen.points)
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
                self.text2speech(text: word, color: "black")
                self.showListenRepeat(word: word, color: "black")
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
    func text2speech(text:String, color:String) {
        if !SettingsManager.isSoundOn{
            return
        }
        let phrase = getPhrase(word: text, color: color)
        let myUtterance = AVSpeechUtterance(string: phrase)
        myUtterance.rate = SettingsManager.voiceRate
        let voiceLanguage = SettingsManager.isSoundVoiceFemale
        myUtterance.voice = AVSpeechSynthesisVoice(language: voiceLanguage ? "en-US" : "en-GB")
        try? AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryMultiRoute)
        try? AVAudioSession.sharedInstance().setMode(AVAudioSessionModeDefault)
        synth.speak(myUtterance)
    }
    func showListenRepeat(word:String, color:String)
    {
        let skipComplete = SettingsManager.isListenRepeatOnlyIncomplete && ChallengeManager.isSpeechComplete(word: word)
        if(!SettingsManager.isSoundOn || !SettingsManager.isListenRepeatEnabled || skipComplete){
            return
        }
        
        let labelText = "The \(word) \(color != "" ? "is \(color)" : "")"
        
        mic_listening = false
        listenRepeatLabel.text = labelText
        micStatusLabel.text = ""
        self.micStatusLabel.textColor = UIColor.black
        
        showingListenRepeat = true
    }
    func getPhrase(word:String, color:String) -> String
    {
        return "The \(word) \(color != "" ? "is \(color)" : "")"
    }
    @IBAction func micIsDown(_ sender: UIButton) {
//        print("mic tapped")
        askMicPermission(completion: { (granted, message) in
            DispatchQueue.main.async {
                if(self.mic_listening) // Stop listening
                {
                    print("Stop listening")
                    self.mic_listening = false
                    if granted {
                        self.stopListening()
                    }
                    print(self.speechTextListened ?? "Nessun testo")
                    if self.speechTextListened == self.listenRepeatLabel.text{
                        ChallengeManager.setSpeechComplete(word: self.lastWord!)
                        
                        self.micStatusLabel.textColor = UIColor.green
                        self.micStatusLabel.text = "Success!"
                    }
                    else {
                        self.micStatusLabel.textColor = UIColor.red
                        self.micStatusLabel.text = "Incomplete!"
                    }
                }
                else // Start listening
                {
                    print("Start listening")
                    self.mic_listening = true
                    if granted {
                        self.startListening()
                        self.micStatusLabel.text = "Listening..."
                    }
                }
            }
        })
    }
    @IBAction func closeListenRepeatAction(_ sender: UIButton) {
        if mic_listening{
            stopListening()
            mic_listening = false
        }
        showingListenRepeat = false
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
    var speechTextListened : String?
    private func startListening() {
        // Clear existing tasks
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        // Start audio session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
            try audioSession.setMode(AVAudioSessionModeMeasurement)
            try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        } catch {
            self.micStatusLabel.text = "An error occurred when starting audio session."
            return
        }
        
        // Request speech recognition
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
//        guard let inputNode = audioEngine.inputNode else {
//            fatalError("No input node detected")
//        }
        let inputNode = audioEngine.inputNode
        
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in
            
            var isFinal = false
            
            if result != nil {
                self.speechTextListened = result?.bestTranscription.formattedString
                self.micStatusLabel.text = self.speechTextListened
                isFinal = result!.isFinal
            }
            
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
            }
        })
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
        } catch {
            self.micStatusLabel.text = "An error occurred starting audio engine"
        }
    }
    
    /**
     Stop listening to audio and speech recognition
     */
    private func stopListening() {
        self.audioEngine.reset()
        self.audioEngine.stop()
        self.recognitionRequest?.endAudio()
        
        self.recognitionRequest = nil
        self.recognitionTask = nil
    }
    /**
     Check the status of Speech Recognizer authorization.
     - returns: A message, and if the access is granted.
     */
    private func askMicPermission(completion: @escaping (Bool, String) -> ()) {
        SFSpeechRecognizer.requestAuthorization { status in
            let message: String
            var granted = false
            
            switch status {
            case .authorized:
                message = "Listening..."
                granted = true
                break
                
            case .denied:
                message = "Access to speech recognition is denied by the user."
                break
                
            case .restricted:
                message = "Speech recognition is restricted."
                break
                
            case .notDetermined:
                message = "Speech recognition has not been authorized yet."
                break
            }
            
            completion(granted, message)
        }
    }
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
//        tapButton.isEnabled = available
        if available {
            // Prepare to listen
//            mic_listening = true
//            micStatusLabel.text = "Tap to listen"
//            viewTapped(tapButton)
        } else {
//            micStatusLabel.text = "Recognition is not available."
        }
    }
}
