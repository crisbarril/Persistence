//
//  DatabaseProtocol.swift
//  Persistence
//
//  Created by Cristian on 10/05/2018.
//  Copyright © 2018 Cristian Barril. All rights reserved.
//

import Foundation

//Generics methods that every database must implement

public protocol DatabaseProtocol {
    associatedtype DatabaseObjectType: DatabaseObjectTypeProtocol
    associatedtype DatabaseContext
    
    var context: DatabaseContext { get }
    
    init(withContext context: DatabaseContext)
    
    func create<ReturnType: DatabaseObjectTypeProtocol>() -> ReturnType?
    func recover<ReturnType: DatabaseObjectTypeProtocol>(key: String, value: String) -> [ReturnType]?
    func delete(_ object: DatabaseObjectType) -> Bool
    func getContext() -> DatabaseContext
}

public protocol DatabaseObjectTypeProtocol {
    //Used to validate DatabaseProtocol associatedtype in generics functions. Must extend the database entity object to conform this protocol
    init()
}
