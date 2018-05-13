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
    public let databaseType: DatabaseType = .Realm
    public let databaseName: String
    public let bundle: Bundle
    public let passphrase: String
    public let schemaVersion: UInt64
    public let migrationBlock: MigrationBlock?
    
    init(databaseName: String, bundle: Bundle, passphrase: String, schemaVersion: UInt64 = 0, migrationBlock: MigrationBlock? = nil) {
        self.databaseName = databaseName
        self.bundle = bundle
        self.passphrase = passphrase
        self.schemaVersion = schemaVersion
        self.migrationBlock = migrationBlock
    }
}
