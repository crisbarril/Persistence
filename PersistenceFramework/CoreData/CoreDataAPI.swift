//
//  CoreDataAPI.swift
//  PersistenceFramework
//
//  Created by Cristian on 13/03/2018.
//  Copyright © 2018 Cristian Barril. All rights reserved.
//

import Foundation
import CoreData

@available(iOS, message: "This function is only available for iOS.")
public func CoreDataManagerInit(databaseName: String, bundle: Bundle, modelURL: URL) throws {
    let databaseKey = DatabaseHelper.getDatabaseKey(databaseName: databaseName, bundle: bundle)
    do {
        try CoreDataManager.initialize(databaseKey, modelURL: modelURL)
    } catch {
        throw error
    }
}

@available(iOS, message: "This function is only available for iOS.")
public func CoreDataManager_getContext(databaseName: String, forBundle bundle: Bundle) -> NSManagedObjectContext? {
    let databaseKey = DatabaseHelper.getDatabaseKey(databaseName: databaseName, bundle: bundle)
    return CoreDataManager.getContext(databaseKey)
}

@available(iOS, message: "This function is only available for iOS.")
public func CoreDataManager_saveContext(databaseName: String, forBundle bundle: Bundle) throws {
    let databaseKey = DatabaseHelper.getDatabaseKey(databaseName: databaseName, bundle: bundle)
    try CoreDataManager.saveContext(databaseKey)
}

@available(iOS, message: "This function is only available for iOS.")
public func CoreDataManager_cleanUp(databaseName: String, forBundle bundle: Bundle) {
    let databaseKey = DatabaseHelper.getDatabaseKey(databaseName: databaseName, bundle: bundle)
    CoreDataManager.cleanUp(databaseKey)
}

@available(iOS, message: "This function is only available for iOS.")
public func CoreDataManager_cleanUpAll() {
    CoreDataManager.cleanUpAll()
}

@available(iOS, message: "This function is only available for iOS.")
public func CoreDataManager_deleteAllCoreData() throws {
    do {
        try CoreDataManager.deleteAllCoreData()
    } catch {
        throw error
    }
}
