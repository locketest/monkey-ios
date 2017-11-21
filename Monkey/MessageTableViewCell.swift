//
//  MessageTableViewCell.swift
//  Monkey
//
//  Created by Harrison Weinerman on 7/10/17.
//  Copyright © 2017 Monkey Squad. All rights reserved.
//

import UIKit

class MessageTableViewCell: UITableViewCell {

    @IBOutlet weak var messageTextView: MakeTextViewGreatAgain!
    
    @IBOutlet weak var topPaddingConstraint: NSLayoutConstraint!
    @IBOutlet weak var bottomPaddingConstraint: NSLayoutConstraint!
    @IBOutlet weak var leadingPaddingConstraint: NSLayoutConstraint!
    @IBOutlet weak var trailingPaddingConstraint: NSLayoutConstraint!

    @IBOutlet weak var chatBubbleView: MakeUIViewGreatAgain!

    enum MessageType {
        case sending, receiving
    }
    
    var currentType: MessageType = .sending {
        didSet {
            if oldValue != currentType {
            
                switch currentType {
                case .sending:
                    self.chatBubbleView.backgroundColor = Colors.purple
                case .receiving:
                    self.chatBubbleView.backgroundColor = Colors.white(0.06)
                }
                
                self.setNeedsLayout()
            }
        }
    }

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.messageTextView.contentInset = .zero
        self.messageTextView.textContainerInset = UIEdgeInsets(top: 7, left: 8, bottom: 7, right: 4)
        self.messageTextView.setNeedsLayout()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    
    func sizeCell() {
     //   self.messageTextView.textContainerInset =
        let size = self.messageTextView.text.boundingRect(forFont: self.messageTextView.font!, constrainedTo: CGSize(width: 244, height: CGFloat.greatestFiniteMagnitude))
        
        var leadingSpace:CGFloat = 14
        var trailingSpace:CGFloat = 14
        
        let remainingSpace = self.bounds.width - size.width - (14 * 2) - self.messageTextView.textContainerInset.left - self.messageTextView.textContainerInset.right
        
        if self.currentType == .sending {
            leadingSpace = remainingSpace
        } else if self.currentType == .receiving {
            trailingSpace = remainingSpace
        }
        
        self.leadingPaddingConstraint.constant = leadingSpace
        self.trailingPaddingConstraint.constant = trailingSpace
        self.setNeedsLayout()
    }
    
}
