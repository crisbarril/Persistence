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
    public typealias Database = RealmManager
    
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
    
    public func create() throws -> RealmManager {
        do {
            let context = try RealmImplementation.sharedInstance.createContext(withBuilder: self)
            return RealmManager(withContext: context)
        } catch {
            throw ErrorFactory.createError(withKey: "Builder fail", failureReason: "Error creating RealmAPI with error: \(error)", domain: "RealmBuilder")
        }
    }
}
