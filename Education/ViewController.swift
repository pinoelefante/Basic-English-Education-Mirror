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
import JavaScriptCore

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate, SFSpeechRecognizerDelegate, AVSpeechSynthesizerDelegate {
    
    @IBOutlet weak var challengeShowContainer: UIView!
    @IBOutlet weak var challengeTitleLabel: UILabel!
    @IBOutlet weak var challengeNameLabel: UILabel!
    @IBOutlet weak var challengePointsLabel: UILabel!
    
    @IBOutlet weak var settingsButton: UIButton!
    @IBOutlet weak var challengesButton: UIButton!
    @IBOutlet weak var currentImage: UIImageView!
    @IBOutlet weak var squareFrame: UIView!
    @IBOutlet weak var listenRepeatContainer: UIView!
    @IBOutlet weak var listenRepeatLabel: UILabel!
    @IBOutlet weak var micStatusLabel: UILabel!
    @IBOutlet weak var micButton: UIButton!
    @IBOutlet weak var repeatSpeechButton: UIButton!
    //Mauro
    var jsContext: JSContext!
    var copy: CVPixelBuffer!
    var uicolor: UIColor!
    var colort: UIColor!
    var colort1: UIColor!
    var colort2: UIColor!
    var imageView: UIImageView = UIImageView()
    let context = CIContext()
    
    let modelSize = 299
    lazy var synth = AVSpeechSynthesizer()
    var lastWord: String?
    var lastColor: String?
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
            switch newValue {
            case true:
                micButton.layer.borderWidth = 2
                break
            case false:
                micButton.layer.borderWidth = 0
                if(speechTextListened.isEmpty){
                    micStatusLabel.text = ""
                }
                break
            }
        }
    }
    
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    private let audioEngine = AVAudioEngine()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.initializeJS()
        
        synth.delegate = self
        
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
        
        repeatSpeechButton.layer.cornerRadius = 15
        repeatSpeechButton.layer.borderColor = UIColor.blue.cgColor
        
//        view.bringSubview(toFront: settingsButton)
        view.bringSubview(toFront: currentImage)
        view.bringSubview(toFront: squareFrame)
//        view.bringSubview(toFront: challengesButton)
        view.bringSubview(toFront: listenRepeatContainer)
        view.bringSubview(toFront: challengeShowContainer)
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
        
        let principalColor = self.getFinalColor(sampleBuffer: sampleBuffer)
        
        var squareImage = getSquareFrameContent(buffer: pixelBuffer)
        let word = getStringFromBuffer(buffer: UIImage.buffer(from: squareImage!)!) ?? ""
        
        if(!word.isEmpty && word != lastWord)
        {
            lastColor = principalColor
            lastWord = word
            let result_seen = ChallengeManager.itemSeen(item: word)
            SettingsManager.points+=Int(result_seen.points)
            if(result_seen.isChallenge){
                print("Sfida completata: \(word)")
                showChallengeComplete(challengeName: word, challengeTitle: NSLocalizedString("Challenge complete!", comment: "NotificationChallengeComplete") , points: result_seen.points)
            }
            else{
                /*
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
                */
            }
            let search4 = self.fourSearch(image: squareImage!, word: word)
            squareImage = search4 == nil ? squareImage : UIImage(pixelBuffer: search4!)
//            squareImage = binarySquare(image: squareImage!, word: word)
//            let objectColor = getObjectColor(image: squareImage!)
            DispatchQueue.main.async {
                self.currentImage.image = squareImage
                self.text2speech(text: word, color: principalColor)
                self.showListenRepeat(word: word, color: principalColor)
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
    //Method to speak
    func text2speech(text:String, color:String) {
        if mic_listening {
            stopListening()
            mic_listening = false
        }
        if !SettingsManager.isSoundOn || synth.isSpeaking {
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
    // Syntethizer starts to speak
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        repeatSpeechButton.layer.borderWidth = 0
    }
    // Syntethizer finishes to speak
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        repeatSpeechButton.layer.borderWidth = 2
    }
    @IBAction func repeatText2Speech(_ sender: UIButton) {
        text2speech(text: lastWord!, color: lastColor!)
    }
    func showListenRepeat(word:String, color:String)
    {
        let labelText = getPhrase(word: word, color: color)
        
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
        if synth.isSpeaking{
            return
        }
        askMicPermission(completion: { (granted, message) in
            DispatchQueue.main.async {
                if(self.mic_listening) // Stop listening
                {
                    print("Stop listening")
                    self.mic_listening = false
                    if granted {
                        self.stopListening()
                    }
//                    print(self.speechTextListened ?? "Nessun testo")
                    let s_comparison = self.speechTextListened.caseInsensitiveCompare(self.listenRepeatLabel.text!)
                    self.finishSpeech(complete: s_comparison.rawValue == 0)
                }
                else // Start listening
                {
                    print("Start listening")
                    self.mic_listening = true
                    self.micStatusLabel.textColor = UIColor.black;
                    if granted {
                        self.startListening(toFind: self.getPhrase(word: self.lastWord!, color: self.lastColor!))
                        {
                            self.mic_listening = false
                            self.stopListening()
                            self.finishSpeech(complete: true)
                        }
                        self.micStatusLabel.text = NSLocalizedString("Listening...", comment: "MicListening")
                    }
                }
            }
        })
    }
    private func finishSpeech(complete:Bool){
        if complete {
            ChallengeManager.setSpeechComplete(word: self.lastWord!)
            
            self.micStatusLabel.textColor = UIColor.green
//            self.micStatusLabel.text = NSLocalizedString("Success!", comment: "MicFinishSuccess")
        }
        else {
            self.micStatusLabel.textColor = UIColor.red
//            self.micStatusLabel.text = NSLocalizedString("Incomplete!", comment: "MicFinishIncomplete")
        }
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
    var speechTextListened : String = ""
    private func startListening(toFind:String, onFind:@escaping ()->Void) {
        // Clear existing tasks
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        speechTextListened = ""
        // Start audio session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
            try audioSession.setMode(AVAudioSessionModeMeasurement)
            try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        } catch {
            self.micStatusLabel.text = NSLocalizedString("An error occurred when starting audio session.", comment: "MicStartAudioSessionFail")
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
                self.speechTextListened = (result?.bestTranscription.formattedString)!
                self.micStatusLabel.text = self.speechTextListened
                isFinal = result!.isFinal
                let s_comparison = self.speechTextListened.caseInsensitiveCompare(toFind)
                if s_comparison.rawValue == 0 {
                    onFind()
                }
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
            self.micStatusLabel.text = NSLocalizedString("An error occurred starting audio engine", comment: "MicStartAudioEngineFail")
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
                message = NSLocalizedString("Listening...", comment: "MicPermissionAuthorized")
                granted = true
                break
                
            case .denied:
                message = NSLocalizedString("Access to speech recognition is denied by the user.", comment: "MicPermissionDenied")
                break
                
            case .restricted:
                message = NSLocalizedString("Speech recognition is restricted.", comment: "MicPermissionRestricted")
                break
                
            case .notDetermined:
                message = NSLocalizedString("Speech recognition has not been authorized yet.", comment: "MicPermissionNotDetermined")
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
    
    func toHexString(color: UIColor) -> String {
        var r:CGFloat = 0
        var g:CGFloat = 0
        var b:CGFloat = 0
        var a:CGFloat = 0
        
        //getRed()
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        
        let rgb:Int = (Int)(r*255)<<16 | (Int)(g*255)<<8 | (Int)(b*255)<<0
        
        return NSString(format:"#%06x", rgb) as String
    }
    
    func initializeJS() {
        self.jsContext = JSContext()
        
        if let jsSourcePath = Bundle.main.path(forResource: "ntc", ofType: "js") {
            do {
                // Load its contents to a String variable.
                let jsSourceContents = try String(contentsOfFile: jsSourcePath)
                
                // Add the Javascript code that currently exists in the jsSourceContents to the Javascript Runtime through the jsContext object.
                self.jsContext.evaluateScript(jsSourceContents)
            }
            catch {
                print(error.localizedDescription)
            }
        }
    }
    
    func whichColor(color: UIColor) -> String{
        
        let colori = toHexString(color: color)
        var nome: String = "Bello"
        
        if let functionFullname = self.jsContext.objectForKeyedSubscript("nomi") {
            // Call the function that composes the fullname.
            if let fullname = functionFullname.call(withArguments: [colori]) {
                nome=fullname.toString()
                
            }
        }
        return nome
    }
    
    func principalColor(color: UIColor) -> String{
        
        var (h,s,b,a) : (CGFloat, CGFloat, CGFloat, CGFloat) = (0,0,0,0)
        _ = color.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        
        //print("HSB range- h: \(h), s: \(s), v: \(b)")
        
        var colorTitle = " "
        
        switch (h, s, b) {
            
        // red
        case (0...0.138, 0.88...1.00, 0.75...1.00):
            colorTitle = "Red"
        // yellow
        case (0.139...0.175, 0.30...1.00, 0.80...1.00):
            colorTitle = "Yellow"
        // green
        case (0.176...0.422, 0.30...1.00, 0.60...1.00):
            colorTitle = "Green"
        // teal
        case (0.423...0.494, 0.30...1.00, 0.54...1.00):
            colorTitle = "Teal"
        // blue
        case (0.495...0.667, 0.30...1.00, 0.60...1.00):
            colorTitle = "Blue"
        // purple
        case (0.668...0.792, 0.30...1.00, 0.40...1.00):
            colorTitle = "Purple"
        // pink
        case (0.793...0.977, 0.30...1.00, 0.80...1.00):
            colorTitle = "Pink"
        // brown
        case (0...0.097, 0.50...1.00, 0.25...0.58):
            colorTitle = "Brown"
        // white
        case (0...1.00, 0...0.05, 0.95...1.00):
            colorTitle = "White"
        // grey
        case (0...1.00, 0, 0.25...0.94):
            colorTitle = "Grey"
        // black
        case (0...1.00, 0...1.00, 0...0.07):
            colorTitle = "Black"
        default:
            if whichColor(color: color).lowercased().range(of:"red") != nil {
                colorTitle = "Red"
            }
            if whichColor(color: color).lowercased().range(of:"yellow") != nil {
                colorTitle = "Yellow"
            }
            if whichColor(color: color).lowercased().range(of:"green") != nil {
                colorTitle = "Green"
            }
            if whichColor(color: color).lowercased().range(of:"teal") != nil {
                colorTitle = "Teal"
            }
            if whichColor(color: color).lowercased().range(of:"blue") != nil {
                colorTitle = "Blue"
            }
            if whichColor(color: color).lowercased().range(of:"purple") != nil {
                colorTitle = "Purple"
            }
            if whichColor(color: color).lowercased().range(of:"pink") != nil {
                colorTitle = "Pink"
            }
            if whichColor(color: color).lowercased().range(of:"brown") != nil {
                colorTitle = "Brown"
            }
            if whichColor(color: color).lowercased().range(of:"white") != nil {
                colorTitle = "White"
            }
            if whichColor(color: color).lowercased().range(of:"grey") != nil {
                colorTitle = "Grey"
            }
            if whichColor(color: color).lowercased().range(of:"black") != nil {
                colorTitle = "Black"
            }
        }
        
        return colorTitle
    }
    
    private func getFinalColor(sampleBuffer: CMSampleBuffer) -> String{
        
        let image = self.imageFromSampleBuffer(sampleBuffer: sampleBuffer)
        imageView.image = image
        
        let screenCentre : CGPoint = CGPoint(x: imageView.center.x, y: imageView.center.y)
        colort = self.imageView.image?.getPixelColor(pos: screenCentre)
        
        let screenCentre1 : CGPoint = CGPoint(x: imageView.center.x+20, y: imageView.center.y)
        colort1 = self.imageView.image?.getPixelColor(pos: screenCentre1)
        
        let screenCentre2 : CGPoint = CGPoint(x: imageView.center.x-20, y: imageView.center.y)
        colort2 = self.imageView.image?.getPixelColor(pos: screenCentre2)
        
        var r: CGFloat = 0
        var r1: CGFloat = 0
        var r2: CGFloat = 0
        var b: CGFloat = 0
        var b1: CGFloat = 0
        var b2: CGFloat = 0
        var g: CGFloat = 0
        var g1: CGFloat = 0
        var g2: CGFloat = 0
        
        if let color1Components = colort.components {
            r = color1Components.red
            g = color1Components.green
            b = color1Components.blue
        }
        if let color2Components = colort1.components {
            r1 = color2Components.red
            g1 = color2Components.green
            b1 = color2Components.blue
        }
        if let color3Components = colort2.components {
            r2 = color3Components.red
            g2 = color3Components.green
            b2 = color3Components.blue
        }
        
        let red: CGFloat = (r+r1+r2)/3
        let green: CGFloat = (g+g1+g2)/3
        let blue: CGFloat = (b+b1+b2)/3
        
//        print("Red: \(red) - Green: \(green) - Blue: \(blue)")
        
        let _: UIColor = UIColor(displayP3Red: red*255, green: green*255, blue: blue*255, alpha: 255)
        
        let col = self.principalColor(color: self.colort)
        let col1 = self.whichColor(color: self.colort)
        var principal = col1
        if(col == " ")
        {
            principal = col1
        }
        else
        {
            principal = col
        }
        
        return principal
    }
    
    private func imageFromSampleBuffer(sampleBuffer: CMSampleBuffer) -> UIImage? {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}

extension UIImage {
    
    func getPixelColor(pos: CGPoint) -> UIColor? {
        
        guard let cgImage = cgImage, let pixelData = cgImage.dataProvider?.data else { return nil }
        
        let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
        
        let bytesPerPixel = cgImage.bitsPerPixel / 8
        
        let pixelInfo: Int = ((cgImage.bytesPerRow * Int(pos.y)) + (Int(pos.x) * bytesPerPixel))
        
        let b = CGFloat(data[pixelInfo]) / CGFloat(255.0)
        let g = CGFloat(data[pixelInfo+1]) / CGFloat(255.0)
        let r = CGFloat(data[pixelInfo+2]) / CGFloat(255.0)
        let a = CGFloat(data[pixelInfo+3]) / CGFloat(255.0)
        
        return UIColor(red: r, green: g, blue: b, alpha: a)
    }
}

extension UIColor {
    var components: (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat)? {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        return getRed(&r, green: &g, blue: &b, alpha: &a) ? (r,g,b,a) : nil
    }
}
