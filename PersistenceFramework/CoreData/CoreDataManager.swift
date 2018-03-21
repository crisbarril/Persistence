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
struct CoreDataManager {
    
    // MARK: - Privates properties
    private static var managedObjectContextCache = [String: NSManagedObjectContext]()
    
    internal static func initialize(_ databaseKey: String, bundle: Bundle, modelURL: URL) throws {
        
        // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
        guard let managedObjectModel = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Error initializing NSManagedObjectModel from URL: \(modelURL)")
        }
        
        guard !databaseKey.isEmpty else {
            fatalError("Must specify a name for the initialization of the database")
        }
        
        if managedObjectContextCache[databaseKey] != nil {
            throw ErrorFactory.createError(withKey: "Already initialized", failureReason: "Already initialized CoreData database with key: \(databaseKey).", domain: "CoreDataManager")
        }
        
        let isMigrationNedeed = isMigrationNeeded(databaseKey, managedObjectModel: managedObjectModel)
        if isMigrationNedeed {
            do {
                try migrate(databaseKey, bundle: bundle, currentManagedObjectModel: managedObjectModel)
            } catch {
                throw ErrorFactory.createError(withKey: "Migration", failureReason: "Fail to migrate database \(databaseKey) with error: \(error)", domain: "CoreDataManager")
            }
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
            throw ErrorFactory.createError(withKey: "No context", failureReason: "There was an error in the initialization of the database.", domain: "CoreDataManager")
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
        let url = getStoreUrl(databaseKey)
        
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
                let wrappedError = ErrorFactory.createError(withKey: "Loading PersistentStores", failureReason: "There was an error creating or loading the application's stores. Error: \(String(describing: error))", domain: "CoreDataManager")
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
            throw ErrorFactory.createError(withKey: "Recovering PersistentStores", failureReason: "There was an error creating or loading the application's stores.", domain: "CoreDataManager")
        }
        
        return container
    }
    
    private static func getStoreUrl(_ databaseKey: String) -> URL {
        return URL.applicationDocumentsDirectory().appendingPathComponent(databaseKey)
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
    
    // MARK: - migration privates methods
    private static func isMigrationNeeded(_ databaseKey: String, managedObjectModel: NSManagedObjectModel) -> Bool {

        let storeUrl =  getStoreUrl(databaseKey)
        
        guard FileManager.default.fileExists(atPath: storeUrl.path) else {
            print("Doesn't exist store with key: \(databaseKey). New database.")
            return false
        }
        
        do {
            let metadata = try NSPersistentStoreCoordinator.metadataForPersistentStore(ofType: NSSQLiteStoreType, at: storeUrl, options: nil)

            let pscCompatible: Bool = managedObjectModel.isConfiguration(withName: nil, compatibleWithStoreMetadata: metadata)
            return !pscCompatible
        } catch {
            print("FAIL to get metadata with error: \(error)")
            return false
        }
    }
    
    private static func migrate(_ databaseKey: String, bundle: Bundle, currentManagedObjectModel: NSManagedObjectModel) throws {

        let storeUrl =  getStoreUrl(databaseKey)
        
        guard let metadata = try? NSPersistentStoreCoordinator.metadataForPersistentStore(ofType: NSSQLiteStoreType, at: storeUrl, options: nil) else {
            print("FAILED to recover store metadata.")
            throw ErrorFactory.createError(withKey: "Recovering metadata", failureReason: "There was an error loading the store metadata.", domain: "CoreDataManager")
        }
        
        guard let sourceModel = NSManagedObjectModel.mergedModel(from: [bundle], forStoreMetadata: metadata) else {
            print("FAILED to create source model, something wrong with source xcdatamodel.")
            throw ErrorFactory.createError(withKey: "Recovering source model", failureReason: "Fail to create source model from bundle: \(bundle).", domain: "CoreDataManager")
        }
        
        let migrationManager = NSMigrationManager(sourceModel: sourceModel, destinationModel: currentManagedObjectModel)
        var mappingModel: NSMappingModel?
        
        do {
            try mappingModel = NSMappingModel.inferredMappingModel(forSourceModel: sourceModel, destinationModel: currentManagedObjectModel)
        } catch  {
            print("FAILED to inferred mapping model with error: \(error).\nProceed to recover mapping model from bundle \(bundle).")
            mappingModel = NSMappingModel(from: [bundle], forSourceModel: sourceModel, destinationModel: currentManagedObjectModel)
        }

        guard mappingModel != nil else {
            print("FAILED to create mapping model, check the MappingModel file in bundle \(bundle).")
            throw ErrorFactory.createError(withKey: "Generating mapping model", failureReason: "Fail to generate mapping model from bundle: \(bundle).", domain: "CoreDataManager")
        }
        
        let destinationUrl = URL.applicationDocumentsDirectory().appendingPathComponent("\(databaseKey)_2")
        
        do {
            try migrationManager.migrateStore(from: storeUrl, sourceType: NSSQLiteStoreType, options: nil, with: mappingModel, toDestinationURL: destinationUrl, destinationType: NSSQLiteStoreType, destinationOptions: nil)
            
            try FileManager.default.removeItem(atPath: storeUrl.path)
            try FileManager.default.moveItem(atPath: destinationUrl.path, toPath: storeUrl.path)
        } catch {
            print("FAILED to migrate model in bundle \(bundle). Error: \(error)")
            throw ErrorFactory.createError(withKey: "Migrating model", failureReason: "Fail to migrate model in bundle \(bundle). Error: \(error)", domain: "CoreDataManager")
        }
    }
}
