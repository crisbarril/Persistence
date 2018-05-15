//
//  RealmManager.swift
//  PersistenceFramework
//
//  Created by Cristian on 13/05/2018.
//  Copyright © 2018 Cristian Barril. All rights reserved.
//

import RealmSwift

protocol RealmImplementation {
    static var sharedInstance: RealmImplementation { get }
    var realmContextCache: [String: Realm] { get }
    
    func initialize(_ builder: RealmBuilder) throws
    func getContext(_ databaseName: String) -> Realm?
}

final class RealmManager: RealmImplementation {
    // MARK: Singleton
    static var sharedInstance: RealmImplementation = RealmManager()
    
    // MARK: Private properties
    var realmContextCache: [String : Realm] = [:]
    private let schemaVersionKey = "schemaVersionKey"
    
    func initialize(_ builder: RealmBuilder) throws {
        guard realmContextCache[builder.databaseName] == nil else {
            print("Already initialized Realm database for key: \(builder.databaseName).")
            return
        }
        
        guard !builder.passphrase.isEmpty, let keyData = validPassphrase(builder.passphrase) else {
            throw ErrorFactory.createError(withKey: "Error passphrase", failureReason: "Error recovering passphrase from builder: \(builder)", domain: "RealmManager")
        }
        
        var persistedSchemaVersion = getSchemaVersion(databaseName: builder.databaseName)
        if builder.schemaVersion > persistedSchemaVersion {
            persistedSchemaVersion = builder.schemaVersion
        }
        
        let url = URL.applicationDocumentsDirectory().appendingPathComponent(builder.databaseName + ".realm")
        let config = Realm.Configuration(
            fileURL: url,
            encryptionKey: keyData,
            schemaVersion: persistedSchemaVersion,
            migrationBlock: builder.migrationBlock
        )
        
        do {
            let realm = try Realm(configuration: config)
            setContext(realm, databaseName: builder.databaseName)
            setSchemaVersion(persistedSchemaVersion, databaseName: builder.databaseName)
            print("All Realm settings for database \(builder.databaseName) done!\n \(currentStack(builder.databaseName))")
        } catch {
            let nserror = error as NSError
            print("RealmManager - \(#function): Unresolved error for \(builder.databaseName): \(nserror), \(nserror.userInfo)")
            
            throw nserror
        }
    }
    
    func getContext(_ databaseName: String) -> Realm? {
        return realmContextCache[databaseName]
    }
    
    internal func cleanUpAll() {
        realmContextCache = [String: Realm]()
        print("RealmManager - \(#function): Clean DONE for all contexts")
    }
    
    internal func deleteAllRealm() throws {
        do {
            for (key, context) in realmContextCache {
                try! context.write {
                    context.deleteAll()
                }
                let realmFile = URL.applicationDocumentsDirectory().appendingPathComponent(key + ".realm")
                try FileManager.default.removeItem(at: realmFile)
                let realmFileLock = URL.applicationDocumentsDirectory().appendingPathComponent(key + ".realm.lock")
                try FileManager.default.removeItem(at: realmFileLock)
                let realmManagement = URL.applicationDocumentsDirectory().appendingPathComponent(key + ".realm.management")
                try FileManager.default.removeItem(at: realmManagement)
                setSchemaVersion(0, databaseName: key)
            }
            self.cleanUpAll()
        } catch {
            print("RealmManager - \(#function): Unresolved error delete realm files: \(error)")
            throw error
        }
    }
    
    // MARK: - Private methods
    private func setContext(_ context: Realm?, databaseName: String) {
        realmContextCache[databaseName] = context
    }
    
    private func validPassphrase(_ passphrase: String) -> Data? {
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
    
    private func getSchemaVersion(databaseName: String) -> UInt64 {
        if let persistedVersion = UserDefaults.standard.value(forKey: "\(databaseName)\(schemaVersionKey)") as? NSNumber {
            return UInt64.init(truncating: persistedVersion)
        }
        return 0
    }
    
    private func setSchemaVersion(_ newSchemaVersion: UInt64, databaseName: String) {
        UserDefaults.standard.set(newSchemaVersion, forKey: "\(databaseName)\(schemaVersionKey)")
    }
    
    private func currentStack(_ databaseName: String) -> String {
        let onThread: String = Thread.isMainThread ? "*** MAIN THREAD ***" : "*** BACKGROUND THREAD ***"
        var status: String = "---- Current Realm Stack: ----\n"
        status += "Thread:                             \(onThread)\n"
        status += "Context:                             \(String(describing: getContext(databaseName)))\n"
        status += "Path:                               \(String(describing: getContext(databaseName)?.configuration.fileURL))\n"
        if let schema = realmContextCache[databaseName]?.schema {
            status += "Schema description:            \(schema.description)\n"
        } else {
            status += "Schema description: none\n"
        }
        
        return status
    }
}
