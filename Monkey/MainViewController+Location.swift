//
//  LocationExtension.swift
//  Monkey
//
//  Created by Jun Hong on 4/9/17.
//  Copyright © 2017 Monkey Squad. All rights reserved.
//

import CoreLocation
import AddressBookUI
import Contacts

/// Extension for location methods
extension MainViewController {
    
    func requestLocationPermissionIfUnavailable() {
        guard CLLocationManager.authorizationStatus() == .notDetermined else {
            // Location services already enabled (likely during onboarding).
            return
        }
        self.locationManager.requestWhenInUseAuthorization()
    }
    /**
     Attempts to sync location information to current user
     */
    func startUpdatingLocation() {
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
            locationManager.startUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            return
        }
        manager.stopUpdatingLocation()
        let latitude = location.coordinate.latitude
        let longitude = location.coordinate.longitude
        reverseGeocode(latitude: latitude, longitude: longitude){(address) in
            guard let address = address else {
                print("Failed to convert location to address")
                return
            }
            let attributes: [RealmUser.Attribute] = [
                .latitude(latitude),
                .longitude(longitude),
//                .latitude(41),
//                .longitude(-74),
                .address(address),
            ]
            APIController.shared.currentUser?.update(attributes: attributes, completion: {(error) in
                error?.log()
            })
        }
    }
    /**
     Convert lat/long into an address format
     */
    func reverseGeocode(latitude: CLLocationDegrees, longitude: CLLocationDegrees, completion: @escaping (String?) -> ()){
        let location = CLLocation(latitude: latitude, longitude: longitude)
        CLGeocoder().reverseGeocodeLocation(location, completionHandler: {(placemarks, error) -> Void in
            guard error == nil else {
                print("Error: Reverse geocoding failed.", error!.localizedDescription)
                completion(nil)
                return
            }
            guard let placemarks = placemarks else {
                print("Error: No placemarks found.")
                completion(nil)
                return
            }
            guard placemarks.count > 0 else {
                print("Error: No placemarks found.")
                completion(nil)
                return
            }
            let placemark = placemarks[0]
            let postalAddressFormatter = CNPostalAddressFormatter()
            postalAddressFormatter.style = .mailingAddress
            completion(postalAddressFormatter.string(from: CNMutablePostalAddress(placemark: placemark)))
        })
    }
    
}

