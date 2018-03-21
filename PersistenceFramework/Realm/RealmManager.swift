//
//  RealmManager.swift
//  PersistenceFramework
//
//  Created by Cristian on 06/03/2018.
//  Copyright © 2018 Cristian Barril. All rights reserved.
//

import Foundation
import RealmSwift

///Class for Realm settings
struct RealmManager {

    // MARK: - Privates properties
    private static var realmContexts = [String: Realm]()
    private static let schemaVersionKey = "schemaVersionKey"

    // MARK: - Internal methods
    internal static func initialize(databaseKey: String, passphrase: String, schemaVersion: UInt64, migrationBlock: MigrationBlock?) throws {
        
        guard !databaseKey.isEmpty else {
            fatalError("RealmManager: Must specify a name for the initialization of the database")
        }
        
        guard !passphrase.isEmpty, let keyData = validPassphrase(passphrase) else {
            fatalError("RealmManager: Must specify a valid passphrase for the initialization of the database")
        }
        
        if realmContexts[databaseKey] != nil {
            throw ErrorFactory.createError(withKey: "Already initialized", failureReason: "Already initialized Realm database with key: \(databaseKey).", domain: "RealmManager")
        }

        var persistedSchemaVersion = getSchemaVersion(databaseKey: databaseKey)
        if schemaVersion > persistedSchemaVersion {
            persistedSchemaVersion = schemaVersion
        }
        
        let url = URL.applicationDocumentsDirectory().appendingPathComponent(databaseKey + ".realm")
        let config = Realm.Configuration(
            fileURL: url,
            encryptionKey: keyData,
            schemaVersion: persistedSchemaVersion,
            migrationBlock: migrationBlock
        )

        do {
            let realm = try Realm(configuration: config)
            setContext(realm, databaseKey: databaseKey)
            setSchemaVersion(persistedSchemaVersion, databaseKey: databaseKey)
            print("All Realm settings for database \(databaseKey) done!\n \(currentStack(databaseKey))")
        } catch {
            let nserror = error as NSError
            print("RealmManager - \(#function): Unresolved error for \(databaseKey): \(nserror), \(nserror.userInfo)")
        
            throw nserror
        }
    }

    internal static func getRealm(databaseKey: String) -> Realm? {
        return realmContexts[databaseKey]
    }
    
    internal static func cleanUp(databaseKey: String) {
        setContext(nil, databaseKey: databaseKey)
        print("RealmManager - \(#function): Clean DONE for \(databaseKey)")
    }
    
    internal static func cleanUpAll() {
        realmContexts = [String: Realm]()
        print("RealmManager - \(#function): Clean DONE for all contexts")
    }
    
    internal static func deleteAllRealm() throws {
        do {
            for (key, _) in realmContexts {
                let realmFile = URL.applicationDocumentsDirectory().appendingPathComponent(key + ".realm")
                try FileManager.default.removeItem(at: realmFile)
                let realmFileLock = URL.applicationDocumentsDirectory().appendingPathComponent(key + ".realm.lock")
                try FileManager.default.removeItem(at: realmFileLock)
                let realmManagement = URL.applicationDocumentsDirectory().appendingPathComponent(key + ".realm.management")
                try FileManager.default.removeItem(at: realmManagement)
            }
            self.cleanUpAll()
        } catch {
            print("RealmManager - \(#function): Unresolved error delete realm files: \(error)")
            throw error
        }
    }
    
    // MARK: - Private methods
    private static func setContext(_ context: Realm?, databaseKey: String) {
        realmContexts[databaseKey] = context
    }
    
    private static func validPassphrase(_ passphrase: String) -> Data? {
        //Custom logic to force a 64 characters passphrase (required by Realm)
        var finalPassphrase = passphrase
        let keyLenght = 64
        
        while finalPassphrase.count < keyLenght {
            finalPassphrase.append(passphrase)
        }
        
        let index = finalPassphrase.index(finalPassphrase.startIndex, offsetBy: keyLenght)
        let realmKey = finalPassphrase[..<index]
        
        let keyData = realmKey.data(using: String.Encoding.utf8, allowLossyConversion: false)
        
        return keyData
    }

    private static func getSchemaVersion(databaseKey: String) -> UInt64 {
        if let persistedVersion = UserDefaults.standard.value(forKey: "\(databaseKey)\(schemaVersionKey)") as? NSNumber {
            return UInt64.init(truncating: persistedVersion)
        }
        return 0
    }
    
    private static func setSchemaVersion(_ newSchemaVersion: UInt64, databaseKey: String) {
        UserDefaults.standard.set(newSchemaVersion, forKey: "\(databaseKey)\(schemaVersionKey)")
    }
    
    private static func currentStack(_ databaseKey: String) -> String {
        let onThread: String = Thread.isMainThread ? "*** MAIN THREAD ***" : "*** BACKGROUND THREAD ***"
        var status: String = "---- Current Default Realm Stack: ----\n"
        status += "Thread:                             \(onThread)\n"
        status += "Default Context:                    \(String(describing: getRealm(databaseKey: databaseKey)))\n"
        status += "Path:                               \(String(describing: getRealm(databaseKey: databaseKey)?.configuration.fileURL))\n"
        if let schema = realmContexts[databaseKey]?.schema {
            status += "Schema description:            \(schema.description)\n"
        } else {
            status += "Schema description: none\n"
        }
        
        return status
    }
}
