//
//  CoreDataPersistenceFrameworkTests.swift
//  PersistenceFrameworkTests
//
//  Created by Cristian on 13/03/2018.
//  Copyright © 2018 Cristian Barril. All rights reserved.
//

import XCTest
import CoreData
@testable import PersistenceFramework

class CoreDataManagerTests: XCTestCase {
    
    private let testBundle = Bundle(for: CoreDataManagerTests.self)
    private let testDatabaseName = "testCoreDataDatabase"
    private let testDatabaseNameTwo = "testCoreDataDatabaseTwo"
    private var testModelURL: URL!
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        testModelURL = testBundle.url(forResource: "TestModel", withExtension:"momd")
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        try? CoreDataManager_deleteAllCoreData()
        super.tearDown()
    }
    
    func test_01_Initialize_Single() {
        XCTAssertNoThrow(try CoreDataManagerInit(databaseName: testDatabaseName, bundle: testBundle, modelURL: testModelURL))
    }
    
    func test_01_Initialize_Multi() {
        XCTAssertNoThrow(try CoreDataManagerInit(databaseName: testDatabaseName, bundle: testBundle, modelURL: testModelURL))
        XCTAssertNoThrow(try CoreDataManagerInit(databaseName: testDatabaseNameTwo, bundle: testBundle, modelURL: testModelURL))
    }
    
    func test_01_Initialize_Repeated() {
        XCTAssertNoThrow(try CoreDataManagerInit(databaseName: testDatabaseName, bundle: testBundle, modelURL: testModelURL))
        XCTAssertThrowsError(try CoreDataManagerInit(databaseName: testDatabaseName, bundle: testBundle, modelURL: testModelURL)) { (error) -> Void in
            XCTAssertNotNil(error)
        }
    }
    
    func test_02_GetContext() {
        do {
            try CoreDataManagerInit(databaseName: testDatabaseName, bundle: testBundle, modelURL: testModelURL)
        } catch {
            XCTFail()
        }
        
        let coreDataContext = CoreDataManager_getContext(databaseName: testDatabaseName, forBundle: testBundle)
        XCTAssertNotNil(coreDataContext, "It's nil")
        
        let coreDataContextTwo = CoreDataManager_getContext(databaseName: testDatabaseNameTwo, forBundle: testBundle)
        XCTAssertNil(coreDataContextTwo, "It's not nil")
    }
    
    func test_03_ModelObject_01_Create() {
        do {
            try CoreDataManagerInit(databaseName: testDatabaseName, bundle: testBundle, modelURL: testModelURL)
        } catch {
            XCTFail()
        }
        
        if let context = CoreDataManager_getContext(databaseName: testDatabaseName, forBundle: testBundle) {
            let testEntityData: TestEntity = NSEntityDescription.insertNewObject(forEntityName: "TestEntity", into: context) as! TestEntity
            XCTAssertNotNil(testEntityData, "It's nil")
        }
        else {
            XCTFail()
        }
    }
    
    func test_03_ModelObject_02_Read() {
        do {
            try CoreDataManagerInit(databaseName: testDatabaseName, bundle: testBundle, modelURL: testModelURL)
        } catch  {
            XCTFail()
        }
        
        if let context = CoreDataManager_getContext(databaseName: testDatabaseName, forBundle: testBundle) {
            let testEntityData: TestEntity = NSEntityDescription.insertNewObject(forEntityName: "TestEntity", into: context) as! TestEntity
            let dataText = "Recovered"
            testEntityData.testAttribute = dataText
            
            do {
                try CoreDataManager_saveContext(databaseName: testDatabaseName, forBundle: testBundle)
            } catch {
                XCTFail()
            }
            
            let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: "TestEntity")
            
            do {
                let fetchedResult = try context.fetch(fetch) as! [TestEntity]
                XCTAssertEqual(fetchedResult.count, 1, "No data recovered")
                XCTAssertEqual(fetchedResult[0].testAttribute, dataText, "Data don't match")
            } catch {
                XCTFail()
            }
        }
        else {
            XCTFail()
        }
    }
    
    func test_03_ModelObject_03_Update() {
        do {
            try CoreDataManagerInit(databaseName: testDatabaseName, bundle: testBundle, modelURL: testModelURL)
        } catch  {
            XCTFail()
        }
        
        if let context = CoreDataManager_getContext(databaseName: testDatabaseName, forBundle: testBundle) {
            let testEntityData: TestEntity = NSEntityDescription.insertNewObject(forEntityName: "TestEntity", into: context) as! TestEntity
            let dataText = "Test"
            testEntityData.testAttribute = dataText
            
            do {
                try CoreDataManager_saveContext(databaseName: testDatabaseName, forBundle: testBundle)
                let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: "TestEntity")
                
                do {
                    let fetchedResult = try context.fetch(fetch) as! [TestEntity]
                    XCTAssertEqual(fetchedResult[0].testAttribute, dataText, "Property testAttribute doesn´t match")
                    let newValue = "newValue"
                    testEntityData.testAttribute = newValue
                    
                    do {
                        try CoreDataManager_saveContext(databaseName: testDatabaseName, forBundle: testBundle)
                        XCTAssertEqual(fetchedResult[0].testAttribute, newValue, "Property testAttribute doesn´t match")
                    } catch {
                        XCTFail()
                    }
                } catch {
                    XCTFail()
                }
            } catch {
                XCTFail()
            }
        }
        else {
            XCTFail()
        }
    }
    
    func test_03_ModelObject_04_Delete() {
        do {
            try CoreDataManagerInit(databaseName: testDatabaseName, bundle: testBundle, modelURL: testModelURL)
        } catch  {
            XCTFail()
        }
        
        if let context = CoreDataManager_getContext(databaseName: testDatabaseName, forBundle: testBundle) {
            let testEntityData: TestEntity = NSEntityDescription.insertNewObject(forEntityName: "TestEntity", into: context) as! TestEntity
            let dataText = "Test"
            testEntityData.testAttribute = dataText
            
            do {
                try CoreDataManager_saveContext(databaseName: testDatabaseName, forBundle: testBundle)
            } catch {
                XCTFail()
            }
            
            context.delete(testEntityData)

            do {
                try CoreDataManager_saveContext(databaseName: testDatabaseName, forBundle: testBundle)
                let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: "TestEntity")
                
                do {
                    let fetchedResult = try context.fetch(fetch) as! [TestEntity]
                    XCTAssertEqual(fetchedResult.count, 0, "Entity not deleted")
                } catch {
                    XCTFail()
                }
            } catch {
                XCTFail()
            }
        }
        else {
            XCTFail()
        }
    }
    
    func test_04_SaveContext_OK() {
        do {
            try CoreDataManagerInit(databaseName: testDatabaseName, bundle: testBundle, modelURL: testModelURL)
        } catch  {
            XCTFail()
        }
        
        if let context = CoreDataManager_getContext(databaseName: testDatabaseName, forBundle: testBundle) {
            let testEntityData: TestEntity = NSEntityDescription.insertNewObject(forEntityName: "TestEntity", into: context) as! TestEntity
            let dataText = "Test"
            testEntityData.testAttribute = dataText
            
            XCTAssertNoThrow(try CoreDataManager_saveContext(databaseName: testDatabaseName, forBundle: testBundle))
        }
        else {
            XCTFail()
        }
    }
    
    func test_04_SaveContext_KO() {
        XCTAssertThrowsError(try CoreDataManager_saveContext(databaseName: testDatabaseName, forBundle: testBundle)) { (error) -> Void in
            XCTAssertNotNil(error)
        }
    }
    
    func test_05_CleanUpCache_Single() {
        do {
            try CoreDataManagerInit(databaseName: testDatabaseName, bundle: testBundle, modelURL: testModelURL)
            try CoreDataManagerInit(databaseName: testDatabaseNameTwo, bundle: testBundle, modelURL: testModelURL)
        } catch  {
            XCTFail()
        }
        
        CoreDataManager_cleanUp(databaseName: testDatabaseName, forBundle: testBundle)
        let coreDataContext = CoreDataManager_getContext(databaseName: testDatabaseName, forBundle: testBundle)
        XCTAssertNil(coreDataContext, "It's not nil")
        
        let coreDataContextTwo = CoreDataManager_getContext(databaseName: testDatabaseNameTwo, forBundle: testBundle)
        XCTAssertNotNil(coreDataContextTwo, "It's nil")
    }
    
    func test_05_CleanUpCache_All() {
        do {
            try CoreDataManagerInit(databaseName: testDatabaseName, bundle: testBundle, modelURL: testModelURL)
            try CoreDataManagerInit(databaseName: testDatabaseNameTwo, bundle: testBundle, modelURL: testModelURL)
        } catch  {
            XCTFail()
        }
        
        CoreDataManager_cleanUpAll()
        let coreDataContext = CoreDataManager_getContext(databaseName: testDatabaseName, forBundle: testBundle)
        XCTAssertNil(coreDataContext, "It's not nil")
        
        let coreDataContextTwo = CoreDataManager_getContext(databaseName: testDatabaseNameTwo, forBundle: testBundle)
        XCTAssertNil(coreDataContextTwo, "It's not nil")
    }
    
    func test_06_DeleteAll() {
        do {
            try CoreDataManagerInit(databaseName: testDatabaseName, bundle: testBundle, modelURL: testModelURL)
        } catch  {
            XCTFail()
        }
        
        let databaseKey = DatabaseHelper.getDatabaseKey(databaseName: testDatabaseName, bundle: testBundle)
        let urlFile = URL.applicationDocumentsDirectory().appendingPathComponent(databaseKey)
        XCTAssertTrue(FileManager.default.fileExists(atPath: urlFile.path), "CoreData file not exist")
        
        XCTAssertNoThrow(try CoreDataManager_deleteAllCoreData())
        XCTAssertFalse(FileManager.default.fileExists(atPath: urlFile.path), "CoreData file exist")
    }
    
    func test_99_Performance() {
        self.measure {
            
        }
    }
}
