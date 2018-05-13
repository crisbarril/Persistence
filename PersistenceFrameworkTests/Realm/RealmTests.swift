//
//  RealmTests.swift
//  PersistenceFrameworkTests
//
//  Created by Cristian on 06/03/2018.
//  Copyright © 2018 Cristian Barril. All rights reserved.
//

import XCTest
import RealmSwift
@testable import PersistenceFramework

class RealmTests: XCTestCase {

    private let testBundle = Bundle(for: RealmTests.self)
    private let testDatabaseName = "testRealmDatabase"
    private let testDatabaseNameTwo = "testRealmDatabaseTwo"
    private let testDatabaseNameMigration = "testDatabaseNameMigration"
    private let testDatabasePassphrase = "passphrase"
    private let lastSchemaVersion: UInt64 = 0
    private var databaseAPI: RealmAPI!
    private var databaseImplementation: RealmManager!
    private var isMigrationInProgress: Bool {
        get {
            return self.lastSchemaVersion > 0
        }
    }
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        if !isMigrationInProgress {
            let databaseBuilder = RealmBuilder(databaseName: testDatabaseName, bundle: testBundle, passphrase: testDatabasePassphrase)
            databaseAPI = try! DatabaseFactory.initialize(databaseBuilder) as RealmAPI
            databaseImplementation = databaseAPI.realmInstance as! RealmManager
        }
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        
        if !isMigrationInProgress {
            try? databaseImplementation.deleteAllRealm()
            databaseImplementation.cleanUpAll()
        }
        super.tearDown()
    }

    func test_01_Initialize_01_Single() {
        XCTAssertNotNil(databaseAPI)
        XCTAssertNotNil(databaseAPI.databaseContext)
        XCTAssertNotNil(databaseImplementation)
    }
    
    func test_01_Initialize_02_Multi() {
        let databaseBuilder = RealmBuilder(databaseName: testDatabaseNameTwo, bundle: testBundle, passphrase: testDatabasePassphrase)
        let databaseAPITwo = try! DatabaseFactory.initialize(databaseBuilder) as RealmAPI
        
        XCTAssertNotNil(databaseAPI)
        XCTAssertNotNil(databaseAPI.databaseContext)
        XCTAssertNotNil(databaseImplementation)
        
        XCTAssertNotNil(databaseAPITwo)
        XCTAssertNotNil(databaseAPITwo.databaseContext)
        XCTAssertNotNil(databaseAPITwo.realmInstance)
        
        XCTAssertNotEqual(databaseAPITwo.databaseContext, databaseAPI.databaseContext, "Context are equals")
    }
    
    func test_01_Initialize_03_Repeated() {
        let databaseBuilder = RealmBuilder(databaseName: testDatabaseName, bundle: testBundle, passphrase: testDatabasePassphrase)
        let databaseAPITwo = try! DatabaseFactory.initialize(databaseBuilder) as RealmAPI
        
        XCTAssertNotNil(databaseAPITwo)
        XCTAssertNotNil(databaseAPITwo.databaseContext)
        XCTAssertEqual(databaseAPITwo.databaseContext, databaseAPI.databaseContext, "Context aren't equals")
    }
    
    func test_01_Initialize_04_KO() {
        let databaseBuilderWrong = RealmBuilder(databaseName: testDatabaseNameTwo, bundle: testBundle, passphrase: "")
        XCTAssertThrowsError(try DatabaseFactory.initialize(databaseBuilderWrong) as RealmAPI)
    }

    func test_02_ModelObject_01_Create() {
        let newObject: Person? = databaseAPI.create()
        XCTAssertNotNil(newObject, "Fail to create Person object")
    }
    
    func test_02_ModelObject_02_CreateAndUpdate() {
        let newObject: Person? = databaseAPI.create()
        XCTAssertTrue(databaseAPI.update(newObject!))
    }
    
    func test_02_ModelObject_03_Create_Multi() {
        let objectOne: Person = databaseAPI.create()!
        let objectTwo: Person = databaseAPI.create()!
        
        XCTAssertNotEqual(objectOne, objectTwo, "The two objects are the same one")
    }
    
    func test_03_ModelObject_01_Read() {
        let objectOne: Person = databaseAPI.create()!
        let objectTwo: Person = databaseAPI.create()!
        _ = databaseAPI.update(objectOne)
        _ = databaseAPI.update(objectTwo)
        
        let recoveredObjects: [Person]? = databaseAPI.recover()
        XCTAssertNotNil(recoveredObjects)
        XCTAssertEqual(recoveredObjects!.count, 2, "Doesn't have the two objects")
    }
    
    func test_03_ModelObject_02_Read_Specific() {
        let objectToFind: Person = databaseAPI.create()!
        let objectId = "objectId"
        objectToFind.id = objectId
        
        let objectTwo: Person = databaseAPI.create()!
        _ = databaseAPI.update(objectToFind)
        _ = databaseAPI.update(objectTwo)
        
        let recoveredObjects: [Person]? = databaseAPI.recover(key: "id", value: objectId)
        XCTAssertNotNil(recoveredObjects)
        XCTAssertEqual(recoveredObjects!.count, 1, "Doesn't have the object")
        XCTAssertEqual(recoveredObjects![0].id, objectId, "Not the same object")
    }
    
    func test_04_ModelObject_01_Delete() {
        let objectToDelete: Person = databaseAPI.create()!
        let objectId = "objectId"
        objectToDelete.id = objectId
        
        let objectTwo: Person = databaseAPI.create()!
        _ = databaseAPI.update(objectToDelete)
        _ = databaseAPI.update(objectTwo)

        let recoveredObjects: [Person]? = databaseAPI.recover()
        XCTAssertNotNil(recoveredObjects)
        XCTAssertEqual(recoveredObjects!.count, 2, "Doesn't have the two objects")

        let result = databaseAPI.delete(objectToDelete)
        XCTAssertTrue(result)

        let newRecoveredObjects: [Person]? = databaseAPI.recover()
        XCTAssertNotNil(newRecoveredObjects)
        XCTAssertEqual(newRecoveredObjects!.count, 1, "Should have only one object")
    }
    
    func test_000_Migration_DifferentScenarios() {
        let databaseBuilder = RealmBuilder(databaseName: testDatabaseNameMigration, bundle: testBundle, passphrase: testDatabasePassphrase, schemaVersion: lastSchemaVersion, migrationBlock: { migration, oldSchemaVersion in
            if (oldSchemaVersion < 1 && self.lastSchemaVersion >= 1) {
                print("Automatic migration")
                // Nothing to do!
                // Realm will automatically detect new properties and removed properties
                // And will update the schema on disk automatically
            }
            
            if (oldSchemaVersion < 2 && self.lastSchemaVersion >= 2) {
                // The enumerateObjects(ofType:_:) method iterates
                // over every Person object stored in the Realm file
                migration.enumerateObjects(ofType: Person.className()) { oldObject, newObject in
                    // combine name fields into a single field
                    let firstName = oldObject!["firstName"] as! String
                    let lastName = oldObject!["lastName"] as! String
                    newObject!["fullName"] = "\(firstName) + \(lastName)"
                }
            }
            
            if (oldSchemaVersion < 3 && self.lastSchemaVersion >= 3) {
                // The renaming operation should be done outside of calls to `enumerateObjects(ofType: _:)`.
                migration.renameProperty(onType: Person.className(), from: "age", to: "yearsSinceBirth")
            }
        })
        
        let databaseAPI = try! DatabaseFactory.initialize(databaseBuilder) as RealmAPI
        XCTAssertNotNil(databaseAPI)
        XCTAssertNotNil(databaseAPI.databaseContext)
        XCTAssertNotNil(databaseAPI.realmInstance)
    }
    
    func test99_Performance() {
        self.measure {
            self.test_01_Initialize_01_Single()
            self.test_01_Initialize_02_Multi()
            self.test_01_Initialize_03_Repeated()
            self.test_02_ModelObject_01_Create()
            self.test_02_ModelObject_02_CreateAndUpdate()
            self.test_02_ModelObject_03_Create_Multi()
        }
    }
}



////Person V0
//class Person: Object {
//    @objc dynamic var id = ""
//    @objc dynamic var firstName = ""
//    @objc dynamic var lastName = ""
//}

//To Test the migration methods, comment the above Person class, uncomment this one and raise `lastSchemaVersion` property
//Person V1
//class Person: Object {
//    @objc dynamic var id = ""
//    @objc dynamic var firstName = "" //No changes
//    @objc dynamic var lastName = "" //No changes
//    @objc dynamic var age = 0 //New property
//}

//To Test the migration methods, comment the above Person class, uncomment this one and raise `lastSchemaVersion` property
//Person V2
class Person: Object {
    @objc dynamic var id = ""
    @objc dynamic var fullName = "" //Removed firstName, lastName and added fullName
    @objc dynamic var age = 0 //No changes
}

//To Test the migration methods, comment the above Person class, uncomment this one and raise `lastSchemaVersion` property
//Person V3
//class Person: Object {
//    @objc dynamic var id = ""
//    @objc dynamic var fullName = "" //No changes
//    @objc dynamic var yearsSinceBirth = 0 //Rename age to yearsSinceBirth
//}
//

