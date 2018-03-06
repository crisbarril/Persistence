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
    let databaseKey = getDatabaseKey(databaseName: databaseName, bundle: bundle)
    do {
        try RealmManager.initialize(databaseKey: databaseKey, passphrase: passphrase, schemaVersion: schemaVersion, migrationBlock: migrationBlock)
    } catch {
        throw error
    }
}

public func RealmManager_getRealm(databaseName: String, forBundle bundle: Bundle) -> Realm? {
    let databaseKey = getDatabaseKey(databaseName: databaseName, bundle: bundle)
    return RealmManager.getRealm(databaseKey: databaseKey)
}

public func RealmManager_currentStack(databaseName: String, forBundle bundle: Bundle) -> String {
    let databaseKey = getDatabaseKey(databaseName: databaseName, bundle: bundle)
    return RealmManager.currentStack(databaseKey: databaseKey)
}

public func RealmManager_cleanUp(databaseName: String?, forBundle bundle: Bundle?) {
    if let name = databaseName, let paramBundle = bundle {
        let databaseKey = getDatabaseKey(databaseName: name, bundle: paramBundle)
        RealmManager.cleanUp(databaseKey: databaseKey)
    }
    else {
        RealmManager.cleanUpAll()
    }
}

public func RealmManager_deleteAllRealm() {
    RealmManager.deleteAllRealm()
}

// MARK: - Internal method
internal func getDatabaseKey(databaseName: String, bundle: Bundle) -> String {
    return "\(bundle.getName())Bundle.\(databaseName)"
}
