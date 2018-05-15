//
//  CoreDataBuilder.swift
//  PersistenceFramework
//
//  Created by Cristian on 10/05/2018.
//  Copyright © 2018 Cristian Barril. All rights reserved.
//

import Foundation

protocol CoreDataBuilderProtocol: DatabaseBuilderProtocol {
    var modelURL: URL { get }
}

public struct CoreDataBuilder: CoreDataBuilderProtocol {
    public let databaseName: String
    public let bundle: Bundle
    public let modelURL: URL
    
    public func initialize<DatabaseTypeProtocol>() throws -> DatabaseTypeProtocol where DatabaseTypeProtocol : DatabaseProtocol {
        do {
            try CoreDataManager.sharedInstance.initialize(self)
            let coreDataAPI = try CoreDataAPI(databaseConfiguration: self, coreDataInstance: CoreDataManager.sharedInstance)
            if let result = coreDataAPI as? DatabaseTypeProtocol {
                return result
            } else {
                throw ErrorFactory.createError(withKey: "Builder fail", failureReason: "Error creating CoreData managet", domain: "CoreDataBuilder")
            }
        } catch{
            throw error
        }
    }
}
