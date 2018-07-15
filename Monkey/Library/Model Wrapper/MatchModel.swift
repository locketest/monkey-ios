//
//  MatchModel.swift
//  Monkey
//
//  Created by 王广威 on 2018/5/17.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//

import Foundation
import RealmSwift
import ObjectMapper
import ObjectMapperAdditions

class MonkeyUser: MonkeyModel {
	override class var type: String {
		return ApiType.MonkeyUser.rawValue
	}
	override static func primaryKey() -> String {
		return "user_id"
	}
	
	// user_od
	dynamic var user_id: Int = 0
	
	dynamic var age: Int = 18
	dynamic var birthday: Date?
	
	dynamic var gender: String?
	dynamic var first_name: String?
	dynamic var instagram_id: String?
	dynamic var snapchat_username: String?
	
	dynamic var bananas: Int = 0
	dynamic var photo_read_url: String?
	
	dynamic var enabled_two_p: Bool = false
	dynamic var unlocked_two_p: Bool = false
	dynamic var two_puser_group_type: Int = UnlockPlan.A.rawValue
	
	dynamic var city: String?
	dynamic var country: String?
	dynamic var address: String?
	dynamic var latitude: CGFloat = 0
	dynamic var longitude: CGFloat = 0
	
	dynamic var online: Bool = false
	
	// 用户资料是否完善
	func isCompleteProfile() -> Bool {
		var isCompleteProfile = true
		// birth_date 和 gender 没有视为资料不完善
		if self.birthday == nil || self.hasGender() == false {
			isCompleteProfile = false
		}
		return isCompleteProfile
	}
	
	// is same gender
	func isSameGender(with other: RealmUser) -> Bool {
		if self.gender == other.gender {
			return true
		}
		return false
	}
	
	// is same country
	func isSameCountry(with other: RealmUser) -> Bool {
		if self.country == other.location {
			return true
		}
		return false
	}
	
	// 是否是女生
	func isFemale() -> Bool {
		if self.gender == Gender.female.rawValue {
			return true
		}
		return false
	}
	// 是否是男生
	func isMale() -> Bool {
		if self.gender == Gender.male.rawValue {
			return true
		}
		return false
	}
	// 是否有性别
	func hasGender() -> Bool {
		if let gender = self.gender, gender.isEmpty == false {
			return true
		}
		return false
	}
	// 是否有名字
	func hasName() -> Bool {
		if let first_name = self.first_name, first_name.isEmpty == false {
			return true
		}
		return false
	}
	// 是否美国用户
	func isAmerican() -> Bool {
		var isAmerican = false
		if self.country == "United States" {
			isAmerican = true
		}
		return isAmerican
	}
	// 是否 monkey king
	func isMonkeyKing() -> Bool {
		var isMonkeyKing = false
		if self.user_id == 2 {
			isMonkeyKing = true
		}
		return isMonkeyKing
	}
	
	// 是否是好友
	func isFriend() -> Bool {
		let isFriendMatched = NSPredicate(format: "user.user_id == \"\(user_id)\"")
		let friendsShips = FriendsViewModel.sharedFreindsViewModel.friendships
		let friendMatched = friendsShips?.filter(isFriendMatched).first
		return friendMatched != nil
	}
	
	// 默认头像
	var defaultAvatar: String {
		if self.isFemale() {
			return "ProfileImageDefaultFemale"
		}else {
			return "ProfileImageDefaultMale"
		}
	}
	
	required convenience init?(map: Map) {
		if map["id"].currentValue == nil {
			return nil
		}
		self.init()
	}
	
	override func mapping(map: Map) {
		super.mapping(map: map)
		
		user_id			<- map["id"]
		
		age				<- map["age"]
		birthday		<- map["birthday"]
		
		gender			<- map["gender"]
		
		first_name			<- map["first_name"]
		instagram_id		<- map["instagram_id"]
		snapchat_username	<- map["snapchat_username"]
		
		bananas			<- map["bananas"]
		photo_read_url	<- map["photo_read_url"]
		
		enabled_two_p			<- map["enabled_two_p"]
		unlocked_two_p			<- map["unlocked_two_p"]
		two_puser_group_type	<- map["two_puser_group_type"]
		
		city			<- map["city"]
		country			<- map["country"]
		address			<- map["address"]
		latitude		<- map["latitude"]
		longitude		<- map["longitude"]
		
		online			<- map["online"]
	}
}

class MatchUser: MonkeyUser {
	// 远程画面展示
	var container: UIView?
	var renderContainer: UIView {
		if let container = self.container {
			return container
		}
		
		let container = UIView.init()
		self.container = container
		return container
	}
	
	/**
	*  是否加入到 agora 房间(可以接收房间内消息)
	*/
	var joined = false
	/**
	*  是否成功连接 agora(收到对方视频流)
	*/
	var connected = false {
		didSet {
			self.connectedTime = Date.init()
		}
	}
	var connectedTime: Date?
	/**
	*  是否对此用户点击了举报按钮
	*/
	var showReport = false
	/**
	*  是否举报了对方
	*/
	var report = false
	/**
	*  举报原因
	*/
	var reportReason: ReportType? {
		didSet {
			if reportReason != nil {
				self.report = true
			}
		}
	}
	/**
	*  是否被对方举报
	*/
	var reported = false
	/**
	*  是否主动发送了加好友请求
	*/
	var friendRequest = false
	/**
	*  是否先收到了对方加好友请求
	*/
	var friendRequested = false
	/**
	*  是否接受了加好友请求
	*/
	var friendAccept = false
	/**
	*  对方是否接受了加好友请求
	*/
	var friendAccepted = false

	/**
	*  是否点了 skip 了
	*/
	var skip = false {
		didSet {
			self.responseTime = Date.init()
		}
	}
	/**
	*  是否点了 accept 了
	*/
	var accept = false {
		didSet(oldValue) {
			guard self.responseTime == nil else {
				return
			}
			self.responseTime = Date.init()
		}
	}
	/**
	*  对方点击 accept/skip 的时间
	*/
	var responseTime: Date?
	/**
	*  发送的消息个数
	*/
	var sendedMessage = 0
	/**
	*  点击 add time 次数
	*/
	var addTimeCount = 0
	/**
	*  是否点击了 unmute
	*/
	var unMuteRequest = false

	// 是否与此人加成好友(当前 match 加成的好友)
	var friendAdded: Bool {
		return self.friendAccept || self.friendAccepted
	}
	// my user info
	var user_info: AdditionInfo?
	
	// 是否是好友
	var friendMatched: Bool {
		return self.friendAdded || self.isFriend()
	}
	
	// 是否有共同的 channel
	func commonChannel() -> RealmChannel? {
		if let currentChannel = UserManager.shared.currentUser?.channels.first, Int(currentChannel.channel_id) == user_info?.tree_id {
			return currentChannel
		}
		return nil
	}
	
	func showedBio() -> String {
		var showedBio = self.user_info?.bio ?? "connecting"
		if let convertBio = showedBio.removingPercentEncoding {
			showedBio = convertBio
			if RemoteConfigManager.shared.app_in_review == true {
				let ceil: Int = 19
				let digitsSet = CharacterSet.decimalDigits.inverted
				let components: [String] = convertBio.components(separatedBy: digitsSet)

				if let user_age_str: String = components.first, let age_range: Range = convertBio.range(of: user_age_str), let user_age: Int = Int(user_age_str) {
					if user_age < ceil {
						let randomAge: Int = Int.arc4random() % 5
						let new_age: Int = abs(randomAge) + ceil
						showedBio = convertBio.replacingCharacters(in: age_range, with: "\(new_age)")
					}
				}
			}
		}
		return showedBio
	}
	
	override class func ignoredProperties() -> [String] {
		return [
			"container",
		]
	}
	
	required convenience init?(map: Map) {
		self.init()
	}
	
	override func mapping(map: Map) {
		super.mapping(map: map)
		user_info		<- map["user_info"]
	}
}

// 对方的额外信息 与我的好友的关系
class AdditionInfo: MonkeyModel {
	override static func primaryKey() -> String {
		return "user_id"
	}
	
	// user_id
	var user_id: Int = 0
	// tree_id
	var tree_id: Int?
	// 需要展示的 bio
	var bio: String = "connecting"
	// 和我的 pair 对象的 friend_id
	var friendship: Bool = false
	
	// 是否和我的 pair 对象加成了好友
	var addFriendRequest: Bool = false
	var addFriendAccept: Bool = false
	
	// 是否和我的 pair 对象是好友
	var isFriendWithPair: Bool {
		return (addFriendRequest && addFriendAccept) || friendship
	}
	
	required convenience init?(map: Map) {
		if map["user_id"].currentValue == nil {
			return nil
		}
		self.init()
	}
	
	override func mapping(map: Map) {
		super.mapping(map: map)
		user_id			<- map["user_id"]
		tree_id			<- map["tree_id"]
		
		bio				<- map["bio"]
		friendship		<- map["friendship"]
	}
}

protocol VideoCallProtocol {
	// channel_name
	var channel_name: String { get }
	// channel_key
	var channel_key: String { get }
	
	// 是否支持 agora
	func supportAgora() -> Bool
	// 是否支持前置消息
	func supportSocket() -> Bool
	
	func allUserJoined() -> Bool
	
	func allUserAccepted() -> Bool
	
	func allUserConnected() -> Bool
	
	// 通过 user_id 拿到用户
	func matchedUser(with user_id: Int) -> MatchUser?
}

class ChannelModel: NSObject, Mappable, VideoCallProtocol {
	/**
	*  match id
	*/
	var match_id: String = ""
	/**
	*  channel media_key
	*/
	var channel_key: String = ""
	
	/**
	*  channel room id
	*/
	var channel_name: String = ""
	
	/**
	*  channel service
	*/
	var video_service: String = "agora"
	
	/**
	*  是否支持前置 accept 消息
	*/
	var notify_accept: Bool = false

	// 是否支持 agora
	func supportAgora() -> Bool {
		return video_service == "agora"
	}
	// uid 大的用户
	private(set) var left: MatchUser!
	// 是否是 video call
	var isVideoCall: Bool {
		return false
	}
	
	// create at
	var beginTime = Date.init()
	// 自己是否 skip 过
	var skip = false {
		didSet {
			self.responseTime = Date.init()
		}
	}
	// 自己是否 accept 过
	var accept = false {
		didSet {
			self.responseTime = Date.init()
		}
	}
	
	// 点击 accept/skip 的时间
	var responseTime: Date?
	
	// 我自己是否加入 channel 成功
	var joined: Bool = false {
		didSet {
			self.joinedTime = Date.init()
		}
	}
	
	//  加入房间成功的时间
	private(set) var joinedTime: Date?
	// 开始连接的时间
	private(set) var connectTime: Date?
	// 连接成功的世界
	private(set) var connectedTime: Date?
	// 断开连接的时间
	var disconnectTime: Date?
	// 聊天时间
	var chatDuration: TimeInterval = 0
	
	var match_room_mode: MatchMode {
		return .VideoMode
	}
	
	// 是否支持前置 accept 消息
	func supportSocket() -> Bool {
		return notify_accept
	}
	
	func allUserJoined() -> Bool {
		return self.left.joined
	}
	
	func allUserAccepted() -> Bool {
		return self.left.accept
	}
	
	func allUserConnected() -> Bool {
		return self.left.connected
	}
	
	func matchedUser(with user_id: Int) -> MatchUser? {
		if self.left.user_id == user_id {
			return self.left
		}
		return nil
	}

	required init?(map: Map) {
		if (map["channel_key"].currentValue == nil) || (map["channel_name"].currentValue == nil) || (map["match_id"].currentValue == nil) {
			return nil
		}
	}

	func mapping(map: Map) {
		match_id			<- map["match_id"]
		
		channel_key			<- map["channel_key"]
		channel_name		<- map["channel_name"]
		
		video_service		<- map["video_service"]
		notify_accept		<- map["notify_accept"]
	}
}

class VideoCallModel: ChannelModel {
	/**
	*  the other user
	*/
	var friend: MatchUser!
	// 是否是主动拨打出去的
	var call_out = true
	
	/**
	*  friendship for this call
	*/
	var friendship: RealmUser? {
		let threadSafeRealm = try? Realm()
		return threadSafeRealm?.object(ofType: RealmUser.self, forPrimaryKey: String.init(friend.user_id))
	}

	// create at
	var expire_time: Date?

	// 开始连接的时间
	override var connectTime: Date? {
		guard let myAcceptTime = responseTime, let leftAcceptTime = left.responseTime else {
			return nil
		}
		// 我和左边用户的 Connect time
		let connectTime: Date = max(myAcceptTime, leftAcceptTime)
		return connectTime
	}
	
	// connect 成功的时间
	override var connectedTime: Date? {
		guard let myAcceptTime = responseTime, let leftConnectedTime = left.connectedTime else {
			return nil
		}
		// 我和左边用户的 Connected time
		let connectedTime: Date = max(myAcceptTime, leftConnectedTime)
		return connectedTime
	}
	
	// disconnect 成功的时间
	var disconnectedTime: Date? {
		didSet {
			if let connectedTime = self.connectedTime, let disconnectedTime = self.disconnectedTime {
				self.chatDuration = disconnectedTime.timeIntervalSince1970 - connectedTime.timeIntervalSince1970
			}
		}
	}
	// video call 对象
	override var left: MatchUser! {
		return self.friend
	}
	// 是否是 dialedCall
	override var isVideoCall: Bool {
		return true
	}

	required init?(map: Map) {
		if map["friend"].currentValue == nil {
			return nil
		}
		super.init(map: map)
	}

	override func mapping(map: Map) {
		super.mapping(map: map)
		friend			<- map["friend"]

		expire_time		<- map["expire_time"]
	}
}

class MatchModel: ChannelModel {
	// request id 每个 match message 的唯一标识符，用于鉴别是否是当前正在请求的 match
	var request_id: String = ""
	// 当前是在 1p 还是 2p
	var match_type: Int = MatchType.Onep.rawValue
	// user
	var users: [MatchUser]!
	// 当前 group 是否是 pair
	func pair() -> Bool {
		return match_type == MatchType.Twop.rawValue
	}
	// 是否匹配到了 pair
	func matched_pair() -> Bool {
		return users.count == 2
	}
	
	// matched user
	override var left: MatchUser! {
		return users.first!
	}
	// right matched user
	var right: MatchUser? {
		if self.matched_pair() {
			return users.last
		}
		return nil
	}

	// 当前房间 mode
	override var match_room_mode: MatchMode {
		if self.matched_pair() {
			return .PairMode
		}
		
		if let selectedMatchMode = Achievements.shared.selectMatchMode, selectedMatchMode.rawValue == "\(match_mode)" {
			return selectedMatchMode
		}
		return .VideoMode
	}
	// 1 normal 2 text 3 event
	var match_mode: Int = Int(MatchMode.VideoMode.rawValue) ?? 1
	// event_mode_id
	var event_mode: String?
	
	// 与对方的距离
	var distance: Int = 0
	// biography to show for next match
	var fact: String?
	
	
	// 收发消息的次数(文本消息)
	var sendedMessages = 0
	// 加成时间的次数
	var addTimeRequestCount = 0
	// 是否 unmute
	var unMuteRequest = false
	
	// 开始连接的时间
	override var connectTime: Date? {
		guard let myAcceptTime = responseTime, let leftAcceptTime = left.responseTime else {
			return nil
		}
		// 我和左边用户的 Connect time
		let connectTime: Date = max(myAcceptTime, leftAcceptTime)
		// 如果匹配到 1p
		guard matched_pair() else { return connectTime }
		// 匹配到 2p
		if let rightAcceptTime = right?.responseTime {
			return max(rightAcceptTime, connectTime)
		}else {
			return nil
		}
	}
	
	// connect 成功的时间
	override var connectedTime: Date? {
		guard let myAcceptTime = responseTime, let leftConnectedTime = left.connectedTime else {
			return nil
		}
		// 我和左边用户的 Connected time
		let connectedTime: Date = max(myAcceptTime, leftConnectedTime)
		// 如果匹配到 1p
		guard matched_pair() else { return connectedTime }
		// 匹配到 2p
		if let rightConnectedTime = right?.connectedTime {
			return max(rightConnectedTime, connectedTime)
		}else {
			return nil
		}
	}
	
	// 其他所有人进入房间
	override func allUserJoined() -> Bool {
		var joined = left.joined
		if matched_pair() {
			joined = joined && (right?.joined ?? false)
		}
		return joined
	}
	
	//  其他所有用户全都 accept
	override func allUserAccepted() -> Bool {
		var accepted = left.accept
		if matched_pair() {
			accepted = accepted && (right?.accept ?? false)
		}
		return accepted
	}
	
	// 收到其他所有人的推流
	override func allUserConnected() -> Bool {
		var connected = left.connected
		if matched_pair() {
			connected = connected && (right?.connected ?? false)
		}
		return connected
	}
	
	// 根据 user_id 获取用户
	override func matchedUser(with user_id: Int) -> MatchUser? {
		for user in self.users {
			if user.user_id == user_id {
				return user
			}
		}
		return nil
	}
	
	// 是否开启了声音
	func isUnmuted() -> Bool {
		return left.unMuteRequest && self.unMuteRequest
	}
	// 是否点击过举报
	func isShowReport() -> Bool {
		return left.showReport || (right?.showReport ?? false)
	}
	// 是否举报了对方
	func isReportPeople() -> Bool {
		return left.report || (right?.report ?? false)
	}
	// 是否被举报了
	func isReportedPeople() -> Bool {
		return left.reported || (right?.reported ?? false)
	}
	
	// 加时间成功次数
	func addTimeCount() -> Int {
		let addTimeCount = min(addTimeRequestCount, left.addTimeCount)
		return addTimeCount
	}
	// 是否加成好友
	func friendAdded() -> Bool {
		return left.friendAdded || (right?.friendAdded ?? false)
	}
	// bio
	func showedBio(for user: Int) -> String {
		let showedBio: String? = self.matchedUser(with: user)?.showedBio()
		var bio: String = showedBio ?? ""

		if self.distance > 0, self.matched_pair() == false, self.pair() == false, Achievements.shared.nearbyMatch == true {
			bio = bio.appending("\n🏡\(self.distance)m")
		}
		return bio
	}
	
	required init?(map: Map) {
		// users 不存在
		if (map["users"].currentValue is [[String: Any]]) == false {
			return nil
		}
		super.init(map: map)
	}

	override func mapping(map: Map) {
		super.mapping(map: map)
		request_id		<- map["request_id"]
		users			<- map["users"]
		
		distance		<- map["distance"]

		match_type		<- map["match_type"]
		match_mode		<- map["match_mode"]
		event_mode		<- map["event_mode"]
		fact			<- map["fact"]
	}
}

class FriendPairModel: ChannelModel {
	var friend: MatchUser!
	var pair_id: String = ""

	override var left: MatchUser! {
		return friend
	}
	
	// 我是否收到了 twop match
	var myConfirmPair: String?
	// 好友是否收到了 twop match
	var friendConfirmPair: String?
	// 如果有 match_pair_id
	func confirmMatch() -> Bool {
		if let match_pair_id = myConfirmPair, match_pair_id == friendConfirmPair {
			return true
		}
		return false
	}
	
	func resetConfirm() {
		self.myConfirmPair = nil
		self.friendConfirmPair = nil
	}

	// 向好友发送 确认离开 消息(先确认完毕的人发送完不能直接离开房间，要等对方发送或者收到对方离开的回调；后确认完毕的人收到此消息后向对方发送此消息，然后直接离开房间)
	func shouldConnectPair() -> Bool {
		if let match_pair_id = self.myConfirmPair {
			if match_pair_id == self.friendConfirmPair {
				return true
			}
			if self.friend.joined == false {
				return true
			}
		}
		return false
	}
	
	required init?(map: Map) {
		// users 不存在
		if (map["friend"].currentValue is [String: Any]) == false || map["pair_id"].currentValue == nil {
			return nil
		}
		super.init(map: map)
	}
	
	override func mapping(map: Map) {
		super.mapping(map: map)
		pair_id		<- map["pair_id"]
		friend		<- map["friend"]
	}
}
