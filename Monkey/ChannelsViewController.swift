//
//  ChannelsViewController.swift
//  Monkey
//
//  Created by Isaiah Turner on 6/17/17.
//  Copyright © 2017 Monkey Squad. All rights reserved.
//

import UIKit
import RealmSwift

class ChannelsViewController: SwipeableViewController, UITableViewDelegate, UITableViewDataSource {
    private var channelsNotificationToken: NotificationToken?
    var channels: Results<RealmChannel>?

    @IBOutlet weak var tableView: UITableView!
    var selectedChannels : [RealmChannel] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .clear
        let realm = try? Realm()
        self.channelsNotificationToken = realm?.objects(RealmChannel.self).addNotificationBlock { (change) in
            self.tableView.reloadData()
        }
        self.channels = realm?.objects(RealmChannel.self).filter(NSPredicate(format: "is_active = true")).sorted(byKeyPath: "updated_at", ascending: true)
        
        RealmChannel.fetchAll { (result: JSONAPIResult<[RealmChannel]>) in
            switch result {
            case .success(_):
                break
            case .error(let error):
                error.log()
            }
        }
        
        if let channels = APIController.shared.currentUser?.channels {
            self.selectedChannels = Array(channels)
        }
        
        self.addBottomPadding()
    }
    
    /// Adds 14px spacing between last channel and its superview
    func addBottomPadding() {
        var insets = self.tableView.contentInset
        insets.bottom = 14
        self.tableView.contentInset = insets
    }
    
    override func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
       
        if (gestureRecognizer == self.tableView.panGestureRecognizer || otherGestureRecognizer == self.tableView.panGestureRecognizer) {
            return false
        }
        
        return super.gestureRecognizer(gestureRecognizer, shouldRecognizeSimultaneouslyWith: otherGestureRecognizer)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        updateChannels(selectedChannels: List(self.selectedChannels))
    }
    
    override func isSwipingDidChange() {
        self.tableView.isScrollEnabled = !self.isSwiping
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "channelCell", for: indexPath) as! ChannelsTableViewCell
        cell.backgroundColor = .clear
        cell.channelId = self.channels?[indexPath.row].channel_id
        return cell
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.channels.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let cell = tableView.cellForRow(at: indexPath) as! ChannelsTableViewCell
        let realm = try? Realm()
        guard let channel = realm?.object(ofType: RealmChannel.self, forPrimaryKey: cell.channelId) else {
            print("Error: could not get selected channel from Realm when selecting row.")
            return
        }
        
        self.selectedChannels.append(channel)
        self.updateChannels(selectedChannels: List(selectedChannels))
		
		AnaliticsCenter.log(withEvent: .joinedChannel, andParameter: [
			"channel_id": channel.channel_id ?? NSNull(),
			"channel_title": channel.title ?? NSNull(),
			"channel_subtitle": channel.subtitle ?? NSNull(),
			"channel_users_online": channel.users_online.value ?? NSNull(),
			"channel_emoji": channel.emoji ?? NSNull(),
			])
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        
        let cell = tableView.cellForRow(at: indexPath) as! ChannelsTableViewCell
       
        let realm = try? Realm()
        guard let channel = realm?.object(ofType: RealmChannel.self, forPrimaryKey: cell.channelId) else {
            print("Error: could not get selected channel from Realm when selecting row.")
            return
        }
        
        self.selectedChannels = self.selectedChannels.filter { $0 != channel }
        self.updateChannels(selectedChannels: List(selectedChannels))
        
    }
    
    func updateChannels(selectedChannels: List<RealmChannel>) {
        APIController.shared.currentUser?.update(attributes: [.channels(selectedChannels)], completion: { error in
            if let error = error {
                self.present(error.toAlert(onOK: nil), animated: true)
                print("Error: could not update RealmUser with currently selected channels. \(String(describing: error))")
                if let channels = APIController.shared.currentUser?.channels {
                    self.selectedChannels = Array(channels)
                    self.tableView.reloadData()
                }
                return
            }
        })
    }
    
    func tableView(_ tableView: UITableView, willDeselectRowAt indexPath: IndexPath) -> IndexPath? {
        
        if selectedChannels.count > 1 {
            return indexPath
        }
        return nil
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        guard let channelsCell = cell as? ChannelsTableViewCell else {
            return
        }
        
        let realm = try? Realm()
        guard let channel = realm?.object(ofType: RealmChannel.self, forPrimaryKey: channelsCell.channelId) else {
            return
        }
        
        if self.selectedChannels.contains(channel) {
            tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 64
    }
}
