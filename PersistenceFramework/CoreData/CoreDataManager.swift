//
//  CoreDataManager.swift
//  PersistenceFramework
//
//  Created by Cristian on 10/05/2018.
//  Copyright © 2018 Cristian Barril. All rights reserved.
//

import CoreData

extension NSManagedObject: DatabaseObjectTypeProtocol {}

public final class CoreDataManager: DatabaseProtocol {
    public typealias DatabaseObjectType = NSManagedObject
    public typealias DatabaseContext = NSManagedObjectContext
    
    public let context: NSManagedObjectContext
    
    public init(withContext context: NSManagedObjectContext) {
        self.context = context
    }
    
    public func create<ReturnType>() -> ReturnType? where ReturnType : DatabaseObjectTypeProtocol {
        let testEntityData = NSEntityDescription.insertNewObject(forEntityName: String(describing: ReturnType.self), into: context) as? ReturnType
        return testEntityData
    }
    
    public func recover<ReturnType>(key: String = "", value: String = "") -> [ReturnType]? where ReturnType : DatabaseObjectTypeProtocol {
        let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: String(describing: ReturnType.self))
        
        if !key.isEmpty && !value.isEmpty {
            let predicate = NSPredicate(format: "\(key) = '\(value)'")
            fetch.predicate = predicate
        }
        
        do {
            let fetchedResult = try context.fetch(fetch)
            
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
        context.delete(object)
        return true
    }
    
    public func getContext() -> NSManagedObjectContext {
        return context
    }
}

extension CoreDataManager: Saveable {
    public func save() throws {
        if (context.hasChanges) {
            var saveError: NSError? = nil
            context.perform {
                do {
                    try self.context.save()
                    print("Save database DONE")
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
