//
//  CoreDataBuilder.swift
//  PersistenceFramework
//
//  Created by Cristian on 10/05/2018.
//  Copyright © 2018 Cristian Barril. All rights reserved.
//

import Foundation

protocol CoreDataBuilderProtocol: DatabaseBuilderProtocol {
    var bundle: Bundle { get }
    var modelURL: URL { get }
}

public struct CoreDataBuilder: CoreDataBuilderProtocol {
    public typealias Database = CoreDataManager
    
    public let databaseName: String
    public let bundle: Bundle
    public let modelURL: URL
    
    public init(databaseName: String, bundle: Bundle, modelURL: URL) {
        self.databaseName = databaseName
        self.bundle = bundle
        self.modelURL = modelURL
    }
    
    public func create() throws -> CoreDataManager {
        do {
            let context = try CoreDataImplementation.sharedInstance.createContext(withBuilder: self)
            return CoreDataManager(withContext: context)
        } catch {
            throw ErrorFactory.createError(withKey: "Builder fail", failureReason: "Error creating CoreData with error: \(error)", domain: "CoreDataBuilder")
        }
    }
}
