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
    private var databaseAPI: CoreDataAPI!
    private var databaseImplementation: CoreDataManager!
    private var testModelURL: URL!
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        testModelURL = testBundle.url(forResource: "TestModel", withExtension:"momd")
        let databaseBuilder = CoreDataBuilder(databaseName: testDatabaseName, bundle: testBundle, modelURL: testModelURL)
        databaseAPI = try! DatabaseFactory.initialize(databaseBuilder) as CoreDataAPI
        databaseImplementation = databaseAPI.coreDataInstance as! CoreDataManager
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        try? databaseImplementation.deleteAllCoreData()
        databaseImplementation.cleanUpAll()
        super.tearDown()
    }
    
    func test_01_Initialize_01_Single() {
        XCTAssertNotNil(databaseAPI)
        XCTAssertNotNil(databaseAPI.databaseContext)
        XCTAssertNotNil(databaseImplementation)
    }
    
    func test_01_Initialize_02_Multi() {
        let databaseBuilder = CoreDataBuilder(databaseName: testDatabaseNameTwo, bundle: testBundle, modelURL: testModelURL)
        let databaseAPITwo = try! DatabaseFactory.initialize(databaseBuilder) as CoreDataAPI
        
        XCTAssertNotNil(databaseAPI)
        XCTAssertNotNil(databaseAPI.databaseContext)
        XCTAssertNotNil(databaseImplementation)
        
        XCTAssertNotNil(databaseAPITwo)
        XCTAssertNotNil(databaseAPITwo.databaseContext)
        XCTAssertNotNil(databaseAPITwo.coreDataInstance)
        
        XCTAssertNotEqual(databaseAPITwo.databaseContext, databaseAPI.databaseContext, "Context are equals")
    }

    func test_01_Initialize_03_Repeated() {
        let databaseBuilder = CoreDataBuilder(databaseName: testDatabaseName, bundle: testBundle, modelURL: testModelURL)
        let databaseAPITwo = try! DatabaseFactory.initialize(databaseBuilder) as CoreDataAPI
        
        XCTAssertNotNil(databaseAPITwo)
        XCTAssertNotNil(databaseAPITwo.databaseContext)
        XCTAssertEqual(databaseAPITwo.databaseContext, databaseAPI.databaseContext, "Context aren't equals")
    }
    
    func test_01_Initialize_04_KO() {
        let testModelURLWrong = DatabaseHelper.getStoreUrl("TestModelWrong.momd")
        let databaseBuilderWrong = CoreDataBuilder(databaseName: testDatabaseNameTwo, bundle: testBundle, modelURL: testModelURLWrong)
        XCTAssertThrowsError(try DatabaseFactory.initialize(databaseBuilderWrong) as CoreDataAPI)
    }
    
    func test_02_ModelObject_01_Create() {
        let newObject: TestEntity? = databaseAPI.create()
        XCTAssertNotNil(newObject, "Fail to create TestEntity object")
    }
    
    func test_02_ModelObject_02_CreateAndSave() {
        _ = databaseAPI.create() as TestEntity?
        XCTAssertNoThrow(try databaseAPI.save())
    }
    
    func test_02_ModelObject_03_Create_Multi() {
        let objectOne: TestEntity = databaseAPI.create()!
        let objectTwo: TestEntity = databaseAPI.create()!
        
        XCTAssertNotEqual(objectOne, objectTwo, "The two objects are the same one")
    }

    func test_03_ModelObject_01_Read() {
        _ = databaseAPI.create() as TestEntity?
        _ = databaseAPI.create() as TestEntity?
        try! databaseAPI.save()
        
        let recoveredObjects: [TestEntity]? = databaseAPI.recover()
        XCTAssertNotNil(recoveredObjects)
        XCTAssertEqual(recoveredObjects!.count, 2, "Doesn't have the two objects")
    }
    
    func test_03_ModelObject_02_Read_Specific() {
        _ = databaseAPI.create() as TestEntity?
        let objectToFind: TestEntity = databaseAPI.create()!
        let testValue = "testValue"
        objectToFind.testAttribute = testValue
        try! databaseAPI.save()
        
        let recoveredObjects: [TestEntity]? = databaseAPI.recover(key: "testAttribute", value: testValue)
        XCTAssertNotNil(recoveredObjects)
        XCTAssertEqual(recoveredObjects!.count, 1, "Doesn't have the object")
        XCTAssertEqual(recoveredObjects![0], objectToFind, "Not the same object")
    }

    func test_04_ModelObject_01_Delete() {
        _ = databaseAPI.create() as TestEntity?
        let objectToDelete: TestEntity = databaseAPI.create()!
        try! databaseAPI.save()
        
        let recoveredObjects: [TestEntity]? = databaseAPI.recover()
        XCTAssertNotNil(recoveredObjects)
        XCTAssertEqual(recoveredObjects!.count, 2, "Doesn't have the two objects")
        
        let result = databaseAPI.delete(objectToDelete)
        XCTAssertTrue(result)
        try! databaseAPI.save()
        
        let newRecoveredObjects: [TestEntity]? = databaseAPI.recover()
        XCTAssertNotNil(newRecoveredObjects)
        XCTAssertEqual(newRecoveredObjects!.count, 1, "Should have only one object")
    }

    func test_99_Performance() {
        self.measure {
            self.test_01_Initialize_01_Single()
            self.test_01_Initialize_02_Multi()
            self.test_01_Initialize_03_Repeated()
            self.test_02_ModelObject_01_Create()
            self.test_02_ModelObject_02_CreateAndSave()
            self.test_02_ModelObject_03_Create_Multi()
        }
    }
}
