//
//  ViewController.swift
//  Call for Help
//
//  Created by Zane Sinno on 5/14/21.
//

import UIKit
import AVFoundation
import Speech

class ViewController: UIViewController, SFSpeechRecognizerDelegate {
    //Define some constants
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    
    private var recognitionTask: SFSpeechRecognitionTask?
    
    private let audioEngine = AVAudioEngine()
    
    @IBOutlet weak var numberField: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        //Request access for speech recognition
        SFSpeechRecognizer.requestAuthorization({_ in})
        do{
            //Prepare the microphone
            recognitionTask?.cancel()
            self.recognitionTask = nil
            speechRecognizer.delegate = self
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            let inputNode = audioEngine.inputNode
            //Prepare a recognition request, which allows me to pr
            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            guard let recognitionRequest = recognitionRequest else { fatalError("Unable to create a SFSpeechAudioBufferRecognitionRequest object") }
            recognitionRequest.shouldReportPartialResults = true
            
            //Start the speech recognition service. It won't start listning until I start the microphone
            recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
                var isFinal = false
                
                if let result = result {
                    isFinal = result.isFinal
                    //Check if the user said "help"
                    if result.bestTranscription.formattedString.lowercased().contains("help") {
                        //If the user said "help", this code will run
                        
                        //Run the call function
                        self.call(Void())
                    }
                }
                
                if error != nil || isFinal {
                    // Stop recognizing speech if there is a problem.
                    self.audioEngine.stop()
                    inputNode.removeTap(onBus: 0)

                    self.recognitionRequest = nil
                    self.recognitionTask = nil

                }
            }

            
            //Create a tap and start the audio engine
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
                self.recognitionRequest?.append(buffer)
            }
            
            audioEngine.prepare()
            //Start the microphone
            try audioEngine.start()
            
        }catch{
            //If the app cannot access the microphone, this will run
            
            //Create an alert
            let alert = UIAlertController(title: "Microphone error", message: "We were unable to access the microphone. To grant microphone access, tap settings", preferredStyle: .alert)
            //Add a settings button to the alert
            alert.addAction(UIAlertAction(title: "Settings", style: .default, handler: { (_) -> Void in
                //If the user taps on the settings button, this code will run
                guard let settingsUrl = URL(string: UIApplication.openSettingsURLString)/*Get the URL to open the settings app and go to this app's settings page*/ else {
                            return
                        }

                        if UIApplication.shared.canOpenURL(settingsUrl) {
                            //Open the settings app
                            UIApplication.shared.open(settingsUrl)
                        }
            }))
            //Add an ok button to the alert
            alert.addAction(UIAlertAction(title: "Ok", style: .default))
            //Show the alert
            present(alert, animated: true)
        }
    }
    @IBAction func call(_ sender: Any) {
        //When the button is pressed or the word "help" is heard, this code will run
        if let url = URL(string: "tel://\(String(numberField.text!))") {
            //Call the phone number in the text box
            UIApplication.shared.open(url)
        }
    }
    

}

