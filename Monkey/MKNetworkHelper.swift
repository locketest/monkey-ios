//
//  MKNetWorkManager.swift
//  Monkey
//
//  Created by YY on 2017/12/14.
//  Copyright © 2017年 Monkey Squad. All rights reserved.
//

import Foundation
import Alamofire

// MARK: -

/// A dictionary of parameters to apply to a `URLRequest`.
public typealias Parameters = [String: Any]

class MKNetworkHelper {
    @discardableResult
    public func mk_request(
        _ url: URLConvertible,
        method: HTTPMethod = .get,
        parameters: Parameters? = nil,
        encoding: ParameterEncoding = URLEncoding.default,
        headers: HTTPHeaders? = nil)
        -> DataRequest
    {
        return SessionManager.default.request(
            url,
            method: method,
            parameters: parameters,
            encoding: encoding,
            headers: headers
        )
    }
    
    @discardableResult
    public func mk_upload(
        _ data: Data,
        to url: URLConvertible,
        method: HTTPMethod = .post,
        headers: HTTPHeaders? = nil)
        -> UploadRequest
    {
        return SessionManager.default.upload(data, to: url, method: method, headers: headers)
    }
}
