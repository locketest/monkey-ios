//
//  CachedImageView.swift
//  Monkey
//
//  Created by Isaiah Turner on 5/11/17.
//  Copyright © 2017 Monkey Squad. All rights reserved.
//
import Foundation
import RealmSwift
import Alamofire

class CachedImageView: MakeUIViewGreatAgain {
    var status: Status = .image {
        didSet {
            // Hide all the views.
            self.imageView.isHidden = true
            self.loadingView.stopAnimating()
            
            // Unhide the view we need to show.
            switch status {
            case .image:
                self.imageView.isHidden = false
            case .loading:
                self.loadingView.startAnimating()
            case .none:
                self.loadingView.startAnimating()
            }
        }
    }
    private var imageCacheRequest: ImageCacheRequest?
	var placeholder: String?
    @IBInspectable var url: String? {
        didSet {

            if self.url != oldValue {
                self.imageCacheRequest?.cancel()
                self.imageCacheRequest = nil
            }
            
            DispatchQueue.main.async {
                guard let url = self.url else {
                    self.showDefaultImage()
                    return
                }
                
                self.status = .loading
                
                self.imageCacheRequest = ImageCache.shared.load(url: url) { [weak self] (result) in
                    switch result {
                    case .success(let cachedImage):
                        guard let image = cachedImage.image else {
                            return
                        }
                        self?.status = .image
                        self?.imageView.image = image
                    case .error(let error):
                        error.log()
                    }
                }
            }
        }
    }
    
    private func showDefaultImage() {
        self.status = .image
        self.imageView.image = UIImage(named: placeholder ?? "ProfileImageDefault", in: .main, compatibleWith: self.traitCollection)
    }
	
    private let imageView = UIImageView()
    private let loadingView = UIActivityIndicatorView()
    init(url: String) {
        super.init(frame: UIScreen.main.bounds)
        defer {
            self.url = url
        }
        afterInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        afterInit()
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        afterInit()
    }
    func afterInit() {
        self.loadingView.hidesWhenStopped = true
        self.addSubview(self.loadingView)
        self.addSubview(self.imageView)
        self.showDefaultImage()
        
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        self.imageView.frame = self.bounds
        self.loadingView.center = self.convert(self.center, from: self.superview)
        self.loadingView.activityIndicatorViewStyle = self.backgroundColor?.readableInverse == .white ? .white : .gray
    }
    enum Status {
        case loading
        case image
        case none
    }
}

enum ImageCacheResult {
    case error(APIError)
    case success(CachedImage)
}

class ImageCacheRequest {
    let url: String
    let imageChangeHandler: (ImageCacheResult) -> Void
    private(set) var isCancelled = false
    init(url: String, onImageChange imageChangeHandler: @escaping (ImageCacheResult) -> Void) {
        self.imageChangeHandler = imageChangeHandler
        self.url = url
    }
    func cancel() {
        self.isCancelled = true
    }
}

/**
 Loads images and deletes them automatically.
 */
class ImageCache {
    static let shared = ImageCache()
    
    let fileManager = FileManager.default
    var cachedImagesDirectory: URL?
    
    private init() {}
    
    private var realm: Realm?
    
    private func setupRealm() throws {
        guard self.realm == nil else {
            return
        }
        
        let documentsDirectory = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        self.cachedImagesDirectory = documentsDirectory.appendingPathComponent("image-cache", isDirectory: true)
        if !fileManager.fileExists(atPath: self.cachedImagesDirectory!.path) {
            try fileManager.createDirectory(at: self.cachedImagesDirectory!, withIntermediateDirectories: false, attributes: nil)
        }
        let imageCacheURL = documentsDirectory.appendingPathComponent("image-cache.realm")
        let imageCacheRealm = try Realm(configuration: .init(
            fileURL: imageCacheURL,
            inMemoryIdentifier: nil,
            syncConfiguration: nil,
            encryptionKey: nil,
            readOnly: false,
            schemaVersion: 1,
            migrationBlock: nil,
            deleteRealmIfMigrationNeeded: false,
            shouldCompactOnLaunch: nil,
            objectTypes: [CachedImage.self]))
        self.realm = imageCacheRealm
        // And clear expired images on app load.
        let now = Date()
        let cachedImages = imageCacheRealm.objects(CachedImage.self)
        cachedImages.forEach({ (cachedImage) in
            if cachedImage.expires_at < now {
                do {
                    try fileManager.removeItem(atPath: cachedImage.local_path)
                    try imageCacheRealm.write {
                        imageCacheRealm.delete(cachedImage)
                    }
                } catch(let error) {
                    print("Error: Auto Deleting Cache Failed - \(error.localizedDescription)")
                }
            }
        })
    }

    /**
     Requests an image at the given URL and returns the currently cached image (if available)
     
     - parameter url: The url of the image to load.
     - parameter callback: A callback that will be called one OR two times.
     */
    func load(url: String, callback: @escaping (ImageCacheResult) -> Void) -> ImageCacheRequest {
        let imageCacheRequest = ImageCacheRequest(url: url, onImageChange: callback)
        if self.realm == nil {
            do {
                try setupRealm()
            } catch(let error) {
                imageCacheRequest.imageChangeHandler(.error(APIError(code: "-1", status: nil, message: error.localizedDescription)))
                return imageCacheRequest
            }
        }
        let now = Date()
        guard let cachedImage = realm?.object(ofType: CachedImage.self, forPrimaryKey: getCachedImageId(forUrl: url)) else {
            self.process(imageCacheRequest: imageCacheRequest)
            return imageCacheRequest
        }
        let isExpired = cachedImage.expires_at < now
        let isUpdatable = cachedImage.updates_at < now
        let isImageAvailable = cachedImage.image != nil
        if !isExpired && isImageAvailable {
            imageCacheRequest.imageChangeHandler(.success(cachedImage))
        }
        if isUpdatable || !isImageAvailable {
            self.process(imageCacheRequest: imageCacheRequest)
        }
        return imageCacheRequest
    }
    
    var resultHandlers = [String:[ImageCacheRequest]]()
    /**
     Requests a file at the provided URL but performs no more than one request for the same resource concurrently.
     */
    private func process(imageCacheRequest: ImageCacheRequest) -> Void {
        let cachedImageId = self.getCachedImageId(forUrl: imageCacheRequest.url)
        guard var callbacks = resultHandlers[cachedImageId] else {
            self.resultHandlers[cachedImageId] = [imageCacheRequest]
            Alamofire.request(imageCacheRequest.url, method: .get)
                .validate(statusCode: 200..<300)
                .responseData { (response) in
                    switch response.result {
                    case .success(let data):
                        self.set(url: imageCacheRequest.url, imageData: data) { (result) in
                            self.sendRequestResults(cachedImageId: cachedImageId, result: result)
                        }
                    case .failure(let error):
                        self.sendRequestResults(cachedImageId: cachedImageId, result: .error(APIError(code: "-1", status: nil, message: error.localizedDescription)))
                    }
            }
            return
        }
        callbacks.append(imageCacheRequest)
    }
    func set(url: String, imageData data: Data, callback: (ImageCacheResult) -> Void) {
        
        if self.realm == nil {
            do {
                try setupRealm()
            } catch(_) {
            }
        }
        
        guard let cachedImagesDirectory = self.cachedImagesDirectory else {
            callback(.error(APIError(code: "-1", status: nil, message: "Cached images directory is nil.")))
            return
        }
        guard let realm = self.realm else {
            callback(.error(.realmNotInitialized))
            return
        }
        do {
            try realm.write {
                let now = Date()
                let localURL = cachedImagesDirectory.appendingPathComponent(getCachedImageId(forUrl: url), isDirectory: false)
                let value = [
                    "cached_image_id": getCachedImageId(forUrl: url),
                    "remote_url": url,
                    "updated_at": now,
                    "updates_at": NSCalendar.current.date(byAdding: .hour, value: 1, to: now) ?? now,
                    "expires_at": NSCalendar.current.date(byAdding: .day, value: 10, to: now) ?? now,
                    ] as [String : Any]
                
                try data.write(to: localURL, options: [
                    .atomic,
                    ])
                let cachedImage = realm.create(CachedImage.self, value: value, update: true)
                callback(.success(cachedImage))
            }
        } catch (let error) {
            callback(.error(APIError(code: "-1", status: nil, message: error.localizedDescription)))
        }
    }
    private func sendRequestResults(cachedImageId: String, result: ImageCacheResult) {
        self.resultHandlers.removeValue(forKey: cachedImageId)?.forEach { (imageCacheRequest) in
            if !imageCacheRequest.isCancelled {
                imageCacheRequest.imageChangeHandler(result)
            }
        }
    }
    fileprivate func getCachedImageId(forUrl url: String) -> String {
        return url.components(separatedBy: "?")[0].sha256
    }
}

class CachedImage: Object {
    var image: UIImage? {
        guard let data = FileManager.default.contents(atPath: self.local_path) else {
            return nil
        }
        return UIImage(data: data)
    }
    
    /// A unique id
    dynamic var cached_image_id: String = ""
    /// The url to the remote file.
    dynamic var remote_url: String = "" // Default value always replaced
    /// The path to the local file.
    var local_path: String {
        get {
            let documentsDirectory = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let cachedImagesDirectory = documentsDirectory?.appendingPathComponent("image-cache", isDirectory: true)
            guard let path = cachedImagesDirectory?.appendingPathComponent(self.cached_image_id, isDirectory:false).path else {
                return ""
            }
            return path
        }
    }
    /// The last date the image was retrieved from the remote server.
    dynamic var updated_at: Date = Date()
    /// After this date, any attempt to "load" the image will result in a cached version being returned while the new data is loaded from the remote server.
    dynamic var updates_at: Date = Date()
    /// After this date, the image will be deleted from disk and memory.
    dynamic var expires_at: Date = Date()
    
    override static func primaryKey() -> String? {
        return "cached_image_id"
    }
    
    override open class func ignoredProperties() -> [String] {
        return ["image", "local_path"]
    }
}
