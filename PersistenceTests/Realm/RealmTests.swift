//
//  RealmTests.swift
//  PersistenceTests
//
//  Created by Cristian on 06/03/2018.
//  Copyright © 2018 Cristian Barril. All rights reserved.
//

import XCTest
import RealmSwift
@testable import Persistence

class RealmTests: XCTestCase {

    private let testDatabaseName = "testRealmDatabase"
    private let testDatabaseNameTwo = "testRealmDatabaseTwo"
    private let testDatabaseNameMigration = "testDatabaseNameMigration"
    private let testDatabasePassphrase = "passphrase"
    private let lastSchemaVersion: UInt64 = 0
    private var database: RealmManager!
    private var isMigrationInProgress: Bool {
        get {
            return self.lastSchemaVersion > 0
        }
    }
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        if !isMigrationInProgress {
            let databaseBuilder = RealmBuilder(databaseName: testDatabaseName, passphrase: testDatabasePassphrase)
            database = try! databaseBuilder.create()
        }
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        
        if !isMigrationInProgress {
            try? RealmImplementation.sharedInstance.deleteAllRealm()
            RealmImplementation.sharedInstance.cleanUpAll()
        }
        super.tearDown()
    }

    func test_01_Create_01_Single() {
        XCTAssertNotNil(database)
        XCTAssertNotNil(database.context)
    }
    
    func test_01_Create_02_Multi() {
        let databaseBuilder = RealmBuilder(databaseName: testDatabaseNameTwo, passphrase: testDatabasePassphrase)
        let databaseAPITwo = try! databaseBuilder.create() as RealmManager
        
        XCTAssertNotNil(database)
        XCTAssertNotNil(database.context)
        
        XCTAssertNotNil(databaseAPITwo)
        XCTAssertNotNil(databaseAPITwo.context)
        
        XCTAssertNotEqual(databaseAPITwo.context, database.context, "Context are equals")
    }
    
    func test_01_Create_03_Repeated() {
        let databaseBuilder = RealmBuilder(databaseName: testDatabaseName, passphrase: testDatabasePassphrase)
        let databaseAPITwo = try! databaseBuilder.create() as RealmManager
        
        XCTAssertNotNil(databaseAPITwo)
        XCTAssertNotNil(databaseAPITwo.context)
        XCTAssertEqual(databaseAPITwo.context, database.context, "Context aren't equals")
    }
    
    func test_01_Create_04_KO() {
        let databaseBuilderWrong = RealmBuilder(databaseName: testDatabaseNameTwo, passphrase: "")
        XCTAssertThrowsError(try databaseBuilderWrong.create() as RealmManager)
    }

    func test_02_ModelObject_01_Create() {
        let newObject: User? = database.create()
        XCTAssertNotNil(newObject, "Fail to create User object")
    }
    
    func test_02_ModelObject_02_CreateAndUpdate() {
        let newObject: User? = database.create()
        XCTAssertTrue(database.update(newObject!))
    }
    
    func test_02_ModelObject_03_Create_Multi() {
        let objectOne: User = database.create()!
        let objectTwo: User = database.create()!
        
        XCTAssertNotEqual(objectOne, objectTwo, "The two objects are the same one")
    }
    
    func test_03_ModelObject_01_Read() {
        let objectOne: User = database.create()!
        let objectTwo: User = database.create()!
        _ = database.update(objectOne)
        _ = database.update(objectTwo)
        
        let recoveredObjects: [User]? = database.recover()
        XCTAssertNotNil(recoveredObjects)
        XCTAssertEqual(recoveredObjects!.count, 2, "Doesn't have the two objects")
    }
    
    func test_03_ModelObject_02_Read_Specific() {
        let objectToFind: User = database.create()!
        let objectId = "objectId"
        objectToFind.id = objectId
        
        let objectTwo: User = database.create()!
        _ = database.update(objectToFind)
        _ = database.update(objectTwo)
        
        let recoveredObjects: [User]? = database.recover(key: "id", value: objectId)
        XCTAssertNotNil(recoveredObjects)
        XCTAssertEqual(recoveredObjects!.count, 1, "Doesn't have the object")
        XCTAssertEqual(recoveredObjects![0].id, objectId, "Not the same object")
    }
    
    func test_04_ModelObject_01_Delete() {
        let objectToDelete: User = database.create()!
        let objectId = "objectId"
        objectToDelete.id = objectId
        
        let objectTwo: User = database.create()!
        _ = database.update(objectToDelete)
        _ = database.update(objectTwo)

        let recoveredObjects: [User]? = database.recover()
        XCTAssertNotNil(recoveredObjects)
        XCTAssertEqual(recoveredObjects!.count, 2, "Doesn't have the two objects")

        let result = database.delete(objectToDelete)
        XCTAssertTrue(result)

        let newRecoveredObjects: [User]? = database.recover()
        XCTAssertNotNil(newRecoveredObjects)
        XCTAssertEqual(newRecoveredObjects!.count, 1, "Should have only one object")
    }
    
    func test_05_RecoverContext() {
        XCTAssertNotNil(database.getContext())
    }
        
    func test_000_Migration_DifferentScenarios() {
        let databaseBuilder = RealmBuilder(databaseName: testDatabaseNameMigration, passphrase: testDatabasePassphrase, schemaVersion: lastSchemaVersion, migrationBlock: { migration, oldSchemaVersion in
            if (oldSchemaVersion < 1 && self.lastSchemaVersion >= 1) {
                print("Automatic migration")
                // Nothing to do!
                // Realm will automatically detect new properties and removed properties
                // And will update the schema on disk automatically
            }
            
            if (oldSchemaVersion < 2 && self.lastSchemaVersion >= 2) {
                // The enumerateObjects(ofType:_:) method iterates
                // over every User object stored in the Realm file
                migration.enumerateObjects(ofType: User.className()) { oldObject, newObject in
                    // combine name fields into a single field
                    let firstName = oldObject!["firstName"] as! String
                    let lastName = oldObject!["lastName"] as! String
                    newObject!["fullName"] = "\(firstName) + \(lastName)"
                }
            }
            
            if (oldSchemaVersion < 3 && self.lastSchemaVersion >= 3) {
                // The renaming operation should be done outside of calls to `enumerateObjects(ofType: _:)`.
                migration.renameProperty(onType: User.className(), from: "age", to: "yearsSinceBirth")
            }
        })
        
        let databaseAPI = try! databaseBuilder.create() as RealmManager
        XCTAssertNotNil(databaseAPI)
        XCTAssertNotNil(databaseAPI.context)
    }
    
    func test99_Performance() {
        self.measure {
            self.test_01_Create_01_Single()
            self.test_01_Create_02_Multi()
            self.test_01_Create_03_Repeated()
            self.test_02_ModelObject_01_Create()
            self.test_02_ModelObject_02_CreateAndUpdate()
            self.test_02_ModelObject_03_Create_Multi()
        }
    }
}



////User V0
//class User: Object {
//    @objc dynamic var id = ""
//    @objc dynamic var firstName = ""
//    @objc dynamic var lastName = ""
//}

//To Test the migration methods, comment the above User class, uncomment this one and raise `lastSchemaVersion` property
//User V1
//class User: Object {
//    @objc dynamic var id = ""
//    @objc dynamic var firstName = "" //No changes
//    @objc dynamic var lastName = "" //No changes
//    @objc dynamic var age = 0 //New property
//}

//To Test the migration methods, comment the above User class, uncomment this one and raise `lastSchemaVersion` property
//User V2
class User: Object {
    @objc dynamic var id = ""
    @objc dynamic var fullName = "" //Removed firstName, lastName and added fullName
    @objc dynamic var age = 0 //No changes
}

//To Test the migration methods, comment the above User class, uncomment this one and raise `lastSchemaVersion` property
//User V3
//class User: Object {
//    @objc dynamic var id = ""
//    @objc dynamic var fullName = "" //No changes
//    @objc dynamic var yearsSinceBirth = 0 //Rename age to yearsSinceBirth
//}
//

