//
//  Async.swift
//  Monkey
//
//  Created by Harrison Weinerman on 3/31/17.
//  Copyright © 2017 Monkey Squad. All rights reserved.
//

import Foundation

class Async {
    /// Run all functions in an array, in order, and call backs
    class func all<ResultT, ErrorT>(_ functions: [(_ callback: @escaping (_ error: ErrorT?, _ result: ResultT?) -> Void) -> Void], completed: @escaping (_ error: ErrorT?, _ results: [ResultT?]?) -> Void) {
        guard functions.count != 0 else {
            completed(nil, nil)
            return
        }
        var nextFunctionIndex = 0
        var results = [ResultT?]()
        var handleCallback: ((_ error: ErrorT?, _ result: ResultT?) -> Void)!
        handleCallback = { (_ error: ErrorT?, _ result: ResultT?) in
            guard error == nil else {
                completed(error, nil)
                return
            }
            results.append(result)
            let isLastFunction = nextFunctionIndex == functions.count - 1
            guard !isLastFunction else {
                completed(nil, results)
                return
            }
            nextFunctionIndex += 1
            functions[nextFunctionIndex](handleCallback)
            
        }
        functions[nextFunctionIndex](handleCallback)
    }
}
