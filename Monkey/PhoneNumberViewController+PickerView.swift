//
//  PhoneNumberViewController+PickerView.swift
//  Monkey
//
//  Created by Isaiah Turner on 8/27/17.
//  Copyright © 2017 Monkey Squad. All rights reserved.
//

import Foundation
import Amplitude_iOS

extension PhoneNumberViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return self.countries.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        guard let country = self.countries?[row] else {
            print("Error: Unable to find country for the given picker view row.")
            return ""
        }
        return "\(country.emoji) \(country.name) +\(country.code)"
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.selectedCountry = self.countries?[row]
    }
}
