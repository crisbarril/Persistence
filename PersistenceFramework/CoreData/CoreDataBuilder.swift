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
    public let databaseType: DatabaseType = .CoreData
    public let databaseName: String
    public let bundle: Bundle
    public let modelURL: URL
}
