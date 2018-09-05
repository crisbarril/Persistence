//
//  RealmManager.swift
//  Persistence
//
//  Created by Cristian on 13/05/2018.
//  Copyright © 2018 Cristian Barril. All rights reserved.
//

import RealmSwift

extension Object: DatabaseObjectTypeProtocol {}

public final class RealmManager: DatabaseProtocol {
    public typealias DatabaseObjectType = Object
    public typealias DatabaseContext = Realm
    
    public let context: Realm
    
    public init(withContext context: Realm) {
        self.context = context
    }
    
    public func create<ReturnType>() -> ReturnType? where ReturnType : DatabaseObjectTypeProtocol {
        return ReturnType()
    }
    
    public func recover<ReturnType>(key: String = "", value: String = "") -> [ReturnType]? where ReturnType : DatabaseObjectTypeProtocol {
        guard let returnClass = ReturnType.self as? Object.Type else {
            return nil
        }
        
        let resultObjects = context.objects(returnClass)
        
        if !key.isEmpty && !value.isEmpty {
            let filteredResultObjects = resultObjects.filter("\(key) = '\(value)'")
            return Array(filteredResultObjects) as? [ReturnType]
        }
        
        return Array(resultObjects) as? [ReturnType]
    }
    
    public func delete(_ object: Object) -> Bool {
        do {
            try context.write {
                context.delete(object)
            }
            return true
        } catch {
            print("Fail to delete object: \(object)")
            return false
        }
    }
    
    public func getContext() -> Realm {
        return context
    }
}

extension RealmManager: Updatable {
    public func update<T>(_ object: T) -> Bool where T : DatabaseObjectTypeProtocol {
        guard let objectClass = T.self as? Object.Type, let objectInstance = object as? Object else {
            return false
        }
        
        let hasPrimaryKey = objectClass.primaryKey() != nil
        
        do {
            try context.write {
                context.add(objectInstance, update: hasPrimaryKey)
            }
            return true
        } catch {
            print("Fail to delete object: \(object)")
            return false
        }
    }
}
