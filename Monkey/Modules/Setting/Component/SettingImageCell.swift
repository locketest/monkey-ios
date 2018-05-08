//
//  SettingImageCell.swift
//  Monkey
//
//  Created by fank on 2018/5/3.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//  setting image cell

import UIKit

class SettingImageCell: UITableViewCell {

    @IBOutlet weak var itemLabel: UILabel!
    
    @IBOutlet weak var genderImageView: UIImageView!
    
    var settingModel : SettingModel {
        get {
            return SettingModel()
        }
        set(newSettingModel){
            
            self.selectionStyle = .none
            
            self.itemLabel.text = newSettingModel.textString
            
            switch Gender(rawValue: APIController.shared.currentUser?.show_gender ?? "") {
            case .male?:
                self.genderImageView.image = #imageLiteral(resourceName: "Guys")
            case .female?:
                self.genderImageView.image = #imageLiteral(resourceName: "Girls")
            default:
                self.genderImageView.image = #imageLiteral(resourceName: "GenderPreferenceButton")
            }
        }
        
    }
    
    func cellTappedFunc() {
        
        let alertController = UIAlertController(title: "Talk to", message: "Tap who you'd rather talk to", preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        alertController.addAction(UIAlertAction(title: "👫 Both", style: .default, handler: { (UIAlertAction) in
            APIController.shared.currentUser?.update(attributes: [.show_gender(nil)], completion: { $0?.log() })
            
            self.genderImageView.image = #imageLiteral(resourceName: "GenderPreferenceButton")
        }))
        
        alertController.addAction(UIAlertAction(title: "👱 Guys", style: .default, handler: { (UIAlertAction) in
            APIController.shared.currentUser?.update(attributes: [.show_gender("male")], completion: { $0?.log() })
            
            self.genderImageView.image = #imageLiteral(resourceName: "Guys")
            
            self.handleSubAlertFunc(isGirls: false)
        }))
        
        alertController.addAction(UIAlertAction(title: "👱‍♀️ Girls", style: .default, handler: { (UIAlertAction) in
            APIController.shared.currentUser?.update(attributes: [.show_gender("female")], completion: { $0?.log() })
            
            self.genderImageView.image = #imageLiteral(resourceName: "Girls")
            
            self.handleSubAlertFunc(isGirls: true)
        }))
        
        self.alertKeyAndVisibleFunc(alert: alertController)
    }
    
    func handleSubAlertFunc(isGirls:Bool) {
        
        let subAlert = UIAlertController(title: isGirls ? "👱‍♀️" : "👱", message: isGirls ? "This gives priority to talk to girls but not guaranteed 🆗" : "This gives priority to talk to guys but not guaranteed 🆗", preferredStyle: .alert)
        
        subAlert.addAction(UIAlertAction(title: "kk", style: .default, handler:nil))
        
        self.alertKeyAndVisibleFunc(alert: subAlert)
    }
    
    func alertKeyAndVisibleFunc(alert:UIAlertController) {
        let alertWindow = UIWindow(frame: UIScreen.main.bounds)
        alertWindow.rootViewController = AlertViewController()
        alertWindow.windowLevel = UIWindowLevelAlert
        alertWindow.makeKeyAndVisible()
        alertWindow.rootViewController?.present(alert, animated: true, completion: nil)
    }

}
