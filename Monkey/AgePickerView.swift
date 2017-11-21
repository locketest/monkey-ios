//
//  AgePickerView.swift
//  Monkey
//
//  Created by Isaiah Turner on 3/25/17.
//  Copyright © 2017 Isaiah Turner. All rights reserved.
//

import Foundation
/**
 A UIPickerView prepopulated with valid ages.
 */
@IBDesignable class AgePickerView: UIPickerView, UIPickerViewDelegate {
    private let minAge = 13
    private let maxAge = 169
    
    /// The currently selected age.
    private(set) var selectedAge: Int = APIController.shared.currentExperiment?.default_age.value ?? 18 {
        didSet {
            self.didSelect?(selectedAge)
        }
    }
    
    /// Called when the selected age changes.
    var didSelect: ((_ age: Int) -> Void)? {
        didSet {
            // Call with the current value whenever a hook is added.
            self.didSelect?(selectedAge)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.afterInit()
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.afterInit()
    }
    
    private func afterInit() {
        self.delegate = self
        self.select(age: selectedAge)
    }
    
    internal func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return maxAge - minAge + 1
    }
    
    internal func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    internal func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return "\(row + minAge)"
    }
    
    internal func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.selectedAge = row + minAge
    }
    /**
     Selects the appropriate row for an age in the picker without animation.
     - parameters:
        - age: The age to select in the picker view.
     */
    func select(age: Int) {
        self.selectedAge = age
        self.selectRow(self.selectedAge - minAge, inComponent: 0, animated: false)
    }
}
