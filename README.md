# Navigation-Test

This project can be very challenging and may take a long time depends on how well we want to build. Based on my experience, I tried two ways to implement this project to let you see the differences.

## method 1 - MapKit
* Mapkit is a very powerful framework in iOS development, specailly when Displaying map or satelliting imagery from your app's interface, calling out points of interest, and determining placemark information for map coordinates.
* But, Getting real time navigation instructions is `not allowed` by using Mapkit, and it is hard to get callback when user reached the destination. Takes too long to build a real time navigation by using Mapkit.
* Steps:
  1. Required User location in Info.plist
  2. Add MKMapView
  3. Show user location
  4. Implement locationManagerdelegate, and start updating user location
  5. Add UILongPressGestureRecognizer into mapView
  6. Get route and add polyline on the mapView
  7. Change mapView.camera.heading when didUpdateingHeading was called after user click start navigation.

  
![](https://github.com/zijiazhai/Navigation-Test/blob/master/mapkit.gif)
## method 2 - Mapbox Navigation
* Mapbox Navigation is a very powerful framework to allow users to view their traveled path in real time, to get real time instructions, such as: travele path, trip time, trip distance ...
* Also, user experience features, such as: GPS signal, or path recalculations are included.
* Steps:
  1. Read Mapbox Documents carefully because it is a much more complex framework than Mapkit
  2. Get a Mapbox API key

![](https://github.com/zijiazhai/Navigation-Test/blob/master/mapbox.gif)
