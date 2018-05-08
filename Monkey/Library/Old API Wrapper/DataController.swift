//
//  DataController.swift
//  Monkey
//
//  Created by Gabriel Duemichen on 8/30/17.
//  Copyright © 2017 Monkey Squad. All rights reserved.
//

import UIKit
import CoreData

class DataController: NSObject {
    @nonobjc static var sharedInstance = DataController()
    /// The name of the persistent store file
    static let storeName = "Monkey.sqlite"
    /// The URL of where the store file is located in documents
    private var storeURL: URL {
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let docURL = urls[urls.endIndex - 1]
        return docURL.appendingPathComponent(DataController.storeName)
    }
    override private init() {
        super.init()
        DispatchQueue.global().async {
            do {
                let fileManager = FileManager.default
                if fileManager.fileExists(atPath: self.storeURL.path) {
                    try fileManager.removeItem(at: self.storeURL)
                }
            } catch {
                print("Error: Failed to delete old monkey core data file")
            }
        }
    }
}
