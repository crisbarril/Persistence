//
//  RealmAPI.swift
//  PersistenceFramework
//
//  Created by Cristian on 06/03/2018.
//  Copyright © 2018 Cristian Barril. All rights reserved.
//

import Foundation
import RealmSwift

public func RealmManagerInit(databaseName: String, bundle: Bundle, passphrase: String, schemaVersion: UInt64 = 0, migrationBlock: MigrationBlock? = nil) throws {
    let databaseKey = DatabaseHelper.getDatabaseKey(databaseName: databaseName, bundle: bundle)
    do {
        try RealmManager.initialize(databaseKey: databaseKey, passphrase: passphrase, schemaVersion: schemaVersion, migrationBlock: migrationBlock)
    } catch {
        throw error
    }
}

public func RealmManager_getRealm(databaseName: String, forBundle bundle: Bundle) -> Realm? {
    let databaseKey = DatabaseHelper.getDatabaseKey(databaseName: databaseName, bundle: bundle)
    return RealmManager.getRealm(databaseKey: databaseKey)
}

public func RealmManager_cleanUp(databaseName: String, forBundle bundle: Bundle) {
    let databaseKey = DatabaseHelper.getDatabaseKey(databaseName: databaseName, bundle: bundle)
    RealmManager.cleanUp(databaseKey: databaseKey)
}

public func RealmManager_cleanUpAll() {
    RealmManager.cleanUpAll()
}

public func RealmManager_deleteAllRealm() throws {
    do {
        try RealmManager.deleteAllRealm()
    } catch {
        throw error
    }    
}
