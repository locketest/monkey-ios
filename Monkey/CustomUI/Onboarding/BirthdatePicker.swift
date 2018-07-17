//
//  DOBPicker.swift
//  Monkey
//
//  Created by Harrison Weinerman on 5/7/17.
//  Copyright © 2017 Monkey Squad. All rights reserved.
//

import UIKit

class BirthdatePicker: UIDatePicker {

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.afterInit()
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.afterInit()
    }
    
    var formattedDate : String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        return dateFormatter.string(from: self.date)
    }
    
    private func afterInit() {
		self.maximumDate = NSCalendar.current.date(byAdding: .year, value: RemoteConfigManager.shared.app_in_review ? -18 : -13, to: Date())
        self.minimumDate = NSCalendar.current.date(byAdding: .year, value: -169, to: Date())
        // this date does not stay by the time viewdidload happens, unsure why, so manually setting this date on each VC that uses the class for now
		self.setDate(NSCalendar.current.date(byAdding: .year, value: RemoteConfigManager.shared.app_in_review ? -20 : -16, to: Date())!, animated: false)
        
        self.backgroundColor = .white
    }
}
