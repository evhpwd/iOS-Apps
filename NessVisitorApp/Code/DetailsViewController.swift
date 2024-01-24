//
//  DetailsViewController.swift
//  NessVisitorApp

import UIKit
import MapKit
import WebKit

class DetailsViewController: UIViewController {
    
    // Variables to store the selected plant and all image data
    var selectedPlant: plant?
    var imageInfo: imageData?
    
    // Outlets for UI elements - web view, map
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var plantMapView: MKMapView!
    
    // Function to set up the web view with data from selected plant
    func setupWebView() {
        if let selectedPlant = selectedPlant {
            
            // Initial values to store HTML string
            var myString = "<html><body style=\"font-family:verdana;font-size:30px\";>"
            
            // Iterates through plant values, adding the property name and value to the string with formatting
            for property in selectedPlant.getValues() {
                myString += "<p>"
                myString += "<b>" + property.0 + ":</b> "
                if property.1 == "" {
                    myString += "No information."
                } else {
                    myString += property.1
                }
                myString += "</p>"
            }
            
            // Gets any associated images and adds them to the string with HTML formatting
            if let images = imageInfo?.images {
                for i in images.filter({$0.recnum == selectedPlant.recnum}) {
                    myString += "<img src=\"" + i.img_file_name + "\" style=\"object-fit:contain;width:49%;border: solid 1px #CCC;\">"
                }
            }
            myString += "</body></html>"
            
            // Loads the string to the web view with the images url as a base
            webView.loadHTMLString(myString, baseURL: URL(string:  "https://cgi.csc.liv.ac.uk/~phil/Teaching/COMP228/ness_images/")!)
        }
    }
    
    func showLocation() {
        if let selectedPlant = selectedPlant {
            
            // Checks if latitude and longitude of selected plant are not null nor empty
            if let latitude = selectedPlant.latitude, let longitude = selectedPlant.longitude {
                if latitude != "" && longitude != "" {
                    
                    // Sets a wide region so the user can see the general area the plant is located in
                    let span = MKCoordinateSpan(latitudeDelta: 15, longitudeDelta: 15)
                    let coordinate = CLLocationCoordinate2D(latitude: Double(latitude)!, longitude: Double(longitude)!)
                    let region = MKCoordinateRegion(center: coordinate, span: span)
                    plantMapView.setRegion(region, animated: true)
                    
                    // Adds an annotation to the plant coordinate with a label displaying either the sgu or country
                    let annotation = MKPointAnnotation()
                    annotation.coordinate = coordinate
                    if let title = selectedPlant.sgu {
                        annotation.title = title
                    } else {
                        annotation.title = selectedPlant.country
                    }
                    plantMapView.addAnnotation(annotation)
                    
                    // Unhides the map
                    plantMapView.isHidden = false
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Sets the map view to hidden initially
        plantMapView.isHidden = true
        
        setupWebView()
        showLocation()
    }
}
