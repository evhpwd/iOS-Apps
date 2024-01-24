//
//  CustomTableViewCell.swift
//  NessVisitorApp

import UIKit

class CustomTableViewCell: UITableViewCell {

    // Variable to contain the current plant in the cell
    var currentPlant: plant? = nil
    
    // Outlets for cell's UI elements - image view, label and favourite button
    @IBOutlet weak var imageView1: UIImageView!
    @IBOutlet weak var label1: UILabel!
    @IBOutlet weak var favButton: UIButton!
    
    // Function for when the favourite button is pressed
    @IBAction func favourite(_ sender: Any) {
        
        // Gets the view controller containing the cell
        let viewController = findViewController()! as! ViewController
        if let currentPlant = currentPlant {
            
            // Checks if current plant is a favourite, removes or adds it accordingly
            let curRecnum = currentPlant.recnum
            if viewController.checkIfFav(recnum: curRecnum) {
                viewController.removeFav(recnum: curRecnum)
            } else {
                viewController.saveFav(recnum: curRecnum)
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}

// Extending UIView to define a recursive function that finds the View Controller containing the current element
extension UIView {
    func findViewController() -> UIViewController? {
        if let nextResponder = self.next as? UIViewController {
            return nextResponder
        } else if let nextResponder = self.next as? UIView {
            return nextResponder.findViewController()
        } else {
            return nil
        }
    }
}
