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

class PersistenceFrameworkTests: XCTestCase {
    
    private let testBundle = Bundle(for: PersistenceFrameworkTests.self)
    private let testDatabaseName = "testDatabase"
    private let testDatabasePassphrase = "passphrase"
//    private var realmClass: RealmManager!
    private let lastSchemaVersion: UInt64 = 0
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        RealmManager_deleteAllRealm()
        super.tearDown()
    }
    
    func test_01_Initialize_OK() {
        XCTAssertNoThrow(try RealmManagerInit(databaseName: testDatabaseName, bundle: testBundle, passphrase: testDatabasePassphrase))
    }
    
    func test_01_Initialize_KO_01_No_DatabaseName() {
        XCTAssertThrowsError(try RealmManager.initialize(databaseKey: "", passphrase: testDatabasePassphrase, schemaVersion: lastSchemaVersion, migrationBlock: nil)) { (error) -> Void in
            XCTAssertNotNil(error)
        }
    }
    
    func test_01_Initialize_KO_02_No_DatabasePassphrase() {
        XCTAssertThrowsError(try RealmManagerInit(databaseName: testDatabaseName, bundle: testBundle, passphrase: "")) { (error) -> Void in
            XCTAssertNotNil(error)
        }
    }
    
    func test_02_checkStack() {
        let retStack = RealmManager_currentStack(databaseName: testDatabaseName, forBundle: testBundle)
        XCTAssertNotNil(retStack, "It's nil")
        print(retStack)
    }
    
    func test_03_getRealmContext() {
        do {
            try RealmManagerInit(databaseName: testDatabaseName, bundle: testBundle, passphrase: testDatabasePassphrase)
        } catch  {
            XCTFail()
        }
        
        let realmsInstance = RealmManager_getRealm(databaseName: testDatabaseName, forBundle: testBundle)
        XCTAssertNotNil(realmsInstance, "It's nil")
    }
    
    func test_04_Migration_DifferentScenarios() {
        
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
    
    func test_05_ModelObject_01_CreateObject() {
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
    
    func test_05_ModelObject_02_ReadObject() {
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
    
    func test_05_ModelObject_03_UpdateObject() {
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
    
    func test_05_ModelObject_04_DeleteObject() {
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
    
    func test_06_Delete_01_CleanUp_01() {
        do {
            try RealmManagerInit(databaseName: testDatabaseName, bundle: testBundle, passphrase: testDatabasePassphrase)
        } catch  {
            XCTFail()
        }
        RealmManager_cleanUp(databaseName: testDatabaseName, forBundle: testBundle)
        let realmContext = RealmManager_getRealm(databaseName: testDatabaseName, forBundle: testBundle)
        XCTAssertNil(realmContext, "It's not nil")
    }
    
    func test_06_Delete_01_CleanUp_02() {
        do {
            try RealmManagerInit(databaseName: testDatabaseName, bundle: testBundle, passphrase: testDatabasePassphrase)
        } catch  {
            XCTFail()
        }
        RealmManager_cleanUp(databaseName: testDatabaseName, forBundle: testBundle)
        let realmContext = RealmManager_getRealm(databaseName: testDatabaseName, forBundle: testBundle)
        XCTAssertNil(realmContext, "It's not nil")
    }
    
    func test_06_Delete_02_All() {
        do {
            try RealmManagerInit(databaseName: testDatabaseName, bundle: testBundle, passphrase: testDatabasePassphrase)
        } catch  {
            XCTFail()
        }
        
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = urls[urls.count-1]
        
        let realmFile = documentsDirectory.appendingPathComponent(getDatabaseKey(databaseName: testDatabaseName, bundle: testBundle) + ".realm")
        XCTAssertTrue(FileManager.default.fileExists(atPath: realmFile.path), "Realm file not exist")
        
        RealmManager_deleteAllRealm()
        let realmFileDeleted = documentsDirectory.appendingPathComponent(getDatabaseKey(databaseName: testDatabaseName, bundle: testBundle) + ".realm")
        XCTAssertFalse(FileManager.default.fileExists(atPath: realmFileDeleted.path), "Realm file exist")
    }
    
    func test99_Performance() {
        
        self.measure {
            test_01_Initialize_OK()
            test_01_Initialize_KO_01_No_DatabaseName()
            test_01_Initialize_KO_02_No_DatabasePassphrase()
            test_02_checkStack()
            test_03_getRealmContext()
            test_04_Migration_DifferentScenarios()
            test_05_ModelObject_01_CreateObject()
            test_05_ModelObject_02_ReadObject()
            test_05_ModelObject_03_UpdateObject()
            test_05_ModelObject_04_DeleteObject()
            test_06_Delete_01_CleanUp_01()
            test_06_Delete_01_CleanUp_02()
            test_06_Delete_02_All()
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
