//
//  ViewController.swift
//
//

import UIKit
import AVFoundation
import HealthKit
import Foundation
import CoreLocation
import MediaPlayer
import WatchConnectivity
//import Cocoa
//dont have to uncletsocket

class ViewController: UIViewController, WCSessionDelegate, UIImagePickerControllerDelegate, UIPickerViewDelegate, UIPickerViewDataSource, UINavigationControllerDelegate, AVCaptureVideoDataOutputSampleBufferDelegate, CLLocationManagerDelegate {
    
    var locationManager = CLLocationManager()
    
    var captureSession: AVCaptureSession?
    var stillImageOutput: AVCaptureStillImageOutput?
    var previewLayer: AVCaptureVideoPreviewLayer? // Master layer where all the other stuff is layed on top of yerexcept this is on replcator layer
                                                    // whose idea was this
    
    
    let socket = SocketIOClient(socketURL: NSURL(string: "http://992403e0.ngrok.io")!)
    
    // hardcoded array of languages
    let languages = ["en", "es", "ru", "de", "hi", "it", "ko", "pl", "pt", "he"]
    
  
    @IBOutlet weak var languagePicker: UIPickerView!
    
    @IBOutlet weak var songTextField: UITextField!
    
    @IBOutlet weak var artistTextField: UITextField!
    
    // onclick for submit button
    @IBAction func submitButton(sender: UIButton) {
        
        let songName = songTextField.text
        let artistName = artistTextField.text

//        lan
        let language = languages[languagePicker.selectedRowInComponent(0)]
        
        socket.emit("song", songName!, artistName!, language)
        
        print("song name: " + songName! + " by " + artistName!)
        
        // play the song
//        // All
//        let mediaItems = MPMediaQuery.songsQuery().items
//        // Or you can filter on various property
//        // Like the Genre for example here
//        var query = MPMediaQuery.songsQuery()
//        let predicateByName = MPMediaPropertyPredicate(value: "21 Guns", forProperty: MPMediaItemPropertyTitle, comparisonType: .)
//        query.filterPredicates = NSSet(object: predicateByName) as? Set<MPMediaPredicate>
//        
//        let mediaCollection = MPMediaItemCollection(items: mediaItems!)
//        
//        let player = MPMusicPlayerController.systemMusicPlayer()
//        player.setQueueWithItemCollection(mediaCollection)
//        
//        player.play()

        let query = MPMediaQuery.songsQuery()
        let isPresent = MPMediaPropertyPredicate(value: songName, forProperty: MPMediaItemPropertyTitle, comparisonType: .Contains)
        query.addFilterPredicate(isPresent)
        
        let result = query.collections
        
        if result!.count == 0 {
            print("not found")
            return
        }
        
        
        let controller = MPMusicPlayerController.systemMusicPlayer()
        let item = result![0]
        
        controller.setQueueWithItemCollection(item)
        controller.prepareToPlay()
        controller.play()
        

        
    }
    
    // SET UP THE PICKERVIEW
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1 // hardcoded
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return 10
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return languages[row]
    }
    
    
    
    let lyricsLayer: CATextLayer = CATextLayer() // Displays lyrics
//    let speedLayer: CATextLayer = CATextLayer()
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // connect the socket
        socket.connect()
        
        socket.on("text") {data, ack in
            
            let originalText = data[0] as! String
            let translatedText = data[1] as! String
            
            
            
            self.lyricsLayer.string = originalText + "\n\n\n" + translatedText
            
        } // end of socket.on
        
    }
    
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        captureSession = AVCaptureSession()
        captureSession?.sessionPreset = AVCaptureSessionPreset1920x1080
        
        let backCamera = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        
        let input = try! AVCaptureDeviceInput(device: backCamera)
        
        //var input = AVCaptureDeviceInput(device: backCamera, error: &error)
        var output: AVCaptureVideoDataOutput?
        
        if captureSession?.canAddInput(input) != nil {
            captureSession?.addInput(input)
            
            stillImageOutput = AVCaptureStillImageOutput()
            stillImageOutput?.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
            
            output = AVCaptureVideoDataOutput()
            
            if (captureSession?.canAddOutput(output) != nil) {
                
                //captureSession?.addOutput(stillImageOutput)
                captureSession?.addOutput(output)
                
                previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
                previewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
                previewLayer?.frame = CGRect(x: 13, y: 40, width: 300, height:  self.view.bounds.size.width - 100)
                //previewLayer?.frame = CGRect(self.view.bounds)
                
                let replicatorLayer = CAReplicatorLayer()
                //replicatorLayer.frame = CGRectMake(0, 0, self.view.bounds.size.width / 2, self.view.bounds.size.height)
                replicatorLayer.frame = CGRectMake(13, 40, 400, self.view.bounds.size.width - 100)
                replicatorLayer.instanceCount = 2
                //replicatorLayer.instanceTransform = CATransform3DMakeTranslation(self.view.bounds.size.width / 2, 0.0, 0.0)
                replicatorLayer.instanceTransform = CATransform3DMakeTranslation(310, 0.0, 0.0)
                
                //replicatorLayer.instanceTransform = CATransform3DMakeTranslation(0.0, self.view.bounds.size.height / 2, 0.0)
                
                previewLayer?.connection.videoOrientation = AVCaptureVideoOrientation.LandscapeRight
                
                // setup the layer
                lyricsLayer.font = "Helvetica"
                lyricsLayer.fontSize = 13
                lyricsLayer.frame = CGRectMake(10, 120, 311, 311) // x, y, width, heights NOTE: THE LYRICSLAYER STARTS AT 0,0, BUT THE CAMERA VIEW IS LOWER THAN THIS
                lyricsLayer.alignmentMode = kCAAlignmentCenter
                lyricsLayer.string = "Lyrics Translator"
                lyricsLayer.foregroundColor = UIColor.whiteColor().CGColor
                
                previewLayer?.addSublayer(lyricsLayer)
                
                replicatorLayer.addSublayer(previewLayer!)
                
                self.view.layer.addSublayer(replicatorLayer)
                captureSession?.startRunning()
            }
        }
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // Record the user's speech
    //declare instance variable
    var audioRecorder:AVAudioRecorder!
    
    
    // records and requests api.ai
    func record() {
        
        // test
//        sendGetRequest()
        
        //init
        let audioSession:AVAudioSession = AVAudioSession.sharedInstance()
        
        //ask for permission
        if (audioSession.respondsToSelector("requestRecordPermission:")) {
            
            AVAudioSession.sharedInstance().requestRecordPermission({(granted: Bool)-> Void in
                if granted {
                    print("RECORDING! OILY OILY")
                    
                    //set category and activate recorder session
                    try! audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
                    try! audioSession.setActive(true)
                    
                    
                    //get documnets directory
                    let documentsDirectory = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
                    let fullPath = documentsDirectory.stringByAppendingString("voiceRecording.caf")

                    let url = NSURL.fileURLWithPath(fullPath)
                    
                    //create AnyObject of settings
                    let settings: [String : AnyObject] = [
                        AVFormatIDKey:Int(kAudioFormatAppleIMA4), //Int required in Swift2
                        AVSampleRateKey:44100.0,
                        AVNumberOfChannelsKey:2,
                        AVEncoderBitRateKey:12800,
                        AVLinearPCMBitDepthKey:16,
                        AVEncoderAudioQualityKey:AVAudioQuality.Max.rawValue
                    ]
                    
                    //record
                    try! self.audioRecorder = AVAudioRecorder(URL: url, settings: settings)
                    
                    // send an http post request to the voice recognition api
                    let request = NSMutableURLRequest(URL: NSURL(string: "https://api.api.ai/v1/query?v=20150910")!)
                    
                    // format the request
                    request.HTTPMethod = "POST"
                    
                    request.addValue("5bd76f3b-b0e2-438f-a093-0c2e681a92dd", forHTTPHeaderField: "ocp-apim-subscription-key")
                    request.addValue("Bearer 2b725cdd533242e6b7df34688803bc1d ", forHTTPHeaderField: "Authorization")
                    request.addValue("application/json", forHTTPHeaderField: "Content-type")
                    
                    request.addValue(url.absoluteString, forHTTPHeaderField: "voiceData")
                    
//                    let postString = "id=13&name=Jack"
//                    request.HTTPBody = url
                    
                    let task = NSURLSession.sharedSession().dataTaskWithRequest(request) { data, response, error in
                        guard error == nil && data != nil else {                                                          // check for fundamental networking error
                            print("error=\(error)")
                            return
                        }
                        
                        if let httpStatus = response as? NSHTTPURLResponse where httpStatus.statusCode != 200 {           // check for http errors
                            print("statusCode should be 200, but is \(httpStatus.statusCode)")
                            print("response = \(response)")
                        }
                        
                        let responseString = NSString(data: data!, encoding: NSUTF8StringEncoding)
                        print("responseString = \(responseString)")
                    }
                    task.resume()

                    
                } else{
                    print("NOT RECORDING not granted")
                }
            })
        } // end of if has permission? idk who cares
    
    } // end of record function
    
//    func sendGetRequest() {
//        let url = NSURL(string: "http://www.stackoverflow.com")
//        
//        let task = NSURLSession.sharedSession().dataTaskWithURL(url!) {(data, response, error) in
//            print(NSString(data: data!, encoding: NSUTF8StringEncoding))
//        }
//        
//        task.resume()
//
//    } // end of sendGetRequest()

}