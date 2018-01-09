//
//  MakeTextViewGreatAgain.swift
//  Monkey
//
//  Created by Isaiah Turner on 10/14/16.
//  Copyright © 2016 Isaiah Turner. All rights reserved.
//

import UIKit
import Contacts
import CoreLocation
import RealmSwift
import Amplitude_iOS

@IBDesignable class MakeTextFieldGreatAgain: UITextField {
    @IBInspectable var lineColor = Colors.yellow {
        didSet {
            addSeparatorInputAccessory()
        }
    }
    @discardableResult override public func becomeFirstResponder() -> Bool {
        self.addSeparatorInputAccessory()
        return super.becomeFirstResponder()
    }
    
    @IBInspectable var selectable = true
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if action == #selector(copy(_:)) || action == #selector(selectAll(_:)) {
            return false
        }
        
        return true
    }
    func addSeparatorInputAccessory() {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 4))
        view.backgroundColor = self.lineColor
        self.inputAccessoryView = view
    }
    
    /// The width of the `leftView`, a transparent UIView with no content.
    @IBInspectable var leftPadding: CGFloat = 0 {
        didSet {
            if oldValue != 0 && self.leftPadding == 0 {
                self.leftView = nil
            }
        }
    }
    /// The width of the `rightView`, a transparent UIView with no content.
    @IBInspectable var rightPadding: CGFloat = 0 {
        didSet {
            if oldValue != 0 && self.rightPadding == 0 {
                self.rightView = nil
            }
        }
    }
    @IBInspectable var placeholderTextColor: UIColor = UIColor.gray.withAlphaComponent(0.7) {
        didSet {
            self.attributedPlaceholder = NSAttributedString(string: self.placeholder ?? "", attributes: [
                NSForegroundColorAttributeName: placeholderTextColor,
                NSFontAttributeName: self.font ?? UIFont.systemFont(ofSize: self.minimumFontSize)
                ])
        }
    }
    override func layoutSubviews() {
        if self.leftPadding != 0 && self.leftView?.bounds.width != self.leftPadding {
            self.leftView = self.makePaddingView(width: leftPadding)
            self.leftViewMode = .always
        }
        if self.rightPadding != 0 && self.rightView?.bounds.width != self.rightPadding {
            self.rightView = self.makePaddingView(width: rightPadding)
            self.rightViewMode = .always
        }
        super.layoutSubviews()
    }
    
    /// Creates a transparent view that fills the full height of the TextField.
    ///
    /// - Parameter width: The width of the view to create.
    /// - Returns: The view created.
    private func makePaddingView(width: CGFloat) -> UIView {
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: width, height: self.bounds.height))
        paddingView.backgroundColor = .clear
        return paddingView
    }
    
	override func delete(_ sender: Any?) {
		if let superclass = self.superclass {
			if superclass.instancesRespond(to: #selector(delete(_:))) {
				super.delete(sender)
			}
		}
    }

}

extension UITextField {
    var charactersCount: Int {
        return self.text?.count ?? 0
    }
}

class StopReverseEngineeringMonkeyAndAskForAJob {
    let ourEmail = "security@monkey.cool (PLEASE DONT PUBLISH SO I KNOW WHO THE SMARTEST PEOPLE ARE)"
    init() {
        
    }
}
@IBDesignable class MakeTextViewGreatAgain: UITextView {
    /// Don't forget to disable scrolling.
    @IBInspectable var isPaddingRemoved = false {
        didSet {
            if isPaddingRemoved {
                self.isScrollEnabled = false
                self.setNeedsLayout()
            }
        }
    }
    
    override func layoutSubviews() {
        if isPaddingRemoved {
            self.textContainerInset = UIEdgeInsets.zero
            self.textContainer.lineFragmentPadding = 0
        }
        super.layoutSubviews()
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
    }
    /// Sets text without removing styling if isSelectable is false
    func updateText(_ text: String) {
        let oldSelectable = self.isSelectable
        self.isSelectable = true
        self.text = text
        self.isSelectable = oldSelectable
    }
    func centerVertically() {
        let fittingSize = CGSize(width: bounds.width, height: CGFloat.greatestFiniteMagnitude)
        let size = sizeThatFits(fittingSize)
        let topOffset = (bounds.size.height - size.height * zoomScale) / 2
        let positiveTopOffset = max(1, topOffset)
        contentOffset.y = -positiveTopOffset
    }
    /*func boundingRect(constrainedTo size: CGSize) {
        let textSize = self.text.c
    }*/
}

@IBDesignable class MakeUIViewGreatAgain: UIView {
    
    @IBInspectable var cornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            layer.cornerRadius = newValue
            layer.masksToBounds = newValue > 0
        }
    }
    @IBInspectable var shadowRadius: CGFloat {
        get {
            return layer.shadowRadius
        }
        set {
            layer.shadowOffset = CGSize(width: 0, height: 0)
            layer.shadowColor = UIColor.black.cgColor
            layer.shadowOpacity = 0.4
            layer.shadowRadius = shadowRadius
        }
    }
    @IBInspectable var interfaceBuilderBackgroundColor: UIColor?

    open override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        self.backgroundColor = self.interfaceBuilderBackgroundColor ?? self.backgroundColor
    }
}
extension Amplitude {
    class var shared:Amplitude {
        return Amplitude.instance()
    }
}

extension UIView {
    func updateShadow(r red: CGFloat, g green: CGFloat, b blue: CGFloat, a alpha: Int, x: CGFloat, y: CGFloat, blur: CGFloat, spread: CGFloat) {
        guard red <= 255.0, green <= 255.0, blue <= 255.0 else {
            print("Color values should be between 0 and 255")
            return
        }
        guard alpha <= 100 else {
            print("Alpha should be be between 0 and 100")
            return
        }
        guard blur >= 0, spread >= 0 else {
            print("Blur and spread can not be negative")
            return
        }
        let shadowPath = UIBezierPath(rect: CGRect(x: 0, y: 0, width: self.frame.width + spread, height: self.frame.height + spread))
        self.layer.shadowColor = UIColor(red: red / 255.0, green: green  / 255.0, blue: blue  / 255.0, alpha: 1.0).cgColor
        self.layer.shadowOffset = CGSize(width: x, height: y)
        self.layer.shadowOpacity = Float(alpha) / 100.0
        self.layer.shadowRadius = blur
        self.layer.masksToBounds =  false
        self.layer.shadowPath = shadowPath.cgPath
    }
}

extension Bundle {
    func loadView<T>(fromNib name: String, withType type: T.Type) -> T {
        if let objects = self.loadNibNamed(name, owner: nil, options: nil) {
            for object in objects {
                if let targetObject = object as? T {
                    return targetObject
                }
            }
        }
        // A view will always be found unless an invalid search was performed which should be fixed before releasing.
        fatalError("Could not load view with type " + String(describing: type))
    }
}

extension UIImage {
    public convenience init?(color: UIColor, size: CGSize = CGSize(width: 1, height: 1)) {
        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
        color.setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let cgImage = image?.cgImage else { return nil }
        self.init(cgImage: cgImage)
    }
}

public extension String {
    func trunc(length: Int, trailing: String? = "...") -> String {
        if self.count > length {
            return self.substring(to: self.index(self.startIndex, offsetBy: length)) + (trailing ?? "")
        } else {
            return self
        }
    }
    func replacingFirstOccurrence(of target: String, withString replaceString: String) -> String {
        if let range = self.range(of: target) {
            return self.replacingCharacters(in: range, with: replaceString)
        }
        return self
    }
    
}

extension NSNotification.Name {
    @nonobjc static let emojiNotification = Notification.Name(rawValue: "MonkeyEmojiNotification")
    @nonobjc static let loginNotification = Notification.Name(rawValue: "MonkeyLoginNotification")
    @nonobjc static let instagramLoginNotification = Notification.Name(rawValue: "MonkeyInstagramLoginNotification")
}
extension CharacterSet {
    ///Characters allowed in Snapchat usernames
    static let snapchat = CharacterSet(charactersIn: ".-_0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ")
}

extension DispatchTime {
    static func after(seconds: Double) -> DispatchTime {
        return DispatchTime.now() + seconds
    }
}

extension TimeInterval {
    /**
     Checks if `since` has passed since `self`.
     
     - Parameter since: The duration of time that needs to have passed for this function to return `true`.
     - Returns: `true` if `since` has passed since now.
     */
    func hasPassed(since: TimeInterval) -> Bool {
        return Date().timeIntervalSinceReferenceDate - self > since
    }
}

/**
 Wraps a function in a new function that will throttle the execution to once in every `delay` seconds.
 
 - Parameter delay: A `TimeInterval` specifying the number of seconds that needst to pass between each execution of `action`.
 - Parameter queue: The queue to perform the action on. Defaults to the main queue.
 - Parameter action: A function to throttle.
 
 - Returns: A new function that will only call `action` once every `delay` seconds, regardless of how often it is called.
 */
func throttle(delay: TimeInterval, queue: DispatchQueue = .main, action: @escaping (() -> Void)) -> () -> Void {
    var currentWorkItem: DispatchWorkItem?
    var lastFire: TimeInterval = 0
    return {
        guard currentWorkItem == nil else { return }
        currentWorkItem = DispatchWorkItem {
            action()
            lastFire = Date().timeIntervalSinceReferenceDate
            currentWorkItem = nil
        }
        delay.hasPassed(since: lastFire) ? queue.async(execute: currentWorkItem!) : queue.asyncAfter(deadline: .now() + delay, execute: currentWorkItem!)
    }
}

extension Optional {
    
    /**
     Runs a block of code if an optional is not nil.
     - Parameter block: Block to run if Optional != nil
     - Parameter wrapped: The wrapped optional.
     */
    func then(_ block: (_ wrapped: Wrapped) throws -> Void) rethrows {
        if let wrapped = self { try block(wrapped) }
    }
}

protocol Countable {
    var count: Int { get }
}

extension Array: Countable {}
extension Data: Countable {}
extension Results: Countable {}

extension Optional where Wrapped: Countable {
    /// The Array's count (or 0 if the array is nil).
    var count: Int {
        return self?.count ?? 0
    }
}

extension CNMutablePostalAddress {
    convenience init(placemark: CLPlacemark) {
        self.init()
        placemark.subThoroughfare    .then { street += $0 + " " }
        placemark.thoroughfare       .then { street += $0 }
        placemark.locality           .then { city = $0 }
        placemark.administrativeArea .then { state = $0 }
        placemark.postalCode         .then { postalCode = $0 }
        placemark.country            .then { country = $0 }
        placemark.isoCountryCode     .then { isoCountryCode = $0 }
    }
}

extension Object {
    /**
     This overrides the default implementation which throws an NSException when a key does not exist. Instead, a message will be printed to the console.
     
     - parameter value: The value to set.
     - parameter key: A key that does not exist on the object.
     */
    override open func setValue(_ value: Any?, forUndefinedKey key: String) {
        if (self.objectSchema.properties.contains { $0.name == key }) {
            return super.setValue(value, forUndefinedKey: key)
        }
        print("Error: Unable to set property \(key) to \(String(describing: value)) because the specified key does not exist on the class \(self.objectSchema.className).")
    }
}

extension Dictionary {
    init(_ pairs: [Element]) {
        self.init()
        for (k, v) in pairs {
            self[k] = v
        }
    }
    func mapPairs<OutKey: Hashable, OutValue>( transform: (Element) throws -> (OutKey, OutValue)) rethrows -> [OutKey: OutValue] {
        return Dictionary<OutKey, OutValue>(try map(transform))
    }
    
    func filterPairs( includeElement: (Element) throws -> Bool) rethrows -> [Key: Value] {
        return Dictionary(try filter(includeElement))
    }
}
extension Formatter {
    static let iso8601: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
        return formatter
    }()
}
extension Date {
    var iso8601: String {
        return Formatter.iso8601.string(from: self)
    }
}
extension NSDate {
    var iso8601: String {
        return Formatter.iso8601.string(from: self as Date)
    }
}
extension String {
    var dateFromISO8601: Date? {
        return Formatter.iso8601.date(from: self)   // "Mar 22, 2017, 10:22 AM"
    }
}

extension String {
    
    var sha256: String {
        if let stringData = self.data(using: String.Encoding.utf8) {
            return hexStringFromData(input: digest(input: stringData as NSData))
        }
        return ""
    }
    
    private func digest(input : NSData) -> NSData {
        let digestLength = Int(CC_SHA256_DIGEST_LENGTH)
        var hash = [UInt8](repeating: 0, count: digestLength)
        CC_SHA256(input.bytes, UInt32(input.length), &hash)
        return NSData(bytes: hash, length: digestLength)
    }
    
    private  func hexStringFromData(input: NSData) -> String {
        var bytes = [UInt8](repeating: 0, count: input.length)
        input.getBytes(&bytes, length: input.length)
        
        var hexString = ""
        for byte in bytes {
            hexString += String(format:"%02x", UInt8(byte))
        }
        
        return hexString
    }
}

extension UIColor {
    var readableInverse: UIColor {
        let count = self.cgColor.numberOfComponents
        let componentColors = self.cgColor.components!
        var darknessScore: CGFloat = 0
        if count == 2 {
            darknessScore = ((componentColors[0] * 255) * 299) + ((componentColors[0] * 255) * 587) + ((componentColors[0] * 255) * 114) / 1000
        } else if count == 4 {
            darknessScore = ((componentColors[0] * 255) * 299) + ((componentColors[1] * 255) * 587) + ((componentColors[2] * 255) * 114) / 1000
        }
        
        if darknessScore >= 125 {
            return .black
        }
        return .white
    }
}

extension Array {
    mutating func removeObject<U: Equatable>(object: U) -> Bool {
        for (idx, objectToCompare) in self.enumerated() {  //in old swift use enumerate(self)
            if let to = objectToCompare as? U {
                if object == to {
                    self.remove(at: idx)
                    return true
                }
            }
        }
        return false
    }
}

extension String {
    var capitalizedFirstLetter: String {
        if (self.isEmpty) {
            return self
        }
        
        let first = String(prefix(1)).capitalized
        let other = String(dropFirst())
        return first + other
    }
}

// MARK: - String Sizing
extension String {
    func boundingRect(forFont font: UIFont, constrainedTo size: CGSize) -> CGRect {
        return self.boundingRect(with: size, options: .usesLineFragmentOrigin, attributes: [NSFontAttributeName: font], context: nil)
    }
}

// MARK: - Scroll to bottom
extension UITableView {
    func scrollToBottom(animated: Bool = true) {
        let sections = self.numberOfSections
        let rows = self.numberOfRows(inSection: sections - 1)
        if (rows > 0){
            self.scrollToRow(at: IndexPath(row: rows - 1, section: sections - 1), at: .bottom, animated: animated)
        }
    }
}

/**
 Used to describe position to the left or right of an object, place, or central point.
 
 - left: The left-hand side.
 - right: The right-hand side.
*/
enum Side {
    /// The left-hand side.
    case left
    /// The right-hand side.
    case right
}

extension NSError {
    static let unknownMonkeyError = NSError(domain: "cool.monkey.ios", code: 0, userInfo: nil)
}

/// Relative direction that the user is swiping a view in from.
enum RelativeDirection {
    /// Moving in from the left.
    case left
    /// Moving in from the right.
    case right
    /// Moving in from the bottom.
    case bottom
    /// Moving in from the top.
    case top
}

extension String {
    var containsEmoji: Bool {
        for scalar in unicodeScalars {
            switch scalar.value {
            case 0x1F600...0x1f997, // Emoticons
            0x1F300...0x1F5FF, // Misc Symbols and Pictographs
            0x1F680...0x1F6FF, // Transport and Map
            0x2600...0x26FF,   // Misc symbols
            0x2700...0x27BF,   // Dingbats
            0xFE00...0xFE0F:   // Variation Selectors
                return true
            default:
                continue
            }
        }
        return false
    }
}
