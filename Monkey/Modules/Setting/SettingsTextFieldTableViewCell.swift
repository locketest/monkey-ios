//
//  SettingsTextFieldTableViewCell.swift
//  Monkey
//
//  Created by Isaiah Turner on 4/28/17.
//  Copyright © 2017 Monkey Squad. All rights reserved.
//

import Foundation
import Alamofire
class SettingsTextFieldTableViewCell: SettingsTableViewCell, UITextFieldDelegate {
    /// Button
    @IBOutlet weak var editSaveButton: UIButton!
    @IBOutlet weak var hashtagField: UITextField!
    
    /// The text of the hashtag field without the # prefix
    var hashtagText : String {
        return hashtagField.text!.replacingOccurrences(of: "#", with: "")
    }
    
    weak var delegate : SettingsHashtagCellDelegate?
    
    @IBAction func editSavePressed(_ sender: Any) {
        if hashtagField.isFirstResponder {
            // User already is editing. Save pressed.
            hashtagField.resignFirstResponder()
        } else {
            // User is not editing. Begin editing.
            hashtagField.becomeFirstResponder()
        }
    }
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField.text == "" {
            // If user begins editing empty cell, replace placeholder with beginning of hashtag to encourage interaction instead of typing over placeholder
            textField.text = "#"
        }
        editSaveButton.setTitle("Save", for: .normal)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        editSaveButton.setTitle("Edit", for: .normal)
        if textField.text == "#" {
            // User didn't set a hashtag or erased the current hashtag. Ensure placeholder is shown.
            textField.text = ""
        }
        updateHashtag(hashtagText)
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        // We only support lowercase a-z.
        let supportedCharacters = NSCharacterSet(charactersIn:"abcdefghijklmnopqrstuvwxyz").inverted
        let compSepByCharInSet = string.components(separatedBy: supportedCharacters)
        let safeString = compSepByCharInSet.joined(separator: "")
        
        if range.location == 0 {
            print("range: \(range.location)\nstring: \(safeString)")
            textField.text = "#" + string
            return false
        }
        
        return string == safeString
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        updateHashtag(hashtagText)
        return true
    }
    
    
    /**
     Sends selected hashtag preference to server
     - parameter text: the hashtag
     */
    func updateHashtag(_ text: String) {
        RealmTag.fetchAll(parameters: [
            "filter[name]": text,
            ]) { (result: JSONAPIResult<[RealmTag]>) in
                switch result {
                case .success(let tags):
                    self.set(tag: tags.first)
                case .error(let error):
                    self.delegate?.showAlert(alert: error.toAlert(onRetry: { (action) in
                        self.updateHashtag(text)
                    }))
                }
        }
    }
    
    func set(tag: RealmTag?) {
        
        // self.delegate?.selectedHashtag(id: tag.tag_id, tag: tag.name)
        
        APIController.shared.currentUser?.update(attributes: [
            .tag(tag)
        ]) { (error: APIError?) in
            guard error == nil else {
                print(error!)
                return
            }
        }
    }
}
