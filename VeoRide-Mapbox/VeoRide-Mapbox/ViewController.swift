//
//  ViewController.swift
//  VeoRide-Mapbox
//
//  Created by zijia on 9/20/19.
//  Copyright © 2019 zijia. All rights reserved.
//

import UIKit
import MapboxCoreNavigation
import MapboxNavigation
import MapboxDirections


private typealias RouteRequestSuccess = (([Route]) -> Void)
private typealias RouteRequestFailure = ((NSError) -> Void)

class ViewController: UIViewController, MGLMapViewDelegate {
    
    var simulating = false
    
    @objc func startButtonClicked(_ sender: Any) {
        simulating = false
        if let userRoute = userRoute {
            startNavigation(along: userRoute)
        }
    }
    
    @objc func simulateButtonClicked(_ sender: Any) {
        simulating = true
        if let userRoute = userRoute {
            startNavigation(along: userRoute)
        }
    }
    
    let startButton: UIButton = {
        let button = UIButton(frame: .zero)
        button.setTitle("start", for: .normal)
        button.setTitleColor(UIColor.white, for: .normal)
        button.backgroundColor = UIColor.blue
        button.addTarget(self, action: #selector(startButtonClicked(_:)), for: .touchUpInside)
        return button
    }()
    
    let simulateButton: UIButton = {
        let button = UIButton(frame: .zero)
        button.setTitle("Simulating", for: .normal)
        button.setTitleColor(UIColor.white, for: .normal)
        button.backgroundColor = UIColor.blue
        button.addTarget(self, action: #selector(simulateButtonClicked(_:)), for: .touchUpInside)
        return button
    }()
    
    func startNavigation(along route: Route) {
        let navigationViewController = NavigationViewController(for: route, navigationService: navigationService())
        self.present(navigationViewController, animated: true, completion: nil)
    }
    
    func navigationService() -> NavigationService? {
        guard let route = routes?.first else { return nil }
        let mode: SimulationMode = simulating == true ? .always : .never
        return MapboxNavigationService(route: route, directions: Settings.directions, simulating: mode)
    }
    
    var userRoute: Route? {
        get {return routes?.first}
        set {
            guard let selected = newValue else {
                routes?.remove(at: 0); return
            }
            guard let routes = routes else {
                self.routes = [selected]; return
            }
            self.routes = [selected] + routes.filter {
                $0 != selected
            }
        }
        
    }
    
    var routes: [Route]? {
        didSet {
            guard let routes = routes,
                let current = routes.first else { mapView.removeRoutes(); return }
            mapView.showRoutes(routes)
            mapView.showWaypoints(current)
        }
    }
    
    fileprivate lazy var defaultSuccess: RouteRequestSuccess = { [weak self] (routes) in
        guard let current = routes.first else { return }
        self?.mapView.removeWaypoints()
        self?.routes = routes
        self?.startButton.isHidden = false
        self?.simulateButton.isHidden = false
//        self?.waypoints = current.routeOptions.waypoints
    }
    
    fileprivate lazy var defaultFailure: RouteRequestFailure = { [weak self] (error) in
        print(self!.waypoints.count)
        self?.routes = nil //clear routes from the map
        print(error.localizedDescription)
    }
    
    lazy var mapView: NavigationMapView = { [weak self] in
        let mapView = NavigationMapView(frame: self!.view.bounds)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.delegate = self
        mapView.userTrackingMode = .follow
        mapView.logoView.isHidden = true
        mapView.showsUserLocation = true
        mapView.locationManager.startUpdatingLocation()
        
        let singleTap = UILongPressGestureRecognizer(target: self, action: #selector(didLongPress(tap:)))
        singleTap.minimumPressDuration = 1
        mapView.addGestureRecognizer(singleTap)
        
        return mapView
    }()
    
    var waypoints: [Waypoint] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(mapView)
        view.addSubview(startButton)
        startButton.anchor(top: nil, left: nil, bottom: view.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 50, paddingRight: 50, width: 100, height: 50)
        startButton.isHidden = true
        
        view.addSubview(simulateButton)
        simulateButton.anchor(top: nil, left: nil, bottom: view.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 120, paddingRight: 50, width: 100, height: 50)
        
        startButton.isHidden = true
        simulateButton.isHidden = true
    }
    
    @objc func didLongPress(tap: UILongPressGestureRecognizer) {
        guard tap.state == .began else { return }
        
        if let annotation = mapView.annotations?.last, waypoints.count > 2 {
            mapView.removeAnnotation(annotation)
        }
        
        if waypoints.count > 1 {
            waypoints = Array(waypoints.suffix(1))
        }
        
        let coordinates = mapView.convert(tap.location(in: mapView), toCoordinateFrom: mapView)
        let waypoint = Waypoint(coordinate: coordinates)
        waypoints.append(waypoint)
        
        requestRoute()
    }
    
    func requestRoute() {
        mapView.removeRoutes()
        guard waypoints.count > 0 else { return }
        
        let userWaypoint = Waypoint(location: mapView.userLocation!.location!, heading: mapView.userLocation?.heading, name: "User location")
        waypoints.insert(userWaypoint, at: 0)
        let options = NavigationRouteOptions(waypoints: waypoints)
        requestRoute(with: options, success: defaultSuccess, failure: defaultFailure)
        
        waypoints.removeAll()
    }
    
    fileprivate func requestRoute(with options: RouteOptions, success: @escaping RouteRequestSuccess, failure: RouteRequestFailure?) {
        
        let handler: Directions.RouteCompletionHandler = { (waypoints, routes, error) in
            if let error = error { failure?(error) }
            guard let routes = routes else { return }
            return success(routes)
        }
        Settings.directions.calculate(options, completionHandler: handler)
    }
}

struct Settings {
    
    static var directions: NavigationDirections = NavigationDirections()
    
    static var selectedOfflineVersion: String? = nil
    
}
