//
//  RealmAPI.swift
//  PersistenceFramework
//
//  Created by Cristian on 06/03/2018.
//  Copyright © 2018 Cristian Barril. All rights reserved.
//

import Foundation
import RealmSwift

/**
 Constructor for Realm database.
 
 - Important:
 This method **must** be called once, before attempting to use the database.
 
 - parameters:
     - databaseName: Name to identify the database in the bundle.
     - bundle: The bundle of the database. Optional, default is _Bundle.main_.
     - passphrase: Passphrase to encrypt the database. Cannot be an empty String.
     - schemaVersion: Current schema version. Optional, default is _0_.
     - migrationBlock: Closure with the logic to migrate the model. Optional, default is _nil_.
 
 - throws:
 NSError with the description of the problem.
 */
public func RealmManagerInit(databaseName: String, bundle: Bundle, passphrase: String, schemaVersion: UInt64 = 0, migrationBlock: MigrationBlock? = nil) throws {
    let databaseKey = DatabaseHelper.getDatabaseKey(databaseName: databaseName, bundle: bundle)
    do {
        try RealmManager.initialize(databaseKey: databaseKey, passphrase: passphrase, schemaVersion: schemaVersion, migrationBlock: migrationBlock)
    } catch {
        throw error
    }
}

/**
 Recover the specific context for the requested database.
 
 - parameters:
     - databaseName: Name to identify the database in the bundle.
     - bundle: The bundle of the database. Optional, default is _Bundle.main_.
 
 - returns:
 Realm object to use the database. Can be nil.
 */
public func RealmManager_getRealm(databaseName: String, forBundle bundle: Bundle) -> Realm? {
    let databaseKey = DatabaseHelper.getDatabaseKey(databaseName: databaseName, bundle: bundle)
    return RealmManager.getRealm(databaseKey: databaseKey)
}

/**
 Remove the context instance generated in the constructor method for the requested database.
 
 - Important:
 Use this method to avoid future uses of the database in the current life cycle of the app.
 
 - parameters:
     - databaseName: Name to identify the database in the bundle.
     - bundle: The bundle of the database. Optional, default is _Bundle.main_.
 */
public func RealmManager_cleanUp(databaseName: String, forBundle bundle: Bundle) {
    let databaseKey = DatabaseHelper.getDatabaseKey(databaseName: databaseName, bundle: bundle)
    RealmManager.cleanUp(databaseKey: databaseKey)
}

/**
 Remove all context instances generated in the constructor method.
 
 - Important:
 Use this method to avoid future uses of any Core Data database in the current life cycle of the app.
 */
public func RealmManager_cleanUpAll() {
    RealmManager.cleanUpAll()
}

/**
 Delete all databases files from sandbox.
 
 - Important:
 All databases will be **deleted**. This action cannot be undone.
 
 - throws:
 NSError with the description of the problem.
 */
public func RealmManager_deleteAllRealm() throws {
    do {
        try RealmManager.deleteAllRealm()
    } catch {
        throw error
    }    
}
