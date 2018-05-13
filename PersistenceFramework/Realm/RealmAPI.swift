//
//  RealmAPI.swift
//  PersistenceFramework
//
//  Created by Cristian on 13/05/2018.
//  Copyright © 2018 Cristian Barril. All rights reserved.
//

import RealmSwift

extension Object: DatabaseObjectTypeProtocol {}

public final class RealmAPI: DatabaseProtocol {
    public typealias DatabaseObjectType = Object
    public typealias DatabaseContextType = Realm
    public let databaseConfiguration: DatabaseConfigurationProtocol
    public let databaseContext: Realm
    
    let realmInstance: RealmImplementation
    
    internal init(databaseConfiguration: DatabaseConfigurationProtocol, realmInstance: RealmImplementation) throws {
        self.databaseConfiguration = databaseConfiguration
        self.realmInstance = realmInstance
        
        guard let context = realmInstance.getContext(databaseConfiguration.databaseKey) else {
            throw ErrorFactory.createError(withKey: "Recovering Context", failureReason: "Couldn't recover Realm context for database with key: \(databaseConfiguration.databaseKey).", domain: "RealmAPI")
        }
        
        self.databaseContext = context
    }
    
    public func getContext() -> Realm {
        return databaseContext
    }
    
    public func create<ReturnType>() -> ReturnType? where ReturnType : DatabaseObjectTypeProtocol {
        return ReturnType()
    }
    
    public func recover<ReturnType>(key: String = "", value: String = "") -> [ReturnType]? where ReturnType : DatabaseObjectTypeProtocol {
        guard let returnClass = ReturnType.self as? Object.Type else {
            return nil
        }
        
        let resultObjects = databaseContext.objects(returnClass)
        
        if !key.isEmpty && !value.isEmpty {
            let filteredResultObjects = resultObjects.filter("\(key) = '\(value)'")
            return Array(filteredResultObjects) as? [ReturnType]
        }
        
        return Array(resultObjects) as? [ReturnType]
    }
    
    public func delete(_ object: Object) -> Bool {
        do {
            try databaseContext.write {
                databaseContext.delete(object)
            }
            return true
        } catch {
            print("Fail to delete object: \(object)")
            return false
        }
    }
}

extension RealmAPI: Updatable {
    public func update<T>(_ object: T) -> Bool where T : DatabaseObjectTypeProtocol {
        guard let objectClass = T.self as? Object.Type, let objectInstance = object as? Object else {
            return false
        }
        
        let hasPrimaryKey = objectClass.primaryKey() != nil
        
        do {
            try databaseContext.write {
                databaseContext.add(objectInstance, update: hasPrimaryKey)
            }
            return true
        } catch {
            print("Fail to delete object: \(object)")
            return false
        }
    }
}
