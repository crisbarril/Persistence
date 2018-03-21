//
//  PersistenceFrameworkTests.swift
//  PersistenceFrameworkTests
//
//  Created by Cristian on 06/03/2018.
//  Copyright © 2018 Cristian Barril. All rights reserved.
//

import XCTest
import RealmSwift
@testable import PersistenceFramework

class RealmManagerTests: XCTestCase {
    
    private let testBundle = Bundle(for: RealmManagerTests.self)
    private let testDatabaseName = "testRealmDatabase"
    private let testDatabaseNameTwo = "testRealmDatabaseTwo"
    private let testDatabasePassphrase = "passphrase"
    private let lastSchemaVersion: UInt64 = 0
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        try? RealmManager_deleteAllRealm()
        super.tearDown()
    }
    
    func test_01_Initialize_Single() {
        XCTAssertNoThrow(try RealmManagerInit(databaseName: testDatabaseName, bundle: testBundle, passphrase: testDatabasePassphrase))
    }
    
    func test_01_Initialize_Multi() {
        XCTAssertNoThrow(try RealmManagerInit(databaseName: testDatabaseName, bundle: testBundle, passphrase: testDatabasePassphrase))
        XCTAssertNoThrow(try RealmManagerInit(databaseName: testDatabaseNameTwo, bundle: testBundle, passphrase: testDatabasePassphrase))
    }
    
    func test_01_Initialize_Repeated() {
        XCTAssertNoThrow(try RealmManagerInit(databaseName: testDatabaseName, bundle: testBundle, passphrase: testDatabasePassphrase))
        XCTAssertThrowsError(try RealmManagerInit(databaseName: testDatabaseName, bundle: testBundle, passphrase: testDatabasePassphrase)) { (error) -> Void in
            XCTAssertNotNil(error)
        }
    }
    
    func test_02_GetRealmContext() {
        do {
            try RealmManagerInit(databaseName: testDatabaseName, bundle: testBundle, passphrase: testDatabasePassphrase)
        } catch  {
            XCTFail()
        }
        
        let realmsInstance = RealmManager_getRealm(databaseName: testDatabaseName, forBundle: testBundle)
        XCTAssertNotNil(realmsInstance, "It's nil")
        
        let realmsInstanceTwo = RealmManager_getRealm(databaseName: testDatabaseNameTwo, forBundle: testBundle)
        XCTAssertNil(realmsInstanceTwo, "It's not nil")
    }
    
    func test_03_Migration_DifferentScenarios() {
        do {
            try RealmManagerInit(databaseName: testDatabaseName, bundle: testBundle, passphrase: testDatabasePassphrase, schemaVersion: lastSchemaVersion, migrationBlock: { migration, oldSchemaVersion in
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
        } catch  {
            XCTFail()
        }
        
        let realmContext = RealmManager_getRealm(databaseName: testDatabaseName, forBundle: testBundle)
        XCTAssertNotNil(realmContext, "It's nil")
    }
    
    func test_04_ModelObject_01_Create() {
        do {
            try RealmManagerInit(databaseName: testDatabaseName, bundle: testBundle, passphrase: testDatabasePassphrase)
        } catch  {
            XCTFail()
        }
        if let realmContext = RealmManager_getRealm(databaseName: testDatabaseName, forBundle: testBundle) {
            let person = Person()
            
            XCTAssertNoThrow(try realmContext.write {
                realmContext.add(person)
                })
        } else {
            XCTFail()
        }
    }
    
    func test_04_ModelObject_02_Read() {
        do {
            try RealmManagerInit(databaseName: testDatabaseName, bundle: testBundle, passphrase: testDatabasePassphrase)
        } catch  {
            XCTFail()
        }
        if let realmContext = RealmManager_getRealm(databaseName: testDatabaseName, forBundle: testBundle) {
            let person = Person()
            person.id = "test"
            
            try! realmContext.write {
                realmContext.add(person)
            }
            
            let persistedObjects = realmContext.objects(Person.self).filter("id == 'test'")
            XCTAssertFalse(persistedObjects.isEmpty, "Couldn't find object in Realm")
        } else {
            XCTFail()
        }
    }
    
    func test_04_ModelObject_03_Update() {
        do {
            try RealmManagerInit(databaseName: testDatabaseName, bundle: testBundle, passphrase: testDatabasePassphrase)
        } catch  {
            XCTFail()
        }
        if let realmContext = RealmManager_getRealm(databaseName: testDatabaseName, forBundle: testBundle) {
            let person = Person()
            person.id = "test"
            
            try! realmContext.write {
                realmContext.add(person)
            }
            
            XCTAssertNoThrow(try realmContext.write {
                person.id = "Another value"
                })
        } else {
            XCTFail()
        }
    }
    
    func test_04_ModelObject_04_Delete() {
        do {
            try RealmManagerInit(databaseName: testDatabaseName, bundle: testBundle, passphrase: testDatabasePassphrase)
        } catch  {
            XCTFail()
        }
        if let realmContext = RealmManager_getRealm(databaseName: testDatabaseName, forBundle: testBundle) {
            let person = Person()
            person.id = "test"
            
            try! realmContext.write {
                realmContext.add(person)
            }
            
            XCTAssertNoThrow(try realmContext.write {
                realmContext.delete(person)
                })
        } else {
            XCTFail()
        }
    }
    
    func test_05_CleanUpCache_Single() {
        do {
            try RealmManagerInit(databaseName: testDatabaseName, bundle: testBundle, passphrase: testDatabasePassphrase)
            try RealmManagerInit(databaseName: testDatabaseNameTwo, bundle: testBundle, passphrase: testDatabasePassphrase)
        } catch  {
            XCTFail()
        }
        RealmManager_cleanUp(databaseName: testDatabaseName, forBundle: testBundle)
        let realmContext = RealmManager_getRealm(databaseName: testDatabaseName, forBundle: testBundle)
        XCTAssertNil(realmContext, "It's not nil")
        
        let realmContextTwo = RealmManager_getRealm(databaseName: testDatabaseNameTwo, forBundle: testBundle)
        XCTAssertNotNil(realmContextTwo, "It's nil")
    }
    
    func test_05_CleanUpCache_All() {
        do {
            try RealmManagerInit(databaseName: testDatabaseName, bundle: testBundle, passphrase: testDatabasePassphrase)
            try RealmManagerInit(databaseName: testDatabaseNameTwo, bundle: testBundle, passphrase: testDatabasePassphrase)
        } catch  {
            XCTFail()
        }
        RealmManager_cleanUpAll()
        let realmContext = RealmManager_getRealm(databaseName: testDatabaseName, forBundle: testBundle)
        XCTAssertNil(realmContext, "It's not nil")
        
        let realmContextTwo = RealmManager_getRealm(databaseName: testDatabaseNameTwo, forBundle: testBundle)
        XCTAssertNil(realmContextTwo, "It's not nil")
    }
    
    func test_06_DeleteAll() {
        do {
            try RealmManagerInit(databaseName: testDatabaseName, bundle: testBundle, passphrase: testDatabasePassphrase)
        } catch  {
            XCTFail()
        }
        
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = urls[urls.count-1]
        
        let realmFile = documentsDirectory.appendingPathComponent(DatabaseHelper.getDatabaseKey(databaseName: testDatabaseName, bundle: testBundle) + ".realm")
        XCTAssertTrue(FileManager.default.fileExists(atPath: realmFile.path), "Realm file not exist")
        
        XCTAssertNoThrow(try RealmManager_deleteAllRealm())
        let realmFileDeleted = documentsDirectory.appendingPathComponent(DatabaseHelper.getDatabaseKey(databaseName: testDatabaseName, bundle: testBundle) + ".realm")
        XCTAssertFalse(FileManager.default.fileExists(atPath: realmFileDeleted.path), "Realm file exist")
    }
    
    func test99_Performance() {
        self.measure {
            
        }
    }
}

//Person V0
class Person: Object {
    @objc dynamic var id = ""
    @objc dynamic var firstName = ""
    @objc dynamic var lastName = ""
}

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
//class Person: Object {
//    @objc dynamic var id = ""
//    @objc dynamic var fullName = "" //Removed firstName, lastName and added fullName
//    @objc dynamic var age = 0 //No changes
//}

//To Test the migration methods, comment the above Person class, uncomment this one and raise `lastSchemaVersion` property
//Person V3
//class Person: Object {
//    @objc dynamic var id = ""
//    @objc dynamic var fullName = "" //No changes
//    @objc dynamic var yearsSinceBirth = 0 //Rename age to yearsSinceBirth
//}
//
