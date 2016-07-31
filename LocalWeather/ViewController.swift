//
//  ViewController.swift
//  LocalWeather
//
//  Created by Teppo Hudson on 31/07/16.
//  Copyright © 2016 Fibo. All rights reserved.
//

import UIKit
import CoreLocation

class ViewController: UIViewController, CLLocationManagerDelegate {
    
    let apiKey = "1cc6bfed02e64a766e553fe760462b28"
    let locationManager = CLLocationManager()

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView?
    @IBOutlet weak var loadingIndicator: UILabel?
    @IBOutlet weak var errorIndicator: UILabel?
    @IBOutlet weak var weatherContainer: UIView?
    @IBOutlet weak var location: UILabel?
    @IBOutlet weak var currentDate: UILabel?
    @IBOutlet weak var weatherDescription: UILabel?
    @IBOutlet weak var weatherIcon: UIImageView?
    @IBOutlet weak var temperature: UILabel?
    @IBOutlet weak var humidity: UILabel?
    @IBOutlet weak var windlabel: UILabel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // at start we want to hide the weather data for smoother loading feel
        weatherContainer?.alpha = 0.0
        errorIndicator?.alpha = 0.0
        
        // Lets ask for Authorisation from the User.
        self.locationManager.requestAlwaysAuthorization()

        // This is for the use on the foreground
        self.locationManager.requestWhenInUseAuthorization()
        
        // For initialisation of the locationservice
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.requestLocation()
        }
        
        // for better ux lets add a reload button
        let refreshButton = UIButton()
        refreshButton.setTitle("RELOAD WEATHER", forState: .Normal)
        refreshButton.frame = CGRectMake(0, self.view.bounds.height-100, self.view.bounds.width, 100)
        refreshButton.backgroundColor = UIColor(red: 29/255, green: 210/255, blue: 255/255, alpha: 1)
        refreshButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        self.view.addSubview(refreshButton)
        refreshButton.addTarget(self, action: #selector(ViewController.reloadPressed), forControlEvents: .TouchUpInside)
        
    }

    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]){
        let userLocation:CLLocation = locations[0]
        let lat = userLocation.coordinate.latitude;
        let long = userLocation.coordinate.longitude;
        
        // everytime the locationManager gets a location lets query the weather API for data.
        let url = NSURL(string: "http://api.openweathermap.org/data/2.5/weather?lat=\(lat)&lon=\(long)&units=metric&appid=\(apiKey)")
        print(url)
        let request = NSURLRequest(URL: url!)
        let config = NSURLSessionConfiguration.defaultSessionConfiguration()
        let session = NSURLSession(configuration: config)

        let task = session.dataTaskWithRequest(request, completionHandler: {(data, response, error) in
            dispatch_async(dispatch_get_main_queue(), {
                if (error == nil) {
                    do {
                        var jsonResult: NSDictionary
                        try jsonResult = NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers) as! NSDictionary
                        print("AsSynchronous\(jsonResult)")
                        
                        
                        self.renderWeatherData(jsonResult)
                        
                        // here would also be good to load forecast data for the location, available from another api. Was not able to implement due to timelimit of the task
                        
                    }
                    catch {
                        // handle error
                    }
                }
                else
                {
                    print("Error: no data found")
                }
            })
        });
        
        task.resume()

    }

    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        UIView.animateWithDuration(1.5, animations: {
            self.errorIndicator?.alpha = 1.0
        })
    }
    
    func renderWeatherData(data:NSDictionary){
        // while the weatherContainer is still hidden to enable smooth display transition
        let date = NSDate()
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        currentDate?.text = dateFormatter.stringFromDate(date)

        location!.text = (data["name"] as! String)
        let weather = (data["weather"] as! NSArray)
        weatherDescription?.text = (weather[0]["description"] as! String).capitalizedString

        let weatherIconData = (weather[0]["icon"] as! String)
        let url = NSURL(string: "http://openweathermap.org/img/w/\(weatherIconData).png")
        //make sure the image in this url does exist, otherwise unwrap in a if let check
        let imagedata = NSData(contentsOfURL: url!)
        if let image = UIImage(data: imagedata!){
            weatherIcon!.image = image
        }
        
        // in the future it would be great to provide data also in fahrenheit
        let maintempdata = data["main"]

        // split the returned temp data, for design reasons.
        let maintemp = (maintempdata!["temp"] as! NSNumber).stringValue.componentsSeparatedByString(".")
        temperature?.text = maintemp[0]
        
        let humidityString = (maintempdata!["humidity"] as! NSNumber).stringValue
        humidity?.text = (string: "Humidity: \(humidityString)%")
        let winddata = data["wind"]
        let windspeedString = (winddata!["speed"] as! NSNumber).stringValue
        windlabel?.text = (string: "Wind: \(windspeedString)m/s")
        
        // We use animation for a smooth fade in of the data
        UIView.animateWithDuration(1.0, animations: {
            self.activityIndicator?.alpha = 0.0
            self.loadingIndicator?.alpha = 0.0
            self.weatherContainer?.alpha = 1.0
        })

    }
    
    func reloadPressed(){
        UIView.animateWithDuration(0.3, animations: {
            self.activityIndicator?.alpha = 1.0
            self.loadingIndicator?.alpha = 1.0
            self.weatherContainer?.alpha = 0.0
        })
        locationManager.requestLocation()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

