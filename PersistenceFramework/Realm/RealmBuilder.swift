//
//  RealmBuilder.swift
//  PersistenceFramework
//
//  Created by Cristian on 13/05/2018.
//  Copyright © 2018 Cristian Barril. All rights reserved.
//

import Foundation
import RealmSwift

protocol RealmBuilderProtocol: DatabaseBuilderProtocol {
    var passphrase: String { get }
    var schemaVersion: UInt64 { get }
    var migrationBlock: MigrationBlock? { get }
}

public struct RealmBuilder: RealmBuilderProtocol {
    public let databaseName: String
    public let passphrase: String
    public let schemaVersion: UInt64
    public let migrationBlock: MigrationBlock?
    
    public init(databaseName: String, passphrase: String, schemaVersion: UInt64 = 0, migrationBlock: MigrationBlock? = nil) {
        self.databaseName = databaseName
        self.passphrase = passphrase
        self.schemaVersion = schemaVersion
        self.migrationBlock = migrationBlock
    }
    
    public func initialize<DatabaseTypeProtocol>() throws -> DatabaseTypeProtocol where DatabaseTypeProtocol : DatabaseProtocol {
        do {
            try RealmManager.sharedInstance.initialize(self)
            let realmAPI = try RealmAPI(databaseConfiguration: self, realmInstance: RealmManager.sharedInstance)
            if let result = realmAPI as? DatabaseTypeProtocol {
                return result
            } else {
                throw ErrorFactory.createError(withKey: "Builder fail", failureReason: "Error creating Realm managet", domain: "DatabaseFactory")
            }
        } catch{
            throw error
        }
    }
}
