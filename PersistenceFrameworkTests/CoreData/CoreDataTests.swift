//
//  CoreDataTests.swift
//  PersistenceFrameworkTests
//
//  Created by Cristian on 13/03/2018.
//  Copyright © 2018 Cristian Barril. All rights reserved.
//

import XCTest
import CoreData
@testable import PersistenceFramework

class CoreDataTests: XCTestCase {
    
    private let testBundle = Bundle(for: CoreDataTests.self)
    private let testDatabaseName = "testCoreDataDatabase"
    private let testDatabaseNameTwo = "testCoreDataDatabaseTwo"
    private var database: CoreDataManager!
    private var testModelURL: URL!
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        testModelURL = testBundle.url(forResource: "TestModel", withExtension:"momd")
        let databaseBuilder = CoreDataBuilder(databaseName: testDatabaseName, bundle: testBundle, modelURL: testModelURL)
        database = try! databaseBuilder.create() as CoreDataManager
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        try? CoreDataImplementation.sharedInstance.deleteAllCoreData()
        CoreDataImplementation.sharedInstance.cleanUpAll()
        super.tearDown()
    }
    
    func test_01_Create_01_Single() {
        XCTAssertNotNil(database)
        XCTAssertNotNil(database.context)
    }
    
    func test_01_Create_02_Multi() {
        let databaseBuilder = CoreDataBuilder(databaseName: testDatabaseNameTwo, bundle: testBundle, modelURL: testModelURL)
        let databaseTwo = try! databaseBuilder.create() as CoreDataManager
        
        XCTAssertNotNil(database)
        XCTAssertNotNil(database.context)
        
        XCTAssertNotNil(databaseTwo)
        XCTAssertNotNil(databaseTwo.context)
        
        XCTAssertNotEqual(databaseTwo.context, database.context, "Context are equals")
    }

    func test_01_Create_03_Repeated() {
        let databaseBuilder = CoreDataBuilder(databaseName: testDatabaseName, bundle: testBundle, modelURL: testModelURL)
        let databaseTwo = try! databaseBuilder.create() as CoreDataManager
        
        XCTAssertNotNil(databaseTwo)
        XCTAssertNotNil(databaseTwo.context)
        XCTAssertEqual(databaseTwo.context, database.context, "Context aren't equals")
    }
    
    func test_01_Create_04_KO() {
        let testModelURLWrong = DatabaseHelper.getStoreUrl("TestModelWrong.momd")
        let databaseBuilderWrong = CoreDataBuilder(databaseName: testDatabaseNameTwo, bundle: testBundle, modelURL: testModelURLWrong)
        XCTAssertThrowsError(try databaseBuilderWrong.create() as CoreDataManager)
    }
    
    func test_02_ModelObject_01_Create() {
        let newObject: TestEntity? = database.create()
        XCTAssertNotNil(newObject, "Fail to create TestEntity object")
    }
    
    func test_02_ModelObject_02_CreateAndSave() {
        _ = database.create() as TestEntity?
        XCTAssertNoThrow(try database.save())
    }
    
    func test_02_ModelObject_03_Create_Multi() {
        let objectOne: TestEntity = database.create()!
        let objectTwo: TestEntity = database.create()!
        
        XCTAssertNotEqual(objectOne, objectTwo, "The two objects are the same one")
    }

    func test_03_ModelObject_01_Read() {
        _ = database.create() as TestEntity?
        _ = database.create() as TestEntity?
        try! database.save()
        
        let recoveredObjects: [TestEntity]? = database.recover()
        XCTAssertNotNil(recoveredObjects)
        XCTAssertEqual(recoveredObjects!.count, 2, "Doesn't have the two objects")
    }
    
    func test_03_ModelObject_02_Read_Specific() {
        _ = database.create() as TestEntity?
        let objectToFind: TestEntity = database.create()!
        let testValue = "testValue"
        objectToFind.testAttribute = testValue
        try! database.save()
        
        let recoveredObjects: [TestEntity]? = database.recover(key: "testAttribute", value: testValue)
        XCTAssertNotNil(recoveredObjects)
        XCTAssertEqual(recoveredObjects!.count, 1, "Doesn't have the object")
        XCTAssertEqual(recoveredObjects![0], objectToFind, "Not the same object")
    }

    func test_04_ModelObject_01_Delete() {
        _ = database.create() as TestEntity?
        let objectToDelete: TestEntity = database.create()!
        try! database.save()
        
        let recoveredObjects: [TestEntity]? = database.recover()
        XCTAssertNotNil(recoveredObjects)
        XCTAssertEqual(recoveredObjects!.count, 2, "Doesn't have the two objects")
        
        let result = database.delete(objectToDelete)
        XCTAssertTrue(result)
        try! database.save()
        
        let newRecoveredObjects: [TestEntity]? = database.recover()
        XCTAssertNotNil(newRecoveredObjects)
        XCTAssertEqual(newRecoveredObjects!.count, 1, "Should have only one object")
    }

    func test_05_RecoverContext() {
        XCTAssertNotNil(database.getContext())
    }
    
    func test_99_Performance() {
        self.measure {
            self.test_01_Create_01_Single()
            self.test_01_Create_02_Multi()
            self.test_01_Create_03_Repeated()
            self.test_02_ModelObject_01_Create()
            self.test_02_ModelObject_02_CreateAndSave()
            self.test_02_ModelObject_03_Create_Multi()
        }
    }
}
