//
//  TruthOrDare.swift
//  Monkey
//
//  Created by Isaiah Turner on 1/19/17.
//  Copyright © 2017 Isaiah Turner. All rights reserved.
//

import Foundation
import Alamofire
import Amplitude_iOS
import AudioToolbox

class TruthOrDareView: UIView, MessageHandler {
    weak var chatSession: ChatSession?

    weak var delegate:TruthOrDareDelegate?
    var soundPlayer = SoundPlayer.shared
    let chatSessionMessagingPrefix: String = "truthordare"
    class func instanceFromNib() -> TruthOrDareView {
        return Bundle.main.loadView(fromNib: "TruthOrDare", withType: TruthOrDareView.self)
    }
    override func awakeFromNib() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeFrame(notification:)), name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)

        self.isUserInteractionEnabled = false
        self.layer.opacity = 0.0
    }
    func startGame(chatSession: ChatSession) {
        guard status == "" else {
            return
        }
        AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
        Amplitude.shared.logEvent("Started truth or dare game")
        SoundPlayer.shared.play(sound: .todGame)
        status = "started"
        chatSession.send(message: "", from: self, withType: "start")
    }
    private var currentAlertYConstraint:NSLayoutConstraint?
    private var currentAlertBottomConstraint:NSLayoutConstraint?
    private func showAlert(view: UIView) {
        self.isUserInteractionEnabled = true
        self.subviews.forEach({ $0.removeFromSuperview() })
        self.addSubview(view)
        let xConstraint = NSLayoutConstraint(item: view, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1, constant: 0)
        
        self.currentAlertYConstraint = NSLayoutConstraint(item: view, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: 0)
        self.currentAlertYConstraint!.priority = 1000
        
        NSLayoutConstraint.activate([xConstraint, self.currentAlertYConstraint!])
        view.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        self.layoutIfNeeded()

        UIView.animate(withDuration: 0.2, animations: {
            view.transform = .identity
            self.layer.opacity = 1.0
            self.layoutIfNeeded()
        }, completion: { (Bool) in
        })
    }
    private func hideAlert(view: UIView) {
        UIView.animate(withDuration: 0.2, animations: {
            view.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
            self.layer.opacity = 0.0
        }, completion: { (Bool) in
            self.isUserInteractionEnabled = false
            view.transform = .identity
            view.removeFromSuperview()
        })
    }
    func chatSession(_ chatSession: ChatSession, statusChangedTo status: ChatSessionStatus) {
        if status == .consumed || status == .consumedWithError {
            self.status = ""
            for subview in self.subviews {
                self.hideAlert(view: subview)
            }
        }
    }
    func chatSesssion(_ chatSesssion: ChatSession, connectionCreated connection: OTConnection) {
        
    }
    var status = ""
    var expect = TruthOrDarePromptView.TruthOrDareResponse.dare
    func chatSession(_ chatSession: ChatSession, received message: String, from connection: OTConnection, withType type: String) {
        switch type {
        case "start":
            guard status == "" else {
                return
            }
            AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
            SoundPlayer.shared.play(sound: .todGame)
            let truthOrDarePromptView = TruthOrDarePromptView.instanceFromNib()
            truthOrDarePromptView.responseHandler = { (response) in
                self.status = "started"
                self.expect = response
                switch response {
                case .truth:
                    chatSession.send(message: "truth", from: self, withType: "request")
                case .dare:
                    chatSession.send(message: "dare", from: self, withType: "request")
                }
                self.hideAlert(view: truthOrDarePromptView)
            }
            showAlert(view: truthOrDarePromptView)
        case "request":
            guard status == "started" else {
                return
            }
            Amplitude.shared.logEvent("Received truth or dare game request")
            let truthOrDareInputView = TruthOrDareInputView.instanceFromNib()
            var isTruth = false
            if message == "dare" {
                truthOrDareInputView.titleLabel.text = "Dare ‼️"
                truthOrDareInputView.textView.updateText("I dare you to...")
                truthOrDareInputView.submitButton.setTitle("Dare", for: .normal)
            } else {
                isTruth = true
                truthOrDareInputView.titleLabel.text = "Truth 🎉"
                truthOrDareInputView.textView.updateText("Ask anything...")
                truthOrDareInputView.submitButton.setTitle("Ask", for: .normal)
            }
            truthOrDareInputView.responseHandler = { (response) in
                self.hideAlert(view: truthOrDareInputView)
                self.createDare(text: response, isTruth: isTruth, chatSession: chatSession)
            }
            showAlert(view: truthOrDareInputView)
            truthOrDareInputView.textField.becomeFirstResponder()
        case "response":
            guard status == "started" else {
                return
            }
            self.getDare(dareId: message, chatSession: chatSession)
        default:
            return
        }
    }
    func getDare(dareId: String, chatSession: ChatSession) {
        guard let authorization = APIController.authorization else {
            print("Not authorized")
            self.status = ""
            return
        }
        let dareId = dareId.trimmingCharacters(in: NSCharacterSet.alphanumerics.inverted)

        let url = "\(Environment.baseURL)/api/v1.1/dares/\(dareId)"

        let headers: HTTPHeaders = [
            "Authorization": authorization,
            "Accept": "application/json"
        ]
        Alamofire.request(url, method: .get, headers: headers).responseJSON { response in
            print("Request completed")
            var error:String?
            if let err = response.result.error {
                error = err.localizedDescription
            }
            if (response.response?.statusCode ?? 500) >= 400  {
                error = ((response.result.value as? Dictionary<String, Array<Dictionary<String, Any>>>)?["errors"]?[0]["title"] as? String) ?? "Something went wrong getting their dare."
            }
            if let errorMessage = error {
                print("Error dare \(errorMessage)")
                let alert = UIAlertController(title: "Uh, oh!", message: errorMessage, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Retry", style: .default, handler: { (action) in
                    self.getDare(dareId: dareId, chatSession: chatSession)
                }))
                self.delegate?.requestPresentation(of: alert, from: self)
                return
            }
            self.status = ""
            guard let data = (response.result.value as? Dictionary<String, Any>)?["data"] as? Dictionary<String, Any> else {
                print("Data parsing issues")
                return
            }
            guard let attributes = data["attributes"] as? Dictionary<String, Any> else {
                print("Attributes parsing issues")
                return
            }
            guard ((attributes["is_truth"] as? Bool) ?? (self.expect == .truth)) == (self.expect == .truth) else {
                print("Wrong type")
                return
            }
            guard ((attributes["is_banned"] as? Bool) ?? false) == false else {
                print("It's banned")
                return
            }
            let truthOrDareAlertView = TruthOrDareAlertView.instanceFromNib()
            truthOrDareAlertView.updateText(attributes["text"] as? String ?? "")
            switch self.expect {
            case .truth:
                truthOrDareAlertView.textLabel.text = "Tell the truth..."
            case .dare:
                truthOrDareAlertView.textLabel.text = "I dare you to..."
            }
            Amplitude.shared.logEvent("Got dare", withEventProperties: [
                "id": dareId,
                "attributes": attributes,
                ])
            truthOrDareAlertView.responseHandler = { () in
                self.status = ""
                self.hideAlert(view: truthOrDareAlertView)
            }
            self.showAlert(view: truthOrDareAlertView)
        }
    }
    func createDare(text: String, isTruth: Bool, chatSession: ChatSession) {
        guard let authorization = APIController.authorization else {
            self.status = ""
            print("Not authorized")
            return
        }

        let url = "\(Environment.baseURL)/api/v1.1/dares"

        let headers: HTTPHeaders = [
            "Authorization": authorization,
            "Accept": "application/json"
        ]
        let parameters: Parameters = [
            "data": [
                "type": "dares",
                "attributes": [
                    "text": text,
                    "is_truth": isTruth,
                ],
                "relationships": [
                    "chat": [
                        "data": [
                            "type": "chats",
                            "id": chatSession.chat?.chatId ?? ""
                        ]
                    ]
                ]
            ]
        ]
        
        Alamofire.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
            print("Request completed")
            var error:String?
            if let err = response.result.error {
                error = err.localizedDescription
            }
            if (response.response?.statusCode ?? 500) >= 400  {
                error = ((response.result.value as? Dictionary<String, Array<Dictionary<String, Any>>>)?["errors"]?[0]["title"] as? String) ?? "Something went wrong getting their dare."
            }
            if let errorMessage = error {
                print("Error dare \(errorMessage)")
                let alert = UIAlertController(title: "Uh, oh!", message: errorMessage, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Retry", style: .default, handler: { (action) in
                    self.createDare(text: text, isTruth: isTruth, chatSession: chatSession)
                }))
                self.delegate?.requestPresentation(of: alert, from: self)
                return
            }
            self.status = ""
            guard let data = (response.result.value as? Dictionary<String, Any>)?["data"] as? Dictionary<String, Any> else {
                print("Data parsing issues")
                return
            }
            guard let attributes = data["attributes"] as? Dictionary<String, Any> else {
                print("Attributes parsing issues")
                return
            }
            guard ((attributes["is_truth"] as? Bool) ?? (self.expect == .truth)) == (self.expect == .truth) else {
                print("Wrong type")
                return
            }
            guard let dareId = data["id"] as? String else {
                print("Id parsing issues")
                return
            }
            Amplitude.shared.logEvent("Sent dare", withEventProperties: [
                "id": dareId,
                "attributes": attributes,
                ])
            chatSession.send(message: dareId, from: self, withType: "response")
            guard ((attributes["is_banned"] as? Bool) ?? false) == false else {
                print("is banned")
                let alert = UIAlertController(title: "Don’t say that! 🙊", message: "That’s inappropriate and not okay to say on Monkey.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
                }))
                self.delegate?.requestPresentation(of: alert, from: self)
                return
            }
        }
    }
    func keyboardWillChangeFrame(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            let endFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
            let duration:TimeInterval = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
            let animationCurveRawNSN = userInfo[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber
            let animationCurveRaw = animationCurveRawNSN?.uintValue ?? UIViewAnimationOptions.curveEaseInOut.rawValue
            let animationCurve:UIViewAnimationOptions = UIViewAnimationOptions(rawValue: animationCurveRaw)
            if (endFrame?.origin.y)! >= UIScreen.main.bounds.size.height {
                self.currentAlertYConstraint?.constant = 0
                //self.currentAlertYConstraint?.isActive = true
                //self.currentAlertBottomConstraint?.constant = 0
            } else {
                self.currentAlertYConstraint?.constant = -((endFrame?.size.height ?? 0.0) / 2) + 10
                // self.currentAlertYConstraint?.isActive = false
                // self.currentAlertBottomConstraint?.constant = endFrame?.size.height ?? 0.0
            }
            UIView.animate(withDuration: duration,
                           delay: TimeInterval(0),
                           options: animationCurve,
                           animations: {
                            self.layoutIfNeeded()
            }, completion: nil)
        }
    }
}

class TruthOrDareInputView: UIView, UITextFieldDelegate, TruthOrDareResizableView {
    
    @IBOutlet var widthConstraintPrivate: NSLayoutConstraint!
    @IBOutlet var heightConstraintPrivate: NSLayoutConstraint!
    internal var heightConstraint: NSLayoutConstraint {
        return heightConstraintPrivate
    }
    internal var widthConstraint: NSLayoutConstraint {
        return widthConstraintPrivate
    }
    
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var submitButton: BigYellowButton!
    @IBOutlet var textView: MakeTextViewGreatAgain!
    @IBOutlet var textFieldContainer: UIView!
    @IBOutlet var textField:UITextField!
    var responseHandler:((String) -> Void)?
    class func instanceFromNib() -> TruthOrDareInputView {
        return Bundle.main.loadView(fromNib: "TruthOrDare", withType: TruthOrDareInputView.self)
    }
    override func awakeFromNib() {
        self.textFieldContainer.layer.cornerRadius = 16
        self.textField.delegate = self
        self.submitButton.isEnabled = false
        self.submitButton.layer.opacity = 0.5
    }
    @IBAction func submit(_ sender: BigYellowButton) {
        self.responseHandler?(self.textField.text ?? "")
        SoundPlayer.shared.play(sound: .todGame)
    }
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let newText = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string)
        if newText.characters.count < 140 {
            if newText.characters.count == 0 {
                self.submitButton.isEnabled = false
                self.submitButton.layer.opacity = 0.5
            } else {
                self.submitButton.isEnabled = true
                self.submitButton.layer.opacity = 1.0
            }
            return true
        }
        return false
    }
}

class TruthOrDarePromptView: UIView, TruthOrDareResizableView {
    
    @IBOutlet var widthConstraintPrivate: NSLayoutConstraint!
    @IBOutlet var heightConstraintPrivate: NSLayoutConstraint!
    internal var heightConstraint: NSLayoutConstraint {
        return heightConstraintPrivate
    }
    internal var widthConstraint: NSLayoutConstraint {
        return widthConstraintPrivate
    }
    
    enum TruthOrDareResponse {
        case truth
        case dare
    }
    var responseHandler:((TruthOrDareResponse) -> Void)?
    class func instanceFromNib() -> TruthOrDarePromptView {
        return Bundle.main.loadView(fromNib: "TruthOrDare", withType: TruthOrDarePromptView.self)
    }
    @IBAction func respondTruth(_ sender: BigYellowButton) {
        self.responseHandler?(.truth)
        SoundPlayer.shared.play(sound: .todGame)

    }
    @IBAction func respondDare(_ sender: BigYellowButton) {
        self.responseHandler?(.dare)
        SoundPlayer.shared.play(sound: .todGame)

    }
}

class TruthOrDareAlertView: UIView, TruthOrDareResizableView {
    @IBOutlet internal var textView: MakeTextViewGreatAgain!
    @IBOutlet internal var textLabel: UILabel!

    var responseHandler:(() -> Void)?
    
    @IBOutlet var widthConstraintPrivate: NSLayoutConstraint!
    @IBOutlet var heightConstraintPrivate: NSLayoutConstraint!
    internal var heightConstraint: NSLayoutConstraint {
        return heightConstraintPrivate
    }
    internal var widthConstraint: NSLayoutConstraint {
        return widthConstraintPrivate
    }
    let baseHeight: CGFloat = 118.0

    class func instanceFromNib() -> TruthOrDareAlertView {
        return Bundle.main.loadView(fromNib: "TruthOrDare", withType: TruthOrDareAlertView.self)
    }
    func updateText(_ text: String) {
        self.textView.updateText(text)
        let sizeThatFits = self.textView.sizeThatFits(CGSize(width: self.textView.frame.size.width, height: CGFloat(MAXFLOAT)))
        
        self.heightConstraint.constant = min(baseHeight + sizeThatFits.height, 320) + 10
    }
    @IBAction func dismiss(_ sender: BigYellowButton) {
        self.responseHandler?()
        SoundPlayer.shared.play(sound: .todGame)

    }
}
protocol TruthOrDareDelegate: class {
    func requestPresentation(of alertController: UIAlertController, from view: UIView)
}
protocol TruthOrDareResizableView: class {
    var heightConstraint: NSLayoutConstraint { get }
    var widthConstraint: NSLayoutConstraint { get }
}
class TruthOrDareAlertContentsView: UIView {
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        self.layer.cornerRadius = 28
        self.clipsToBounds = true
    }
}
