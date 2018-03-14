//
//  Bundle.swift
//  PersistenceFramework
//
//  Created by Cristian on 06/03/2018.
//  Copyright © 2018 Cristian Barril. All rights reserved.
//

import Foundation

internal extension Bundle {
    func getName() -> String {
        guard let bundleName = self.infoDictionary![kCFBundleNameKey as String] as? String else {
            return ""
        }
        return bundleName
    }
}
