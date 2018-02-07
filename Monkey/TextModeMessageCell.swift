//
//  TextModeMessageCell.swift
//  Monkey
//
//  Created by 王广威 on 2018/2/6.
//  Copyright © 2018年 Monkey Squad. All rights reserved.
//

import UIKit

enum MessageDirection: String {
	case Send = "SendMessage"
	case Received = "ReceivedMessage"
}

class TextModeMessageCell: UITableViewCell {
	
	let textContent = UIView.init()
	let messageLabel = UILabel.init()
	var textMessage: TextMessage!
	
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
		
    }
	
	convenience init(direction: MessageDirection) {
		self.init(style: UITableViewCellStyle.default, reuseIdentifier: direction.rawValue)
		self.direction = direction
		configureDefaultAppearance()
	}
	
	override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		configureDefaultAppearance()
	}
	
	deinit {
		self.clearTypingStatus()
	}
	
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
	
	var direction = MessageDirection.Send
	var typingCount = 0
	
	func configureDefaultAppearance() {
		self.backgroundColor = UIColor.clear
		self.contentView.backgroundColor = UIColor.clear
		self.contentView.addSubview(textContent)
		textContent.layer.cornerRadius = 10
		textContent.layer.masksToBounds = true
		textContent.frame = CGRect.init(x: 8, y: 8, width: self.contentView.frame.size.width - 16, height: self.contentView.frame.size.height - 16)
		if direction == .Send {
			textContent.autoresizingMask = [.flexibleLeftMargin, .flexibleHeight]
			textContent.backgroundColor = UIColor.init(red: 150.0 / 255.0, green: 14.0 / 255.0, blue: 1, alpha: 1)
		}else {
			textContent.autoresizingMask = [.flexibleRightMargin, .flexibleHeight]
			textContent.backgroundColor = UIColor.init(red: 1, green: 1, blue: 1, alpha: 0.1)
		}
		
		textContent.addSubview(messageLabel)
		messageLabel.textColor = UIColor.white
		messageLabel.font = UIFont.systemFont(ofSize: 17)
		messageLabel.frame = CGRect.init(x: 10, y: 8, width: textContent.frame.size.width - 20, height: textContent.frame.size.height - 16)
		messageLabel.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		messageLabel.textAlignment = NSTextAlignment.left
		messageLabel.numberOfLines = 0
	}

	func configure(messageModel: TextMessage) {
		if let currentMessage = self.textMessage {
			if currentMessage.body == messageModel.body {
				return
			}
		}else {
			textMessage = messageModel
		}
		
		self.clearTypingStatus()
		self.configureApperance(with: messageModel)
	}
	
	func configureApperance(with message: TextMessage) {
		messageLabel.text = message.body
		
		let textContentWidth = message.textWidth + 20
		var textContentX: CGFloat = 8
		if direction == .Send {
			textContentX = contentView.frame.size.width - textContentWidth - 8
		}
		
		textContent.frame = CGRect.init(x: textContentX, y: 8, width: textContentWidth, height: self.contentView.frame.size.height - 16)
		
		
		if message.type == MessageType.Typing.rawValue {
			self.perform(#selector(makeTypingStatus), with: nil, afterDelay: 0.1)
		}
	}
	
	func makeTypingStatus() {
		let typingSubs = ["", ".", "..", "..."]
		let typingSub = typingSubs[typingCount % typingSubs.count]
		self.textMessage?.body = "Typing" + typingSub
		self.configureApperance(with: self.textMessage)
		typingCount = typingCount + 1
	}
	
	func clearTypingStatus() {
		NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(makeTypingStatus), object: nil)
		typingCount = 0
	}
}
