//
//  ErrorFactory.swift
//  PersistenceFramework
//
//  Created by Cristian Barril on 21/3/18.
//  Copyright © 2018 Cristian Barril. All rights reserved.
//

import Foundation

struct ErrorFactory {
    internal static func createError(withKey key: String, failureReason: String, domain: String,  code: Int = 999) -> NSError {
        var dict = [String: AnyObject]()
        dict[NSLocalizedDescriptionKey] = key as AnyObject
        dict[NSLocalizedFailureReasonErrorKey] = failureReason as AnyObject
        return NSError(domain: domain, code: code, userInfo: dict)
    }
}
