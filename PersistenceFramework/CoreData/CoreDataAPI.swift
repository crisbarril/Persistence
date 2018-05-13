//
//  CoreDataManager.swift
//  PersistenceFramework
//
//  Created by Cristian on 10/05/2018.
//  Copyright © 2018 Cristian Barril. All rights reserved.
//

import CoreData

extension NSManagedObject: DatabaseObjectTypeProtocol {}

public final class CoreDataAPI: DatabaseProtocol {
    public typealias DatabaseObjectType = NSManagedObject
    public typealias DatabaseContextType = NSManagedObjectContext
    public let databaseConfiguration: DatabaseConfigurationProtocol
    public let databaseContext: NSManagedObjectContext
    
    let coreDataInstance: CoreDataImplementation
    
    internal init(databaseConfiguration: DatabaseConfigurationProtocol, coreDataInstance: CoreDataImplementation) throws {
        self.databaseConfiguration = databaseConfiguration
        self.coreDataInstance = coreDataInstance
        
        guard let context = coreDataInstance.getContext(databaseConfiguration.databaseKey) else {
            throw ErrorFactory.createError(withKey: "Recovering Context", failureReason: "Couldn't recover CoreData context for database with key: \(databaseConfiguration.databaseKey).", domain: "CoreDataAPI")
        }
        
        self.databaseContext = context
    }
    
    public func getContext() -> NSManagedObjectContext {
        return databaseContext
    }
    
    public func create<ReturnType>() -> ReturnType? where ReturnType : DatabaseObjectTypeProtocol {
        let testEntityData = NSEntityDescription.insertNewObject(forEntityName: String(describing: ReturnType.self), into: databaseContext) as? ReturnType
        return testEntityData
    }
    
    public func recover<ReturnType>(key: String = "", value: String = "") -> [ReturnType]? where ReturnType : DatabaseObjectTypeProtocol {
        let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: String(describing: ReturnType.self))
        
        if !key.isEmpty && !value.isEmpty {
            let predicate = NSPredicate(format: "\(key) = '\(value)'")
            fetch.predicate = predicate
        }
        
        do {
            let fetchedResult = try databaseContext.fetch(fetch)
            
            if let result = fetchedResult as? [ReturnType] {
                return result
            }
            else {
                return nil
            }
        } catch {
            return nil
        }
    }
    
    public func delete(_ object: NSManagedObject) -> Bool {
        databaseContext.delete(object)
        return true
    }
}

extension CoreDataAPI: Saveable {
    public func save() throws {
        if (databaseContext.hasChanges) {
            var saveError: NSError? = nil
            databaseContext.perform {
                do {
                    try self.databaseContext.save()
                    print("Async save DONE for database \(self.databaseConfiguration.databaseKey)")
                } catch {
                    saveError = error as NSError
                    print("Unresolved error \(String(describing: saveError)), \(String(describing: saveError?.userInfo))")
                }
            }
            if let error = saveError {
                throw error
            }
        } else {
            throw ErrorFactory.createError(withKey: "No context", failureReason: "There was an error in the initialization of the database.", domain: "CoreDataManager")
        }
    }
}
