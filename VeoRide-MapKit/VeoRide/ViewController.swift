//
//  ViewController.swift
//  VeoRide
//
//  Created by zijia on 9/20/19.
//  Copyright © 2019 zijia. All rights reserved.
//

import UIKit
import MapKit

class ViewController: UIViewController, BottomViewControllerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var bottomView: UIView!
    @IBOutlet weak var startButton: UIButton!
    @IBAction func startButtonClicked(_ sender: Any) {
        navigating = true
    }
    
    var locationManager: CLLocationManager!
    var annotations = [MKAnnotation]()
    var polylines = [MKPolyline]()
    var defaultCamera = MKMapCamera()
    var destinationCoordinate = CLLocationCoordinate2D()
    var bottomVC: BottomViewController?
    
    lazy var navigateCamera: MKMapCamera = { [weak self] in
        let camera = self!.mapView.camera
        camera.altitude = 700
        camera.pitch = 45
        return camera
    }()
    
    var navigating = false {
        didSet {
            if navigating == true {
                bottomView.isHidden = false
                startButton.isHidden = true
                locationManager.startUpdatingHeading()
                locationManager.startUpdatingLocation()
            } else {
                mapView.camera = defaultCamera
                bottomView.isHidden = true
                startButton.isHidden = false
                locationManager.startUpdatingLocation()
                locationManager.stopUpdatingHeading()
            }
        }
    }
    
    
    func bottomViewControllerDelegateCancelButtonClicked() {
        navigating = false
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let viewController = segue.destination as? BottomViewController {
            bottomVC = viewController
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        bottomVC?.delegate = self
        defaultCamera = mapView.camera
        
        startButton.isHidden = true
        bottomView.isHidden = true
        
        mapView.showsUserLocation = true
        mapView.delegate = self
        mapView.setUserTrackingMode(.followWithHeading, animated: true)
        
        let uilgr = UILongPressGestureRecognizer(target: self, action: #selector(recognizeLongPress))
        uilgr.minimumPressDuration = 1
        mapView.addGestureRecognizer(uilgr)
        
        if (CLLocationManager.locationServicesEnabled()) {
            locationManager = CLLocationManager()
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.requestAlwaysAuthorization()
            locationManager.startUpdatingLocation()
        }
    }
    
    @objc private func recognizeLongPress(_ sender: UILongPressGestureRecognizer) {
        
        if sender.state != UIGestureRecognizer.State.began {
            return
        }
        
        mapView.removeAnnotations(annotations)
        mapView.removeOverlays(polylines)
        
        let location = sender.location(in: mapView)
        let myCoordinate: CLLocationCoordinate2D = mapView.convert(location, toCoordinateFrom: mapView)
        destinationCoordinate = myCoordinate
        
        let myPin: MKPointAnnotation = MKPointAnnotation()
        myPin.coordinate = myCoordinate
        myPin.title = "Destination"
        
        annotations.append(myPin)
        mapView.addAnnotation(myPin)
        
        getRoute(myCoordinate)
    }
    
    func getRoute(_ destinationCoordinate: CLLocationCoordinate2D) {
        
        mapView.removeOverlays(polylines)
        
        let sourceCoordinate = locationManager.location?.coordinate
        
        let sourcePlacemark = MKPlacemark(coordinate: sourceCoordinate!)
        let destPlacemark = MKPlacemark(coordinate: destinationCoordinate)
        
        let sourceItem = MKMapItem(placemark: sourcePlacemark)
        let destItem = MKMapItem(placemark: destPlacemark)
        
        let directionRequest = MKDirections.Request()
        directionRequest.requestsAlternateRoutes = true
        directionRequest.source = sourceItem
        directionRequest.destination = destItem
        directionRequest.transportType = .any
        
        let direction = MKDirections(request: directionRequest)
        direction.calculate { (response, err) in
            guard let response = response else {
                print("Something is Wrong")
                return
            }

            guard let route = response.routes.first else {
                print("Something is Wrong")
                return
            }
            
            
            for step in route.steps {
                print(step.instructions)
                print(step.distance)
            }

            if  route.steps.count > 1, let bottomVC = self.bottomVC {
                let step = route.steps[1]
                print(step.instructions)
                let data = Turndata(instruction: step.instructions, distance: Double(step.distance), totleDistance: Double(route.distance), totleTime: route.expectedTravelTime)
                bottomVC.datas = data
            }

            self.startButton.isHidden = false

            self.polylines.append(route.polyline)
            self.mapView.addOverlay(route.polyline, level: .aboveRoads)

            let rekt = route.polyline.boundingMapRect
            self.mapView.setRegion(MKCoordinateRegion.init(rekt), animated: true)

        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let render = MKPolylineRenderer(overlay: overlay)
        render.strokeColor = UIColor.blue
        render.lineWidth = 3
        return render
    }

}

extension ViewController: CLLocationManagerDelegate {

    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        mapView.camera.heading = newHeading.magneticHeading
        mapView.camera.altitude = 700
        mapView.camera.pitch = 45
        mapView.setCamera(mapView.camera, animated: true)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        if navigating == true {
            if let location = locations.last{
                let center = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
                self.mapView.setCenter(center, animated: true)
            }
        }
        
        if navigating == false {
            if let location = locations.last{
                let center = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
                let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
                self.mapView.setRegion(region, animated: true)
            }
            locationManager.stopUpdatingLocation()
        }
       
    }
}


extension ViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let annotation = view.annotation else {
            return
        }
        
        let directionRequest = MKDirections.Request()
        directionRequest.source = MKMapItem.forCurrentLocation()
        directionRequest.destination = MKMapItem(placemark: MKPlacemark(coordinate: annotation.coordinate))
        directionRequest.transportType = .automobile
        let directions = MKDirections(request: directionRequest)
        
        directions.calculate {
            (response, error) -> Void in
            guard let response = response else {
                if let error = error {
                    print("Error: \(error)")
                }
                return
            }
            
            if !response.routes.isEmpty {
                let route = response.routes[0]
                DispatchQueue.main.async { [weak self] in
                    self?.mapView.addOverlay(route.polyline)
                }
            }
        }
    }
}

