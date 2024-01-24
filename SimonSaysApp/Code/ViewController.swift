//
//  ViewController.swift
//  simsez
//
//  Created by Evie Harpwood on 11/11/2023.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    
    //Outlets for each of the buttons and the label displaying the score
    
    @IBOutlet weak var scoreLabel: UILabel!
    
    @IBOutlet weak var yellowButton: UIButton!
    
    @IBOutlet weak var blueButton: UIButton!
    
    @IBOutlet weak var redButton: UIButton!
    
    @IBOutlet weak var greenButton: UIButton!
    
    let buttons = ["yellow", "blue", "red", "green"]    //Array containing each type of button
    
    var pattern: [String] = []  //Array to contain the full pattern the player will need to replicate
    
    var place = 0   //Variable to track how far through the player is in their turn
    
    var progress = 0    //Variable to track how far through the player is in the full pattern
    
    var simonPlace = 0  //Variable to track simon's turn
    
    var score = 0   //Contains the player's current score
    
    var audioPlayer: AVAudioPlayer?
    
    let filePaths: [String: URL] = getAllMP3FileNameURLs()
    
    func setupPlayer(toPlay fileURL:URL) {
        do {
            try self.audioPlayer = AVAudioPlayer(contentsOf: fileURL)
        } catch {
            print("Can't load audio file \(fileURL.absoluteString)")
            print(error.localizedDescription)
       }
    }
    
    static func getAllMP3FileNameURLs() -> [String:URL] {
        var filePaths = [URL]() //URL array
        var audioFileNames = [String]() //String array
        var theResult = [String:URL]()

        let bundlePath = Bundle.main.bundleURL
        do {
            try FileManager.default.createDirectory(atPath: bundlePath.relativePath, withIntermediateDirectories: true)
            let directoryContents = try FileManager.default.contentsOfDirectory(at: bundlePath, includingPropertiesForKeys: nil, options: [])
            
            // filter the directory contents
            filePaths = directoryContents.filter{ $0.pathExtension == "mp3" }
            
            //get the file names, without the extensions
            audioFileNames = filePaths.map{ $0.deletingPathExtension().lastPathComponent }
        } catch {
            print(error.localizedDescription) //output the error
        }
        //print(audioFileNames) //for debugging purposes only
        for loop in 0..<filePaths.count { //Build up the dictionary.
            theResult[audioFileNames[loop]] = filePaths[loop]
        }
        return theResult
    }
    
    //Function that takes the colour, button, boolean and an optional completion to be called after the button flash animation
    //Carries out the function of a button based on its colour/who is pressing it
    func colourButtonFunction(_ colour: String, _ button: UIButton, _ isSimon: Bool, _ completion: ((Bool) -> Void)? = nil) {
        //Border to indicate it is being pressed
        button.layer.borderWidth = 10
        button.layer.borderColor = UIColor.white.cgColor

        //Queues the sound cue and an animation to make the border fade without blocking the UI thread
        DispatchQueue.main.async {
            self.setupPlayer(toPlay: self.filePaths[colour]!)
            self.audioPlayer?.play()
            
            UIView.animate(withDuration: 0.5, animations: {
                button.layer.borderWidth = 0
            }, completion: completion)
        }
        
        //Checks if it is a player, if so carries out the check for their press
        if !isSimon {
            checkPress(colour)
        }
    }
    
    //Functions for each of the buttons, calls the colourButtonFunction with relevant arguments
    @IBAction func yellowButton(_ sender: Any?) {
        colourButtonFunction("yellow", self.yellowButton, sender == nil)
    }
    
    @IBAction func blueButton(_ sender: Any?) {
        colourButtonFunction("blue", self.blueButton, sender == nil)
    }
    
    @IBAction func redButton(_ sender: Any?) {
        colourButtonFunction("red", self.redButton, sender == nil)
    }
    
    @IBAction func greenButton(_ sender: Any?) {
        colourButtonFunction("green", self.greenButton, sender == nil)
    }
    
    //Button to start the game, generates a pattern and calls simonTurn
    @IBAction func playButton(_ sender: Any) {
        generatePattern(10)
        simonTurn()
    }
    
    //Button to switch to the high scores screen
    @IBAction func highScoresButton(_ sender: Any) {
        performSegue(withIdentifier: "toHighScores", sender: nil)
    }
    
    //Functions to disable/enable all of the colour buttons
    func disableButtons() {
        yellowButton.isUserInteractionEnabled = false
        greenButton.isUserInteractionEnabled = false
        redButton.isUserInteractionEnabled = false
        blueButton.isUserInteractionEnabled = false
    }
    
    func enableButtons() {
        yellowButton.isUserInteractionEnabled = true
        greenButton.isUserInteractionEnabled = true
        redButton.isUserInteractionEnabled = true
        blueButton.isUserInteractionEnabled = true
    }
    
    //Function to generate a new pattern of colours, takes a parameter to define how long the pattern should be, returns array of strings
    func generatePattern(_ length: Int) {
        pattern = []
        place = 0
        progress = 0
        for _ in 1...length {
            pattern.append(buttons[Int.random(in: 0...3)])
        }
        print(pattern)
    }
    
    //Function to check the player's button press and act accordingly
    func checkPress(_ buttonPressed: String) {
        var simonCanGo = true   //Boolean defining whether simon should be able to go at the end of the check
        
        
        if pattern[place] == buttonPressed {
            if place != progress && place != pattern.count - 1 {
                //If the player's press is correct, they have not reached the end of the current segment of the pattern and they have not completed the pattern,
                //Increment their place by one and set simon to not go as it is still the player's turn
                place += 1
                simonCanGo = false
            } else if place == pattern.count - 1 {
                //Otherwise, if they have reached the end of the pattern,
                // Add the length of the pattern to their score, generate a new pattern and allow simon to go
                score += pattern.count
                generatePattern(5 + pattern.count)
                }
            else {
                //If neither of these are true,
                //The player has completed their current step in the pattern but not the whole pattern, increment their progress by one and allow simon to go
                place = 0
                progress += 1
            }
        } else {
            if score != 0 {
                //Load the serialised high scores from UserDefaults
                var data = UserDefaults.standard.data(forKey: "scoresArray")
                var scores: [StoredScore] = []
                if let loadedData = data {
                    //If there was an entry for scoresArray, deserialise it. Otherwise use an empty array
                    scores = try! PropertyListDecoder().decode([StoredScore].self, from: loadedData)
                }
                //Add the current score, sort the scores from highest to lowest, then take the first 20
                //The new score will therefore only be included if it is within the top 20
                scores.append(StoredScore(score: score, date: Date()))
                scores.sort {
                    $0.score > $1.score
                }
                scores = Array(scores.prefix(20))
                //Reserialise the scores back into UserDefaults
                data = try! PropertyListEncoder().encode(scores)
                UserDefaults.standard.set(data, forKey: "scoresArray")
            }
            //Reset score and generate new pattern
            score = 0
            generatePattern(10)
        }
        //Update label displaying score
        scoreLabel.text = "Score: " + String(score)
        
        if simonCanGo {
            //We need to return from the touch event so enqueue
            //simon's turn for later execution. This prevents blocking the UI
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.simonTurn()
            }
        }
    }
    
    func simonPressCurrentButton() {
        //This will be called repeatedly via completions, so exit if we've played the whole pattern and re-enable the buttons
        if simonPlace >= pattern.count || simonPlace > progress {
            enableButtons()
            return
        }
        //We need to play animations in sequence, so we'll
        //use a series of completions instead of a loop
        let completion: (Bool) -> Void = {_ in
            self.simonPlace += 1
            self.simonPressCurrentButton()
        }
        //Call the button pressing function with correct values, passing true to isSimom
        switch pattern[simonPlace] {
            case "yellow": colourButtonFunction("yellow", yellowButton, true, completion)
            case "blue": colourButtonFunction("blue", blueButton, true, completion)
            case "red": colourButtonFunction("red", redButton, true, completion)
            case "green": colourButtonFunction("green", greenButton, true, completion)
            default: break;
        }
    }
    
    //Disable user interaction and begin the pressing of buttons by simon
    func simonTurn() {
        simonPlace = 0
        disableButtons()
        simonPressCurrentButton()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Generates a pattern when first loaded so the user can begin play by pressing a button
        generatePattern(10)
    }


}

