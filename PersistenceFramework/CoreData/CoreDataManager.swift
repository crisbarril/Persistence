//
//  CoreDataManager.swift
//  PersistenceFramework
//
//  Created by Cristian on 13/03/2018.
//  Copyright © 2018 Cristian Barril. All rights reserved.
//

import Foundation
import CoreData

@available(iOS, message: "This class is only available for iOS.")
class CoreDataManager {
    
    // MARK: - Privates properties
    private static var managedObjectContextCache = [String: NSManagedObjectContext]()
    
    internal static func initialize(_ databaseKey: String, modelURL: URL) throws {
        
        // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
        guard let managedObjectModel = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Error initializing NSManagedObjectModel from URL: \(modelURL)")
        }
        
        guard !databaseKey.isEmpty else {
            fatalError("Must specify a name for the initialization of the database")
        }
        
        if managedObjectContextCache[databaseKey] != nil {
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Already initialized" as AnyObject?
            dict[NSLocalizedFailureReasonErrorKey] = "Already initialized CoreData database with key: \(databaseKey)." as AnyObject?
            
            let wrappedError = NSError(domain: "CoreDataManager", code: 999, userInfo: dict)
            throw wrappedError
        }
        
        do {
            if let container = try loadPersistentContainer(databaseKey, managedObjectModel: managedObjectModel) {
                setContext(container.viewContext, forDatabase: databaseKey)
                print("All CoreData settings for database \(databaseKey) done!\n \(currentStack(databaseKey, managedObjectModel: managedObjectModel, container: container))")
            }
        } catch  {
            throw error
        }
    }
    
    internal static func getContext(_ databaseKey: String) -> NSManagedObjectContext? {
        return managedObjectContextCache[databaseKey]
    }
    
    internal static func saveContext(_ databaseKey: String) throws {
        if let context = getContext(databaseKey) {
            if (context.hasChanges) {
                var saveError: NSError? = nil
                context.perform {
                    do {
                        try context.save()
                        print("Async save DONE for database \(databaseKey)")
                    } catch {
                        saveError = error as NSError
                        print("Unresolved error \(String(describing: saveError)), \(String(describing: saveError?.userInfo))")
                    }
                }
                if let error = saveError {
                    throw error
                }
            }
        } else {
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to recover the context for \(databaseKey)" as AnyObject?
            dict[NSLocalizedFailureReasonErrorKey] = "There was an error in the initialization of the database." as AnyObject?
            
            let wrappedError = NSError(domain: "CoreDataManager", code: 999, userInfo: dict)
            throw wrappedError
        }
    }
    
    internal static func cleanUp(_ databaseKey: String) {
        setContext(nil, forDatabase: databaseKey)
        print("Clean DONE for database \(databaseKey)")
    }
    
    internal static func cleanUpAll() {
        managedObjectContextCache.removeAll()
    }
    
    internal static func deleteAllCoreData() throws {
        do {
            for managedObjectContext in managedObjectContextCache {
                let urlFile = URL.applicationDocumentsDirectory().appendingPathComponent(managedObjectContext.key)
                try FileManager.default.removeItem(atPath: urlFile.path)
            }
        } catch {
            print("Unresolved error delete coredata files")
        }
        cleanUpAll()
    }
    
    // MARK: - privates methods
    private static func setContext(_ defaultContext: NSManagedObjectContext?, forDatabase databaseKey: String ) {
        managedObjectContextCache[databaseKey] = defaultContext
    }
    
    private static func loadPersistentContainer(_ databaseKey: String, managedObjectModel: NSManagedObjectModel) throws -> NSPersistentContainer? {
        let container = NSPersistentContainer(name: databaseKey, managedObjectModel: managedObjectModel)
        let url =  URL.applicationDocumentsDirectory().appendingPathComponent(databaseKey)
        
        // Create Persistent Store Description
        let persistentStoreDescription = NSPersistentStoreDescription(url: url)
        
        // Configure Persistent Store Description
        persistentStoreDescription.type = NSSQLiteStoreType
        persistentStoreDescription.shouldMigrateStoreAutomatically = true
        persistentStoreDescription.shouldInferMappingModelAutomatically = true
        
        var loadingPersistentStoresError: NSError? = nil
        
        container.persistentStoreDescriptions = [persistentStoreDescription]
        container.loadPersistentStores { (storeDescription, error) in
            if error != nil {
                var dict = [String: AnyObject]()
                dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's data" as AnyObject?
                dict[NSLocalizedFailureReasonErrorKey] = "There was an error creating or loading the application's data." as AnyObject?
                dict[NSUnderlyingErrorKey] = error as AnyObject
                
                let wrappedError = NSError(domain: "CoreDataManager", code: 999, userInfo: dict)
                print("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
                
                loadingPersistentStoresError = wrappedError
            }
        }
        
        if let error = loadingPersistentStoresError {
            throw error
        }
        
        if !container.persistentStoreCoordinator.persistentStores.isEmpty {
            let dict = container.persistentStoreCoordinator.metadata(for:container.persistentStoreCoordinator.persistentStores[0])
            print("Container - metadata for persistentStores (element 0): \(dict)")
        } else {
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's data" as AnyObject?
            dict[NSLocalizedFailureReasonErrorKey] = "There was an error creating or loading the application's data." as AnyObject?
            let wrappedError = NSError(domain: "CoreDataManager", code: 999, userInfo: dict)
            throw wrappedError
        }
        
        return container
    }

    private static func currentStack(_ databaseKey: String, managedObjectModel: NSManagedObjectModel, container: NSPersistentContainer) -> String {
        let onThread: String = Thread.isMainThread ? "*** MAIN THREAD ***" : "*** BACKGROUND THREAD ***"
        var status: String = "---- Current Default Core Data Stack: ----\n"
        status += "Thread:                             \(onThread)\n"
        status += "Default Context:                    \(String(describing: getContext(databaseKey)))\n"
        status += "Models (versionIdentifiers):        \(String(describing: managedObjectModel.versionIdentifiers.first?.description))\n"
        status += "Models (entityVersionHashesByName): \(String(describing: managedObjectModel.entityVersionHashesByName))\n"
        for entity in managedObjectModel.entities {
            status += "Models (Entity version):            \(entity.name!) - \(String(describing: entity.versionHashModifier))\n"
        }
        status += "PersistentContainer (iOS 10):       \(String(describing: container))\n"
        status += "Database Name (iOS 10):                     \(databaseKey)"
        
        return status
    }
}
