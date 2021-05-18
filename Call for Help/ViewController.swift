//
//  ViewController.swift
//  Call for Help
//
//  Created by Zane Sinno on 5/14/21.
//

import UIKit
import AVFoundation
import Speech
import CoreData



class ViewController: UIViewController, SFSpeechRecognizerDelegate {
    
    //Define some variables
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    
    private var recognitionTask: SFSpeechRecognitionTask?
    
    private let audioEngine = AVAudioEngine()
    
    var called = false
    
    @IBOutlet weak var numberField: UITextField!
    //Save the phone number when it is changed
    @IBAction func valueChanged(_ sender: Any) {
          do {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let mancon = appDelegate.persistentContainer.viewContext
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Number")
            fetchRequest.returnsObjectsAsFaults = false

            do
            {
                let results = try mancon.fetch(fetchRequest)
                for managedObject in results
                {
                    let managedObjectData:NSManagedObject = managedObject as! NSManagedObject
                    mancon.delete(managedObjectData)
                }
            } catch let error as NSError {
                print("Detele all data in \("Number") error : \(error) \(error.userInfo)")
            }
            guard let appDelegate =
                UIApplication.shared.delegate as? AppDelegate else {
                return
              }
            let managedContext =
                appDelegate.persistentContainer.viewContext
              
              let entity =
                NSEntityDescription.entity(forEntityName: "Number",
                                           in: managedContext)!
              
              let numb = NSManagedObject(entity: entity,
                                           insertInto: managedContext)
              
            numb.setValue(numberField.text, forKeyPath: "num")
            try managedContext.save()
          } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
          }
    }
    override func viewDidLoad() {
        //This function runs when the app is opened
        super.viewDidLoad()
        //Load the phone number from previously
          guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
              return
          }
          
          let managedContext =
            appDelegate.persistentContainer.viewContext
          
          let fetchRequest =
            NSFetchRequest<NSManagedObject>(entityName: "Number")
          
          do {
            let numb = try managedContext.fetch(fetchRequest)
            if numb.count == 1 {
                numberField.text = (numb[0].value(forKey: "num") as! String)
            }
          } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
          }
        
        //Hide the keyboard when the user taps out of it
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard (_:)))
        self.view.addGestureRecognizer(tapGesture)
        
        //Request access for speech recognition
        SFSpeechRecognizer.requestAuthorization({_ in})
        do{
            //Kill old tasks (if any)
            recognitionTask?.cancel()
            self.recognitionTask = nil
            speechRecognizer.delegate = self
            //Prepare the microphone
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            let inputNode = audioEngine.inputNode
            //Prepare a recognition request, which allows me to process speech
            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            guard let recognitionRequest = recognitionRequest else { fatalError("Unable to create a SFSpeechAudioBufferRecognitionRequest object") }
            recognitionRequest.shouldReportPartialResults = true
            
            //Start the speech recognition service. It won't start listning until I start the microphone
            recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
                var isFinal = false
                if result != nil{
                if let result = result {
                    isFinal = result.isFinal
                    //Check if the user said "help"
                    if result.bestTranscription.formattedString.lowercased().contains("help") && self.called == false {
                        //If the user said "help", this code will run
                        self.called = true //Stop the ask function from running
                        
                        //Run the call function
                        self.call(ViewController())
                    }
                }
                
                if error != nil || isFinal {
                    // Stop recognizing speech if there is a problem.
                    self.audioEngine.stop()
                    inputNode.removeTap(onBus: 0)

                    self.recognitionRequest = nil
                    self.recognitionTask = nil
                    //Reload the audio engine
                    self.reload()
                    
                }
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
    func reload() {
        //If the audio player crashes, this will reload it
        
        self.audioEngine.stop()
        recognitionRequest?.endAudio()

        self.recognitionRequest = nil
        self.recognitionTask = nil
        
        SFSpeechRecognizer.requestAuthorization({_ in})
        do{
            //Kill old tasks (if any)
            recognitionTask?.cancel()
            self.recognitionTask = nil
            speechRecognizer.delegate = self
            //Prepare the microphone
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            let inputNode = audioEngine.inputNode
            //Prepare a recognition request, which allows me to process speech
            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            guard let recognitionRequest = recognitionRequest else { fatalError("Unable to create a SFSpeechAudioBufferRecognitionRequest object") }
            recognitionRequest.shouldReportPartialResults = true
            
            //Start the speech recognition service. It won't start listning until I start the microphone
            recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
                var isFinal = false
                if result != nil{
                if let result = result {
                    isFinal = result.isFinal
                    //Check if the user said "help"
                    if result.bestTranscription.formattedString.lowercased().contains("help") && self.called == false {
                        //If the user said "help", this code will run
                        self.called = true //Stop the ask function from running
                        
                        //Run the call function
                        self.call(ViewController())
                    }
                }
                
                if error != nil || isFinal {
                    // Stop recognizing speech if there is a problem.
                    self.audioEngine.stop()
                    inputNode.removeTap(onBus: 0)

                    self.recognitionRequest = nil
                    self.recognitionTask = nil
                    //Reload the audio engine
                    self.reload()
                    
                }
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
    func returnto(){
        //When the app finishes the call, this code will run
        
        //Reload the audio driver
        reload()
    }
    
    @IBAction func call(_ sender: Any) {
        //When the button is pressed or the word "help" is heard, this code will run
        
        //Load the phone number
        guard let appDelegate =
          UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        let managedContext =
          appDelegate.persistentContainer.viewContext
        
        let fetchRequest =
          NSFetchRequest<NSManagedObject>(entityName: "Number")
        
        do {
          let numb = try managedContext.fetch(fetchRequest)
          if numb.count == 1 {
            if let url = URL(string: "tel://\(numb[0].value(forKey: "num") as! String)") {
                //Call the phone number in the text box
                UIApplication.shared.open(url)
            }
          }
        } catch let error as NSError {
          print("Could not fetch. \(error), \(error.userInfo)")
        }
        
    }
    //Hide the keyboard when the user taps out of it
    @objc func dismissKeyboard (_ sender: UITapGestureRecognizer) {
        numberField.resignFirstResponder()
    }
    

}

