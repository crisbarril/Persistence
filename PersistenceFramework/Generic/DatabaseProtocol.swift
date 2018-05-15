//
//  DatabaseProtocol.swift
//  PersistenceFramework
//
//  Created by Cristian on 10/05/2018.
//  Copyright © 2018 Cristian Barril. All rights reserved.
//

import Foundation

public protocol DatabaseConfigurationProtocol {
    var databaseName: String { get }
    var bundle: Bundle { get }
}

extension DatabaseConfigurationProtocol {
    var databaseKey: String {
        get {
            return "\(self.bundle).\(self.databaseName)"
        }
    }
}

public protocol DatabaseBuilderProtocol: DatabaseConfigurationProtocol {
    func initialize<DatabaseTypeProtocol: DatabaseProtocol>() throws -> DatabaseTypeProtocol
}

public protocol DatabaseObjectTypeProtocol {
    //Used to validate DatabaseProtocol associatedtype in generics functions. Must extend the database entity object to conform this protocol
    init()
}

public protocol DatabaseProtocol {
    associatedtype DatabaseObjectType: DatabaseObjectTypeProtocol
    associatedtype DatabaseContextType
    var databaseConfiguration: DatabaseConfigurationProtocol { get }
    var databaseContext: DatabaseContextType { get }
    
    func create<ReturnType: DatabaseObjectTypeProtocol>() -> ReturnType?
    func recover<ReturnType: DatabaseObjectTypeProtocol>(key: String, value: String) -> [ReturnType]?
    func delete(_ object: DatabaseObjectType) -> Bool
    func getContext() -> DatabaseContextType
}

public protocol Updatable: DatabaseProtocol {
    func update<T: DatabaseObjectTypeProtocol>(_ object: T) -> Bool
}

public protocol Saveable: DatabaseProtocol {
    func save() throws
}
