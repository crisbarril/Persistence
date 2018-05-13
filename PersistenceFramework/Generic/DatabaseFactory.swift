//
//  DatabaseFactory.swift
//  PersistenceFramework
//
//  Created by Cristian on 10/05/2018.
//  Copyright © 2018 Cristian Barril. All rights reserved.
//

import Foundation

public enum DatabaseType {
    case CoreData
    case Realm
}

public protocol DatabaseBuilderProtocol: DatabaseConfigurationProtocol {
    var databaseType: DatabaseType { get }
}

/*
 
 1 - La App crea un `CoreDataBuilder` con los datos que necesita
 2 - Lo pasa al DatabaseFactory y le devuelve un `CoreDataManager: DatabaseProtocol` para ese builder (para ese "bundle.name")
    - Con el builder inicializa la implementacion y la setea en el manager
    - Si no existe, la crea. Sino recupera el context
 */

public struct DatabaseFactory {
    
    static func initialize<DatabaseTypeProtocol: DatabaseProtocol>(_ builder: DatabaseBuilderProtocol) throws -> DatabaseTypeProtocol {
        
        switch builder.databaseType {
        case .CoreData:
            
            guard let coreDataBuilder = builder as? CoreDataBuilder else {
                throw ErrorFactory.createError(withKey: "Builder type", failureReason: "Builder type is not correct for \(builder.databaseType)", domain: "DatabaseFactory")
            }
            
            do {
                try CoreDataManager.sharedInstance.initialize(coreDataBuilder)
                let coreDataAPI = try CoreDataAPI(databaseConfiguration: coreDataBuilder, coreDataInstance: CoreDataManager.sharedInstance)
                if let result = coreDataAPI as? DatabaseTypeProtocol {
                    return result
                } else {
                    throw ErrorFactory.createError(withKey: "Builder fail", failureReason: "Error creating CoreData managet", domain: "DatabaseFactory")
                }
            } catch{
                throw error
            }
            
        case .Realm:
            
            guard let realmBuilder = builder as? RealmBuilder else {
                throw ErrorFactory.createError(withKey: "Builder type", failureReason: "Builder type is not correct for \(builder.databaseType)", domain: "DatabaseFactory")
            }
            
            do {
                try RealmManager.sharedInstance.initialize(realmBuilder)
                let realmAPI = try RealmAPI(databaseConfiguration: realmBuilder, realmInstance: RealmManager.sharedInstance)
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
}
