//
//  ViewController.swift
//  NessVisitorApp


import UIKit
import MapKit
import CoreLocation
import CoreData

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, MKMapViewDelegate, CLLocationManagerDelegate, UITextViewDelegate {
    
    // Outlets for UI elements - table, map, toggle/show bed annotations button
    @IBOutlet weak var myTable: UITableView!
    @IBOutlet weak var myMap: MKMapView!
    @IBOutlet weak var showBedsButton: UIButton!
    
    // Variables to store the current plant/bed/image datas being used
    var plantInfo: plantData?
    var bedInfo: bedData?
    var imageInfo: imageData?
    
    var plantImageDict: [String:[UIImage]] = [:]    // Dictionary that stores a plant recnum key with an array of associated images value
    var sectionInfos: [sectionInfo] = []            // Array of a 'sectionInfo' struct that contains all relevant information
                                                    // for each section in the table (bed ID, array plants in bed)
    var selPlant: plant?            // Variable to store the corresponding plant when a row is selected
    var favPlants: [String] = []    // Array of favourited plants recnums
    
    //MARK: Map related
    
    // Variables for map function
    var locationManager = CLLocationManager()
    var firstRun = true
    var startTrackingTheUser = false
    var bedsShowing = false
    
    // Function for when the user's location is updated
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Gets latitude and longitude of user
        let locationOfUser = locations[0]
        let latitude = locationOfUser.coordinate.latitude
        let longitude = locationOfUser.coordinate.longitude
        
        // Calls function to update the section order according to the new distance from the user
        updateBedOrders(latitude: latitude, longitude: longitude)
        
        let location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        
        // If it's the first time the map has appeared, initialise region
        if firstRun {
            firstRun = false
            
            // Sets up a small region so the user can view beds nearby
            let latDelta: CLLocationDegrees = 0.0010
            let lonDelta: CLLocationDegrees = 0.0010
            let span = MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
            let region = MKCoordinateRegion(center: location, span: span)
            self.myMap.setRegion(region, animated: true)
            _ = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(startUserTracking), userInfo: nil, repeats: false)
        }
        // Recenters on the user if tracking is on
        if startTrackingTheUser == true {
            myMap.setCenter(location, animated: true)
        }
    }
    
    // Function to set user tracking as on
    @objc func startUserTracking() {
        startTrackingTheUser = true
    }
    
    // Button method called when show beds button is pressed, toggles bed annotations on or off
    @IBAction func showBeds(_ sender: Any) {
        if bedsShowing {
            for annotation in myMap.annotations {
                myMap.removeAnnotation(annotation)
            }
        } else {
            addBedAnnotations()
        }
        bedsShowing = !bedsShowing
    }
    
    // Function that iterates through beds and adds an annotation to the map for each
    func addBedAnnotations() {
        if let bedInfo = bedInfo {
            for sect in sectionInfos {
                let bed = bedInfo.beds.first(where: {$0.bed_id == sect.sectBed})!
                let annotation = MKPointAnnotation()
                let coordinate = CLLocationCoordinate2D(latitude: Double(bed.latitude)!, longitude: Double(bed.longitude)!)
                annotation.coordinate = coordinate
                annotation.title = bed.name
                myMap.addAnnotation(annotation)
            }
        }
    }
    
    //MARK: Table related
    
    // Number of rows per section defined as the number of plants in that section
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sectionInfos[section].sectPlants.count
    }
    
    // Number of sections defined as the number of entries in sectionInfos
    func numberOfSections(in tableView: UITableView) -> Int {
        return sectionInfos.count
    }
    
    // Title of each section defined as the name of the bed associated with the bed ID in that section
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let info = sectionInfos[section]
        return bedInfo?.beds.first(where: {$0.bed_id == info.sectBed})?.name ?? "null"
    }
    
    // Function to set up each cell in the table
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "aCell", for: indexPath) as! CustomTableViewCell
        
        let info = sectionInfos[indexPath.section]                  // Gets relevant section info
        let currentPlant: plant = info.sectPlants[indexPath.row]    // Gets relevant plant info for row in section
        
        cell.currentPlant = currentPlant    // Updates the cell's 'currentPlant' attribute
        
        // Checks if the current plant is favourited and updates the cell's favourite button icon accordingly
        if favPlants.contains(currentPlant.recnum) {
            cell.favButton.setImage(UIImage(systemName: "star.fill"), for: .normal)
        } else {
            cell.favButton.setImage(UIImage(systemName: "star"), for: .normal)
        }
        
        // Retrieves relevant values from the current plant and adds them to a string to make the cell label
        var cellLabel = ""
        let potentialValues = ["Cultivar Name", "Vernacular Name", "Infraspecific Epithet", "Species", "Genus"]
        for property in currentPlant.getValues().filter({ potentialValues.contains($0.0) }) {
            if property.1 != "" {
                cellLabel += property.0 + ": " + property.1 + "\n"
            }
        }
        cell.label1.text = cellLabel
        
        if let image = plantImageDict[currentPlant.recnum] {
            // If the image is in the cache, load it
            cell.imageView1.image = image[0]
        } else {
            // Make sure old images aren't left displayed
            cell.imageView1.image = nil
            
            // Get any images for the current plant
            if let imageInfo = imageInfo, let i = imageInfo.images.first(where: {$0.recnum == currentPlant.recnum}) {
                
                let thumb = URL(string: "https://cgi.csc.liv.ac.uk/~phil/Teaching/COMP228/ness_thumbnails/" + i.img_file_name)!
                
                // Load the image and add it to the cache and display it
                URLSession.shared.dataTask(with: thumb) {
                    (data, response, err) in
                    if let data = data {
                        let image = UIImage(data:data)!
                        self.plantImageDict[i.recnum, default: []].append(image)
                        // Send the image back to the main thread to modify UI
                        DispatchQueue.main.async() {
                            cell.imageView1.image = image
                            self.myTable.reconfigureRows(at: [indexPath])
                        }
                    }
                }.resume()
            }
        }
        return cell
    }
    
    // Function for when a row is selected, passes selected plant to cell and performs segue to details view
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let info = sectionInfos[indexPath.section]
        selPlant = info.sectPlants[indexPath.row]
        performSegue(withIdentifier: "toDetail", sender: nil)
    }
    
    // Function to reload table data
    func updateTheTable() {
        myTable.reloadData()
    }
    
    //MARK: Data related
    
    // Generic function to decode JSON from a URL then call the next completion
    func getData<T>(_ type: T.Type, url: String, completion: @escaping (T) -> Void) where T: Decodable {
        let url = URL(string: url)!
        let session = URLSession.shared
        session.dataTask(with: url) { (data, response, err) in
            guard let jsonData = data else { return }
            do {
                let decoder = JSONDecoder()
                let decoded = try decoder.decode(type, from: jsonData)
                completion(decoded)
            } catch let jsonErr {
                print("Error decoding JSON", jsonErr)
            }
        }.resume()
    }
    
    // Function that calls getData to fill out plantInfo then call the next completion
    func getPlantData(completion: @escaping () -> Void) {
        getData(plantData.self, url: "https://cgi.csc.liv.ac.uk/~phil/Teaching/COMP228/ness/data.php?class=plants") {
            plantList in
            self.plantInfo = plantList
            completion()
        }
    }
    
    // Function to fill out bedInfo then call the next completion
    func getBedData(completion: @escaping () -> Void) {
        getData(bedData.self, url: "https://cgi.csc.liv.ac.uk/~phil/Teaching/COMP228/ness/data.php?class=beds") {
            bedList in
            self.bedInfo = bedList
            completion()
        }
    }
    
    // Function to fill out imageInfo then update table and call the next completion
    func getImageData(completion: @escaping () -> Void) {
        getData(imageData.self, url: "https://cgi.csc.liv.ac.uk/~phil/Teaching/COMP228/ness/data.php?class=images") {
            imageList in
            self.imageInfo = imageList
            // Function is not necessarily called before table is updated so update table
            DispatchQueue.main.async {
                self.updateTheTable()
            }
            completion()
        }
    }
    
    // Function to fill out sectionInfos then update table and call the next completion
    func buildSectionInfos(completion: @escaping () -> Void) {
        
        // Creates temporary variable of sectionInfos initialised to store the bed IDs with empty plant array
        var sections = bedInfo!.beds.map({sectionInfo(sectBed: $0.bed_id, sectPlants: [])})
        
        // Iterates through plants with accsta 'C'
        for aPlant in plantInfo!.plants.filter({$0.accsta == "C"}) {
            
            // Finds all bed IDs of each plant, iterates through them
            let plantBeds = aPlant.bed.components(separatedBy: .whitespaces)
            for pBed in plantBeds {
                
                // Finds section containing bed ID, adds plant to plant array
                if let bed = bedInfo!.beds.first(where: {$0.bed_id == pBed}) {
                    if let sect = sections.firstIndex(where: {$0.sectBed == bed.bed_id}) {
                        sections[sect].sectPlants.append(aPlant)
                    }
                }
            }
        }
        
        // Initialise the variable once ready so the UI doesn't try to use this data while it's being set up
        // Filters the sections to ones where the plant array is not empty
        sectionInfos = sections.filter({$0.sectPlants.count > 0})
        
        DispatchQueue.main.async {
            self.updateTheTable()
        }
        completion()
    }
    
    // Function to update the order that each bed should be displayed according to distance from user
    func updateBedOrders(latitude: CLLocationDegrees, longitude: CLLocationDegrees) {
        
        //Calculates the distance of each bed from the user and stores in a dictionary pointing from the section info to the distance
        var distances: [sectionInfo: Double] = [:]
        if let bedInfo = bedInfo {
            for curBed in bedInfo.beds {
                let distance = sqrt(pow((latitude-Double(curBed.latitude)!).magnitude, 2)
                                    + pow((longitude-Double(curBed.longitude)!).magnitude, 2))
                if let curSect = sectionInfos.first(where: {$0.sectBed == curBed.bed_id}) {
                    distances[curSect] = distance
                }
            }
            
            //Sorts the sectionInfos array by the distances, lowest to highest
            sectionInfos.sort(by: {distances[$0]! < distances[$1]!})
            updateTheTable()
        }
    }
    
    //MARK: Core Data Related
    
    // Retrieves data from a given entity and copies to relevant variable then calls next completion
    func fetchData(entity: String, completion: @escaping () -> Void) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: entity)
        
        do {
            if entity == "Plant" {
                // Sets plantInfo with core data, converting from the core data Plant type to the defined plant type
                let plants = try (managedContext.fetch(fetchRequest) as? [Plant])!.map(fromCoreData)
                plantInfo = plantData(plants: plants)
            } else if entity == "Bed" {
                // Sets bedInfo similarly, converting from Bed to bed
                let beds = try (managedContext.fetch(fetchRequest) as? [Bed])!.map(fromCoreData)
                bedInfo = bedData(beds: beds)
            } else if entity == "Favourite" {
                // Sets favPlants similarly, retrieving the stored recnum as a string
                let favs = try (managedContext.fetch(fetchRequest))
                favPlants = favs.map({ $0.value(forKey: "recnum") as! String })
            }
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        completion()
    }
    
    // Saves values in plantInfo to core data then calls next completion
    func savePlants(completion: @escaping () -> Void) {
        
        DispatchQueue.main.async {
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
                return
            }
            
            let managedContext = appDelegate.persistentContainer.viewContext
            
            // Iterates through plants, inserts a new object into core data, updates its attributes
            for plant in self.plantInfo!.plants {
                let ent = NSEntityDescription.insertNewObject(forEntityName: "Plant", into: managedContext)
                for (key, value) in plant.dictionary! {
                    ent.setValue(value, forKeyPath: key)
                }
            }
            // Saves changes
            do {
                try managedContext.save()
            } catch let error as NSError {
                print("Could not save. \(error), \(error.userInfo)")
            }
            completion()
        }
    }
    
    // Saves values in bedInfo to core data
    func saveBeds() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        
        // Iterates through beds, inserts a new object into core data, updates its attributes
        for bed in bedInfo!.beds {
            let ent = NSEntityDescription.insertNewObject(forEntityName: "Bed", into: managedContext)
            ent.setValue(bed.bed_id, forKeyPath: "bed_id")
            ent.setValue(bed.name, forKeyPath: "name")
            ent.setValue(bed.latitude, forKeyPath: "latitude")
            ent.setValue(bed.longitude, forKeyPath: "longitude")
            ent.setValue(bed.last_modified, forKeyPath: "last_modified")
        }
        // Saves changes
        do {
            try managedContext.save()
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }
    
    //-- Favourites functions
    
    // Checks if a plant recnum is in favPlants, returns true/false accordingly
    func checkIfFav(recnum: String) -> Bool {
        if favPlants.contains(recnum) {
            return true
        } else {
            return false
        }
    }
    
    // Saves a new favourite to core data and favPlants
    func saveFav(recnum: String) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        
        // Inserts a new object, sets its value to the given recnum
        let ent = NSEntityDescription.insertNewObject(forEntityName: "Favourite", into: managedContext)
        ent.setValue(recnum, forKeyPath: "recnum")
        
        // Saves to core data and adds to favPlants
        do {
            try managedContext.save()
            favPlants.append(recnum)
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
        updateTheTable()
    }
    
    // Removes a favourite from core data and favPlants
    func removeFav(recnum: String) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        
        // Creates a fetch to retrieve the NSManagedObject containing the given recnum
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName:"Favourite")
        fetchRequest.fetchLimit =  1
        fetchRequest.predicate = NSPredicate(format: "recnum = %@", recnum)
        
        // Removes the result of the fetch from core data and favPlants
        do {
            guard let fetchedResults =  try managedContext.fetch(fetchRequest) as? [NSManagedObject] else { return }
            managedContext.delete(fetchedResults[0])
            try managedContext.save()
            favPlants.removeAll(where: {$0 == recnum})
        } catch let error as NSError {
            print("Could not delete. \(error), \(error.userInfo)")
        }
        updateTheTable()
    }
    
    //MARK: View Related
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        // If going to the detail view, sets the selected plant and image info attributes
        if segue.identifier == "toDetail" {
            let ViewController = segue.destination as! DetailsViewController
            ViewController.selectedPlant = selPlant
            ViewController.imageInfo = imageInfo
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Make this view controller a delegate of the Location Manager, so that it is able to call functions provided in this view controller
        locationManager.delegate = self as CLLocationManagerDelegate
        // Set the level of accuracy for the user's location
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        // Ask the location manager to request authorisation from the user
        // Note that this only happens once if the user selects the "when in use" option
        // If the user denies access, then your app will not be provided with details of the user's location
        locationManager.requestWhenInUseAuthorization()
        // Once the user's location is being provided then ask for updates when the user moves around
        locationManager.startUpdatingLocation()
        // Configure the map to show the user's location (with a blue dot)
        myMap.showsUserLocation = true
        
        let launchedBefore = UserDefaults.standard.bool(forKey: "launchedBefore")
        if launchedBefore {
            
            // If the app has been launched previously, fetch from core data for plant, bed and favourites values and build section infos
            // Performed as a series of completions to ensure that values are set before functions calling them are run
            // Image data is fetched last in case there is no internet access
            fetchData(entity: "Plant", completion: {
                [self]() in fetchData(entity: "Bed", completion: {
                    [self]() in fetchData(entity: "Favourite", completion: {
                        [self]() in buildSectionInfos(completion: {
                            [self]() in getImageData(completion: {().self
                            })
                        })
                    })
                })
            })
        } else {
            
            // If it is the first time the app is run, get data from web service and build section infos
            // Then, save to core data and set launchedBefore to true
            getPlantData(completion: {
                [self]() in getBedData(completion: {
                    [self]() in getImageData(completion: {
                        [self]() in buildSectionInfos(completion: {
                            [self]() in savePlants(completion: {
                                [self]() in saveBeds()
                                UserDefaults.standard.set(true, forKey: "launchedBefore")
                            })
                        })
                    })
                })
            })
        }
    }
}



