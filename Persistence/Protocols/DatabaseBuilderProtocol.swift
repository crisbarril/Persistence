//
//  DatabaseBuilderProtocol.swift
//  Persistence
//
//  Created by Cristian on 24/05/2018.
//  Copyright © 2018 Cristian Barril. All rights reserved.
//

import Foundation

public protocol DatabaseBuilderProtocol {
    associatedtype Database: DatabaseProtocol
    
    var databaseName: String { get }
    
    func create() throws -> Database
}
