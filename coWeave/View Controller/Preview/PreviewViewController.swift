//
//  PreviewViewController.swift
//  coWeave
//
//  Created by Benoît Frisch on 18/11/2017.
//  Copyright © 2017 Benoît Frisch. All rights reserved.
//

import UIKit
import MobileCoreServices
import CoreData
import AVFoundation

class PreviewViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    var image : UIImage!
    var imagePicker = UIImagePickerController()
    var document : Document? = nil
    var page : Page!
    var pageImage : Image! = nil
    var pageNumber: Int16 = 1
    var managedObjectContext: NSManagedObjectContext!
    /**
     *  Audio Recorder
     */
    var recorder: AVAudioRecorder!
    var player:AVAudioPlayer!
    var meterTimer:Timer!
    var soundFileURL:URL!
    var audio : Bool = false
    var playing : Bool = false
    /**
     *  Toolbar Buttons
     */
    @IBOutlet var previousPageButton: UIBarButtonItem!
    @IBOutlet var nextPageButton: UIBarButtonItem!
    @IBOutlet var pageNameButton: UIBarButtonItem!
    /**
     *  Navigation Bar Buttons
     */
    @IBOutlet var audioButton: UIBarButtonItem!
    /**
     * Background
     */
    @IBOutlet var backgroundImageView: UIImageView!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.pageNumber = Int16(document!.pages!.count)
        self.page = document?.firstPage
        updatePage(page: self.page)
        
        self.navigationItem.title = document?.name!
        updatePageControls(page: page)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.navigationItem.title = document?.name!
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func export(_ sender: Any) {
        /*if let audioURL1 = Bundle.main.url(forResource: "audio1", withExtension: "mp3"), let audioURL2 = Bundle.main.url(forResource: "audio2", withExtension: "mp3"), let audioURL3 =  Bundle.main.url(forResource: "audio3", withExtension: "mp3") {
            if let _image1 = UIImage(named: "image1"), let _image2 = UIImage(named: "image2"), let _image3 = UIImage(named: "image3") {
                
                VideoGenerator.current.fileName = "multipleVideo"
                VideoGenerator.current.videoBackgroundColor = .red
                VideoGenerator.current.scaleWidth = 700
                
                VideoGenerator.current.generate(withImages: [_image1, _image2, _image3], andAudios: [audioURL1, audioURL2, audioURL3], andType: .multiple, { (progress) in
                    print(progress)
                }, success: { (url) in
                    print(url)
                    self.createAlertView(message: "Finished single type video generation")
                }, failure: { (error) in
                    print(error)
                    self.createAlertView(message: error.localizedDescription)
                })
            }
        }*/
    }
    
    @IBAction func audioAction(_ sender: Any) {
        print("audio")
        if audio && !playing { // if sound recorded, play it.
            startPlay()
            return
        }
        if playing {
            print("stopping")
            stopPlay()
            return
        }
    }
    
    
    func resetPage() {
        self.image = nil
        self.backgroundImageView.image = nil
        self.pageImage = nil
        removeAudioFile(url: self.soundFileURL)
    }
    
    func updatePageControls(page: Page) {
        self.previousPageButton.isEnabled = (page.previous != nil) ? true : false;
        self.nextPageButton.isEnabled = (page.next != nil) ? true : false;
        self.pageNameButton.title = (page.title == nil) ? "Page \(page.number)" : page.title
        self.audioButton.isEnabled = (page.audio == nil) ? false : true
    }
    
    func updatePage(page: Page) {
        if (page.image != nil) {
            self.image = UIImage(data: page.image!.image! as Data, scale: 1.0)
            self.backgroundImageView.image = self.image
            self.pageImage = page.image!
        }
        loadAudio(page: page)
        if (page.audio != nil) {
            play()
            self.audioButton.image = UIImage(named: "stop")
            playing = true
        }
    }
    
    func loadAudio(page: Page) {
        if (page.audio != nil) {
            let format = DateFormatter()
            format.dateFormat="yyyy-MM-dd-HH-mm-ss"
            let currentFileName = "audio-page\(page.number)-\(format.string(from: Date())).m4a"
            print(currentFileName)
            
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            self.soundFileURL = documentsDirectory.appendingPathComponent(currentFileName)
            do {
                try page.audio?.write(to: self.soundFileURL, options: .atomic)
            } catch {}
            self.recorder = nil
            self.player = nil
            self.meterTimer = nil
            self.audio = true
            self.playing = false
        } else {
            self.recorder = nil
            self.player = nil
            self.meterTimer = nil
            self.soundFileURL = nil
            self.audio = false
            self.playing = false
        }
    }
    
    func removeAudioFile(url : URL? = nil) {
        if (url != nil) {
            do {
                try FileManager.default.removeItem(at: url!)
            } catch let error as NSError {
                print("Error: \(error.domain)")
            }
        }
    }
    
    @IBAction func previousPage(_ sender: Any) {
        resetPage()
        if (page.previous != nil) {
            page = page.previous
        }
        updatePage(page: page)
        updatePageControls(page: page)
    }
    
    @IBAction func nextPage(_ sender: Any) {
        print("next")
        page = page.next
        resetPage()
        updatePage(page: page)
        updatePageControls(page: page)
    }
    
    /**
     * Save Image
     */
    
    func startPlay() {
        play()
        self.audioButton.image = UIImage(named: "stop")
        playing = true
    }
    
    func stopPlay() {
        player.stop()
        self.audioButton.image = UIImage(named: "play")
        playing = false
    }
    
    
    func updateAudioMeter(_ timer:Timer) {
        if let recorder = self.recorder {
            if recorder.isRecording {
                let min = Int(recorder.currentTime / 60)
                let sec = Int(recorder.currentTime.truncatingRemainder(dividingBy: 60))
                let s = String(format: "%02d:%02d", min, sec)
                recorder.updateMeters()
            }
        }
    }
    
    func play() {
        print("\(#function)")
        var url:URL?
        if self.recorder != nil {
            url = self.recorder.url
        } else {
            url = self.soundFileURL!
        }
        print("playing \(String(describing: url))")
        
        do {
            self.player = try AVAudioPlayer(contentsOf: url!)
            self.audioButton.image = UIImage(named: "stop")
            player.delegate = self
            player.prepareToPlay()
            player.volume = 1.0
            player.play()
        } catch {
            self.player = nil
            print(error.localizedDescription)
        }
        
    }
    
    
    func setupRecorder() {
        print("\(#function)")
        
        let format = DateFormatter()
        format.dateFormat="yyyy-MM-dd-HH-mm-ss"
        let currentFileName = "recording-\(format.string(from: Date())).m4a"
        print(currentFileName)
        
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.soundFileURL = documentsDirectory.appendingPathComponent(currentFileName)
        print("writing to soundfile url: '\(soundFileURL!)'")
        
        if FileManager.default.fileExists(atPath: soundFileURL.absoluteString) {
            // probably won't happen. want to do something about it?
            print("soundfile \(soundFileURL.absoluteString) exists")
        }
        
        let recordSettings:[String : Any] = [
            AVFormatIDKey:             kAudioFormatAppleLossless,
            AVEncoderAudioQualityKey: AVAudioQuality.max.rawValue,
            AVEncoderBitRateKey :      32000,
            AVNumberOfChannelsKey:     2,
            AVSampleRateKey :          44100.0
        ]
        
        
        do {
            recorder = try AVAudioRecorder(url: soundFileURL, settings: recordSettings)
            recorder.delegate = self
            recorder.isMeteringEnabled = true
            recorder.prepareToRecord() // creates/overwrites the file at soundFileURL
        } catch {
            recorder = nil
            print(error.localizedDescription)
        }
        
    }
    
    func recordWithPermission(_ setup:Bool) {
        print("\(#function)")
        
        AVAudioSession.sharedInstance().requestRecordPermission() {
            [unowned self] granted in
            if granted {
                
                DispatchQueue.main.async {
                    print("Permission to record granted")
                    self.setSessionPlayAndRecord()
                    if setup {
                        self.setupRecorder()
                    }
                    self.recorder.record()
                    
                    self.meterTimer = Timer.scheduledTimer(timeInterval: 0.1,
                                                           target:self,
                                                           selector:#selector(self.updateAudioMeter(_:)),
                                                           userInfo:nil,
                                                           repeats:true)
                }
            } else {
                print("Permission to record not granted")
            }
        }
        
        if AVAudioSession.sharedInstance().recordPermission() == .denied {
            print("permission denied")
        }
    }
    
    func setSessionPlayback() {
        print("\(#function)")
        
        let session = AVAudioSession.sharedInstance()
        
        do {
            try session.setCategory(AVAudioSessionCategoryPlayback, with: .defaultToSpeaker)
            
        } catch {
            print("could not set session category")
            print(error.localizedDescription)
        }
        
        do {
            try session.setActive(true)
        } catch {
            print("could not make session active")
            print(error.localizedDescription)
        }
    }
    
    func setSessionPlayAndRecord() {
        print("\(#function)")
        
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(AVAudioSessionCategoryPlayAndRecord, with: .defaultToSpeaker)
        } catch {
            print("could not set session category")
            print(error.localizedDescription)
        }
        
        do {
            try session.setActive(true)
        } catch {
            print("could not make session active")
            print(error.localizedDescription)
        }
    }
    
    func askForNotifications() {
        print("\(#function)")
        
        NotificationCenter.default.addObserver(self,
                                               selector:#selector(DocumentDetailViewController.background(_:)),
                                               name:NSNotification.Name.UIApplicationWillResignActive,
                                               object:nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector:#selector(DocumentDetailViewController.foreground(_:)),
                                               name:NSNotification.Name.UIApplicationWillEnterForeground,
                                               object:nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector:#selector(DocumentDetailViewController.routeChange(_:)),
                                               name:NSNotification.Name.AVAudioSessionRouteChange,
                                               object:nil)
    }
    
    func background(_ notification:Notification) {
        print("\(#function)")
        
    }
    
    func foreground(_ notification:Notification) {
        print("\(#function)")
        
    }
    
    
    func routeChange(_ notification:Notification) {
        print("\(#function)")
        
        if let userInfo = (notification as NSNotification).userInfo {
            print("routeChange \(userInfo)")
            
            //print("userInfo \(userInfo)")
            if let reason = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt {
                //print("reason \(reason)")
                switch AVAudioSessionRouteChangeReason(rawValue: reason)! {
                case AVAudioSessionRouteChangeReason.newDeviceAvailable:
                    print("NewDeviceAvailable")
                    print("did you plug in headphones?")
                    checkHeadphones()
                case AVAudioSessionRouteChangeReason.oldDeviceUnavailable:
                    print("OldDeviceUnavailable")
                    print("did you unplug headphones?")
                    checkHeadphones()
                case AVAudioSessionRouteChangeReason.categoryChange:
                    print("CategoryChange")
                case AVAudioSessionRouteChangeReason.override:
                    print("Override")
                case AVAudioSessionRouteChangeReason.wakeFromSleep:
                    print("WakeFromSleep")
                case AVAudioSessionRouteChangeReason.unknown:
                    print("Unknown")
                case AVAudioSessionRouteChangeReason.noSuitableRouteForCategory:
                    print("NoSuitableRouteForCategory")
                case AVAudioSessionRouteChangeReason.routeConfigurationChange:
                    print("RouteConfigurationChange")
                    
                }
            }
        }
    }
    
    func checkHeadphones() {
        print("\(#function)")
        
        // check NewDeviceAvailable and OldDeviceUnavailable for them being plugged in/unplugged
        let currentRoute = AVAudioSession.sharedInstance().currentRoute
        if currentRoute.outputs.count > 0 {
            for description in currentRoute.outputs {
                if description.portType == AVAudioSessionPortHeadphones {
                    print("headphones are plugged in")
                    break
                } else {
                    print("headphones are unplugged")
                }
            }
        } else {
            print("checking headphones requires a connection to a device")
        }
    }
    
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "close") {
            let classVc = segue.destination as! DocumentDetailNavigationViewController
            classVc.managedObjectContext = self.managedObjectContext
            classVc.document = self.document
        }
    }
    
}


// MARK: AVAudioRecorderDelegate
extension PreviewViewController : AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder,
                                         successfully flag: Bool) {
        
        print("\(#function)")
        
        print("finished recording \(flag)")
        self.play()
        
        //recordButton.setTitle("Record", for:UIControlState())
        
        // iOS8 and later
        let alert = UIAlertController(title: "Playing recorded audio...",
                                      message: "Would you like to save or delete it?",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Save", style: .default, handler: {action in
            print("keep was tapped")
            self.recorder = nil
            self.audio = true
           
            
            do {
                let audioData =  try Data(contentsOf: self.soundFileURL!)
                self.page.audio = audioData as NSData
                do {
                    try self.page.managedObjectContext?.save()
                } catch {
                    let saveError = error as NSError
                    print("\(saveError), \(saveError.userInfo)")
                }
            } catch {}
            self.player.stop()
        }))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: {action in
            print("delete was tapped")
            self.recorder.deleteRecording()
            self.audio = false
            self.recorder = nil
            self.soundFileURL = nil
            
            self.player.stop()
        }))
        self.present(alert, animated:true, completion:nil)
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder,
                                          error: Error?) {
        print("\(#function)")
        
        if let e = error {
            print("\(e.localizedDescription)")
        }
    }
    
}

// MARK: AVAudioPlayerDelegate
extension PreviewViewController : AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        print("\(#function)")
        
        print("finished playing \(flag)")
        self.audioButton.image = UIImage(named: "play")
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        print("\(#function)")
        
        if let e = error {
            print("\(e.localizedDescription)")
        }
        
    }
}
