//
//  HighScoresViewController.swift
//  simsez
//
//  Created by Evie Harpwood on 12/11/2023.
//

import UIKit

//We need 'Codable' so this struct can be serialised and stored into UserDefaults
struct StoredScore: Codable {
    var score: Int
    var date: Date
}

class HighScoresViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    //Returns a sorted list of up to 20 scores (highest to lowest) from UserDefaults
    func scores() -> [StoredScore] {
        //If there is no entry currently, return an empty array
        guard let data = UserDefaults.standard.data(forKey: "scoresArray") else {
            return []
        }
        //Deserialise the list, sort it and take the top 20
        var scores: [StoredScore] = try! PropertyListDecoder().decode([StoredScore].self, from: data)
        scores.sort {
            $0.score > $1.score
        }
        return Array(scores.prefix(20))
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return scores().count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let aCell = tableView.dequeueReusableCell(withIdentifier: "scoreCell", for: indexPath)
        let score = scores()[indexPath.row]
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        //'text' will be placed on the left of the cell, and
        //'detailText' on the right
        aCell.textLabel!.text = String(score.score)
        aCell.detailTextLabel!.text = dateFormatter.string(from: score.date)
        return aCell
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
    }

}
