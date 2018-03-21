//
//  CoreDataAPI.swift
//  PersistenceFramework
//
//  Created by Cristian on 13/03/2018.
//  Copyright © 2018 Cristian Barril. All rights reserved.
//

import Foundation
import CoreData

/**
 Constructor for Core Data database.
 
 - Important:
 This method **must** be called once, before attempting to use the database.
 
 - parameters:
    - databaseName: Name to identify the database in the bundle.
    - bundle: The bundle of the database. Optional, default is _Bundle.main_.
    - modelURL: Path URL to the data model.
 */
@available(iOS, message: "This function is only available for iOS.")
public func CoreDataManagerInit(databaseName: String, bundle: Bundle = Bundle.main, modelURL: URL) throws {
    let databaseKey = DatabaseHelper.getDatabaseKey(databaseName: databaseName, bundle: bundle)
    do {
        try CoreDataManager.initialize(databaseKey, bundle: bundle, modelURL: modelURL)
    } catch {
        throw error
    }
}

/**
 Recover the specific context for the requested database.
 
 - parameters:
     - databaseName: Name to identify the database in the bundle.
     - bundle: The bundle of the database. Optional, default is _Bundle.main_.
 */
@available(iOS, message: "This function is only available for iOS.")
public func CoreDataManager_getContext(databaseName: String, forBundle bundle: Bundle = Bundle.main) -> NSManagedObjectContext? {
    let databaseKey = DatabaseHelper.getDatabaseKey(databaseName: databaseName, bundle: bundle)
    return CoreDataManager.getContext(databaseKey)
}

/**
 Save the context for the requested database.
 
 - parameters:
     - databaseName: Name to identify the database in the bundle.
     - bundle: The bundle of the database. Optional, default is _Bundle.main_.
 */
@available(iOS, message: "This function is only available for iOS.")
public func CoreDataManager_saveContext(databaseName: String, forBundle bundle: Bundle = Bundle.main) throws {
    let databaseKey = DatabaseHelper.getDatabaseKey(databaseName: databaseName, bundle: bundle)
    try CoreDataManager.saveContext(databaseKey)
}

/**
 Remove the context instance generated in the constructor method for the requested database.
 
 - Important:
 Use this method to avoid future uses of the database in the current life cycle of the app.
 
 - parameters:
     - databaseName: Name to identify the database in the bundle.
     - bundle: The bundle of the database. Optional, default is _Bundle.main_.
 */

@available(iOS, message: "This function is only available for iOS.")
public func CoreDataManager_cleanUp(databaseName: String, forBundle bundle: Bundle = Bundle.main) {
    let databaseKey = DatabaseHelper.getDatabaseKey(databaseName: databaseName, bundle: bundle)
    CoreDataManager.cleanUp(databaseKey)
}

/**
 Remove all context instances generated in the constructor method.
 
 - Important:
 Use this method to avoid future uses of any Core Data database in the current life cycle of the app.
 */
@available(iOS, message: "This function is only available for iOS.")
public func CoreDataManager_cleanUpAll() {
    CoreDataManager.cleanUpAll()
}

/**
 Delete all databases files from sandbox.
 
 - Important:
 All databases will be **deleted**. This action cannot be undone.
 */
@available(iOS, message: "This function is only available for iOS.")
public func CoreDataManager_deleteAllCoreData() throws {
    do {
        try CoreDataManager.deleteAllCoreData()
    } catch {
        throw error
    }
}
