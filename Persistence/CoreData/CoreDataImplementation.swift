//
//  CoreDataImplementation.swift
//  Persistence
//
//  Created by Cristian on 09/05/2018.
//  Copyright © 2018 Cristian Barril. All rights reserved.
//

import CoreData

final class CoreDataImplementation: DatabaseImplementationProtocol {
    typealias DatabaseBuilder = CoreDataBuilder
    typealias DatabaseContext = NSManagedObjectContext
    
    // MARK: Singleton
    static var sharedInstance: CoreDataImplementation = CoreDataImplementation()
    
    // MARK: Private properties
    var contextsCache: [String : NSManagedObjectContext] = [:]
    
    func createContext(withBuilder builder: CoreDataBuilder) throws -> NSManagedObjectContext {
        if let context = contextsCache[builder.databaseName] {
            print("Already created CoreData context for key: \(builder.databaseName).")
            return context
        }
        
        guard let managedObjectModel = NSManagedObjectModel(contentsOf: builder.modelURL) else {
            throw ErrorFactory.createError(withKey: "Error initializing NSManagedObjectModel", failureReason: "Error initializing NSManagedObjectModel from URL: \(builder.modelURL)", domain: "CoreDataImplementation")
        }
        
        let isMigrationNedeed = isMigrationNeeded(builder.databaseName, managedObjectModel: managedObjectModel)
        if isMigrationNedeed {
            do {
                try migrate(builder.databaseName, bundle: builder.bundle, currentManagedObjectModel: managedObjectModel)
            } catch {
                throw ErrorFactory.createError(withKey: "Migration", failureReason: "Fail to migrate database \(builder.databaseName) with error: \(error)", domain: "CoreDataImplementation")
            }
        }
        
        do {
            if let container = try loadPersistentContainer(builder.databaseName, managedObjectModel: managedObjectModel) {
                setContext(container.viewContext, forDatabase: builder.databaseName)
                print("All CoreData settings for database \(builder.databaseName) done!\n \(currentStack(builder.databaseName, managedObjectModel: managedObjectModel, container: container))")
                
                return container.viewContext
            }
            else {
                throw ErrorFactory.createError(withKey: "Error recovering context", failureReason: "Error recovering NSManagedObjectContext", domain: "CoreDataImplementation")
            }
        } catch  {
            throw error
        }
    }
    
    internal func getContext(forDatabaseName databaseName: String) -> NSManagedObjectContext? {
        return contextsCache[databaseName]
    }
    
    internal func cleanUpAll() {
        contextsCache.removeAll()
    }
    
    internal func deleteAllCoreData() throws {
        do {
            for managedObjectContext in contextsCache {
                let urlFile = DatabaseHelper.getStoreUrl(managedObjectContext.key)
                try FileManager.default.removeItem(atPath: urlFile.path)
            }
        } catch {
            print("Unresolved error delete coredata files")
            throw error
        }
        cleanUpAll()
    }
    
    // MARK: - privates methods
    private func setContext(_ defaultContext: NSManagedObjectContext?, forDatabase databaseName: String ) {
        contextsCache[databaseName] = defaultContext
    }
    
    private func loadPersistentContainer(_ databaseName: String, managedObjectModel: NSManagedObjectModel) throws -> NSPersistentContainer? {
        let container = NSPersistentContainer(name: databaseName, managedObjectModel: managedObjectModel)
        let url = DatabaseHelper.getStoreUrl(databaseName)
        
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
                let wrappedError = ErrorFactory.createError(withKey: "Loading PersistentStores", failureReason: "There was an error creating or loading the application's stores. Error: \(String(describing: error))", domain: "CoreDataImplementation")
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
            throw ErrorFactory.createError(withKey: "Recovering PersistentStores", failureReason: "There was an error creating or loading the application's stores.", domain: "CoreDataImplementation")
        }
        
        return container
    }
    
    private func currentStack(_ databaseName: String, managedObjectModel: NSManagedObjectModel, container: NSPersistentContainer) -> String {
        let onThread: String = Thread.isMainThread ? "*** MAIN THREAD ***" : "*** BACKGROUND THREAD ***"
        var status: String = "---- Current Core Data Stack: ----\n"
        status += "Thread:                             \(onThread)\n"
        status += "Context:                             \(String(describing: getContext(forDatabaseName: databaseName)))\n"
        status += "Models (versionIdentifiers):        \(String(describing: managedObjectModel.versionIdentifiers.first?.description))\n"
        status += "Models (entityVersionHashesByName): \(String(describing: managedObjectModel.entityVersionHashesByName))\n"
        for entity in managedObjectModel.entities {
            status += "Models (Entity version):            \(entity.name!) - \(String(describing: entity.versionHashModifier))\n"
        }
        status += "PersistentContainer:       \(String(describing: container))\n"
        status += "Database Name:                     \(databaseName)"
        
        return status
    }
    
    // MARK: - migration privates methods
    private func isMigrationNeeded(_ databaseName: String, managedObjectModel: NSManagedObjectModel) -> Bool {
        
        let storeUrl = DatabaseHelper.getStoreUrl(databaseName)
        
        guard FileManager.default.fileExists(atPath: storeUrl.path) else {
            print("Doesn't exist store with key: \(databaseName). New database.")
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
    
    private func migrate(_ databaseName: String, bundle: Bundle, currentManagedObjectModel: NSManagedObjectModel) throws {
        
        let storeUrl = DatabaseHelper.getStoreUrl(databaseName)
        
        guard let metadata = try? NSPersistentStoreCoordinator.metadataForPersistentStore(ofType: NSSQLiteStoreType, at: storeUrl, options: nil) else {
            print("FAILED to recover store metadata.")
            throw ErrorFactory.createError(withKey: "Recovering metadata", failureReason: "There was an error loading the store metadata.", domain: "CoreDataImplementation")
        }
        
        guard let sourceModel = NSManagedObjectModel.mergedModel(from: [bundle], forStoreMetadata: metadata) else {
            print("FAILED to create source model, something wrong with source xcdatamodel.")
            throw ErrorFactory.createError(withKey: "Recovering source model", failureReason: "Fail to create source model from bundle: \(bundle).", domain: "CoreDataImplementation")
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
            throw ErrorFactory.createError(withKey: "Generating mapping model", failureReason: "Fail to generate mapping model from bundle: \(bundle).", domain: "CoreDataImplementation")
        }
        
        let destinationUrl = URL.applicationDocumentsDirectory().appendingPathComponent("\(databaseName)_2")
        
        do {
            try migrationManager.migrateStore(from: storeUrl, sourceType: NSSQLiteStoreType, options: nil, with: mappingModel, toDestinationURL: destinationUrl, destinationType: NSSQLiteStoreType, destinationOptions: nil)
            
            try FileManager.default.removeItem(atPath: storeUrl.path)
            try FileManager.default.moveItem(atPath: destinationUrl.path, toPath: storeUrl.path)
        } catch {
            print("FAILED to migrate model in bundle \(bundle). Error: \(error)")
            throw ErrorFactory.createError(withKey: "Migrating model", failureReason: "Fail to migrate model in bundle \(bundle). Error: \(error)", domain: "CoreDataImplementation")
        }
    }
}
