//
//  GeofenceAnnotation.swift
//  Locative
//
//  Created by Marcus Kida on 28/03/2016.
//  Copyright © 2016 Marcus Kida. All rights reserved.
//

import MapKit

class GeofenceAnnotation: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D

    init(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
    }
}