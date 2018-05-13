//
//  DatabaseHelper.swift
//  PersistenceFramework
//
//  Created by Cristian on 13/03/2018.
//  Copyright © 2018 Cristian Barril. All rights reserved.
//

import Foundation

struct DatabaseHelper {    
    internal static func getStoreUrl(_ databaseKey: String) -> URL {
        return URL.applicationDocumentsDirectory().appendingPathComponent(databaseKey)
    }
}
