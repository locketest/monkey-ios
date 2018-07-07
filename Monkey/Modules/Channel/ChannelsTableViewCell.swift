//
//  ChannelsTableViewCell.swift
//  Monkey
//
//  Created by Isaiah Turner on 6/17/17.
//  Copyright © 2017 Monkey Squad. All rights reserved.
//

import UIKit
import RealmSwift

class ChannelsTableViewCell: UITableViewCell {
    @IBOutlet private var iconLabelContainer: MakeUIViewGreatAgain!
    @IBOutlet private var iconLabel: UILabel!
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var subtitleLabel: UILabel!
    private var channelName: String?
    /// Setting this will cause the view to lookup the channel in Realm and update the view with the data for the given channel ID.
    var channelId: String? {
        didSet {
            let realm = try? Realm()
            let channel = realm?.object(ofType: RealmChannel.self, forPrimaryKey: self.channelId)
            channelName = channel?.title
            self.titleLabel.text = channelName
            let subtitleText = { () -> String in
                let subtitleTemplate = channel?.subtitle ?? ""
                let usersOnline = channel?.users_online ?? 0
                let usersOnlineNumberFormatter = NumberFormatter()
                usersOnlineNumberFormatter.numberStyle = .decimal
                return subtitleTemplate.replacingOccurrences(of: "{{users_online}}", with: usersOnlineNumberFormatter.string(from: usersOnline as NSNumber) ?? "")
            }()
            self.subtitleLabel.text = subtitleText
            self.iconLabel.text = channel?.emoji
        }
    }
    
    override func layoutSubviews() {
        self.iconLabelContainer.cornerRadius = self.iconLabelContainer.frame.height / 2
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        self.iconLabelContainer.backgroundColor = selected ? .white : UIColor.init(red: 100.0/255.0, green: 74.0/255.0, blue: 241.0/255.0, alpha: 1.0)
        titleLabel.text = selected ? (channelName ?? "") + " 🌴" : channelName
        super.setSelected(selected, animated: animated)
    }
    
}
