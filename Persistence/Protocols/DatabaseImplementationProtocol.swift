//
//  DatabaseImplementationProtocol.swift
//  Persistence
//
//  Created by Cristian on 24/05/2018.
//  Copyright © 2018 Cristian Barril. All rights reserved.
//

import Foundation

protocol DatabaseImplementationProtocol {
    associatedtype DatabaseBuilder: DatabaseBuilderProtocol
    associatedtype DatabaseContext
    
    static var sharedInstance: Self { get }
    var contextsCache: [String: DatabaseContext] { get }
    
    func createContext(withBuilder builder: DatabaseBuilder) throws -> DatabaseContext
    func getContext(forDatabaseName databaseName: String) -> DatabaseContext?
}
