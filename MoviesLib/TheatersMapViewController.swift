//
//  TheatersMapViewController.swift
//  MoviesLib
//
//  Created by Usuário Convidado on 02/04/18.
//  Copyright © 2018 EricBrito. All rights reserved.
//

import UIKit
import MapKit

class TheatersMapViewController: UIViewController {

    //MARK: - IBOutlets
    @IBOutlet weak var mapView: MKMapView!
    
    //MARK: - Properties
    var currentElement: String!
    var theater: Theater!
    var theaters: [Theater] = []
    lazy var locationManager = CLLocationManager()
    var poiAnnotation: [MKPointAnnotation] = []
    
    
    //MARK: - Super methods
    override func viewDidLoad() {
        super.viewDidLoad()
        loadXML()
        
        requestUserLocationAuthorization()
    }
    
    //MARK: - Methods
    func loadXML(){
        guard let xml = Bundle.main.url(forResource: "theaters", withExtension: "xml"), let xmlParser = XMLParser(contentsOf: xml) else {return}
        xmlParser.delegate = self
        xmlParser.parse()
    }
    
    func addTheaters(){
        for theater in theaters {
            let coordinate = CLLocationCoordinate2D(latitude: theater.latitude, longitude: theater.longitude)
            let annotation = TheaterAnnotation(coordinate: coordinate, title: theater.name, subtitle: theater.address)
            
            mapView.addAnnotation(annotation)
        }
        mapView.showAnnotations(mapView.annotations, animated: true)
    }
    
    func requestUserLocationAuthorization(){
        if CLLocationManager.locationServicesEnabled(){
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            //locationManager.allowsBackgroundLocationUpdates = true
            locationManager.pausesLocationUpdatesAutomatically = true
            
            switch CLLocationManager.authorizationStatus(){
            case .authorizedAlways, .authorizedWhenInUse:
                print("usuario ja autorizaou o uso da localizacao")
            case .denied:
                print("Usuario negou a autorizacao")
            case .notDetermined:
                locationManager.requestWhenInUseAuthorization()
            case .restricted:
                print("Sifu!")
            }
        }
    }
}

//MARK: XML ParseDelegate
extension TheatersMapViewController: XMLParserDelegate{
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        
        if elementName == "Theater"{
            theater = Theater()
            
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        let content = string.trimmingCharacters(in: .whitespacesAndNewlines)
        if !content.isEmpty{
            switch currentElement{
            case "name":
                theater.name = content
            case "address":
                theater.address = content
            case "latitude":
                theater.latitude = Double(content)!
            case "longitude":
                theater.longitude = Double(content)!
            case "url":
                theater.url = content
            default:
                break
                
            }
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "Theater"{
            theaters.append(theater)
        }
    }
    
    func parserDidEndDocument(_ parser: XMLParser) {
        addTheaters()
    }
}

//MARK: MKMapViewDelegate
extension TheatersMapViewController: MKMapViewDelegate{
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        var annotationView: MKAnnotationView!
        
        if annotation is TheaterAnnotation{
            annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "Theater")
            if annotationView == nil{
                annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "Theater")
                annotationView.image = UIImage(named: "theaterIcon")
                annotationView.canShowCallout = true
            }else{
                annotationView.annotation = annotation
            }
        }
        
        return annotationView
    }
}

extension TheatersMapViewController: CLLocationManagerDelegate{
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status{
        case .authorizedAlways, .authorizedWhenInUse:
            mapView.showsUserLocation = true
        default:
            break
        }
    }
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        print("Velocidade do usuario:\(userLocation.location?.speed ?? 0)")
        
//        let region = MKCoordinateRegionMakeWithDistance(userLocation.coordinate, 500, 500)
//        mapView.setRegion(region, animated: true)
    }
}

extension TheatersMapViewController: UISearchBarDelegate{
    func searcgBarButtonClicked(_ searchBar: UISearchBar){
        let request = MKLocalSearchRequest()
        request.naturalLanguageQuery = searchBar.text!
        request.region = mapView.region
        let search = MKLocalSearch(request: request)
        search.start { (response, error) in
            if error == nil {
                guard let response = response else {return}
                self.mapView.removeAnnotations(self.poiAnnotation)
                self.poiAnnotation.removeAll()
                
                for item in response.mapItems{
                    let place = MKPointAnnotation()
                    place.coordinate = item.placemark.coordinate
                    place.title = item.name
                    place.subtitle = item.phoneNumber
                    self.poiAnnotation.append(place)
                }
                self.mapView.addAnnotations(self.poiAnnotation)
            }
        }
    }
}
