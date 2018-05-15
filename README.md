# Table of contents
- [PersistenceFramework](#persistenceframework)
- [Supported databases](#supported-databases)
- [Installation](#installation)
    + [All databases](#all-databases)
    + [Only Core Data database](#only-core-data-database)
    + [Only Realm database](#only-realm-database)
- [How to use](#how-to-use)
  * [Protocols](#protocols)
    + [DatabaseProtocol](#databaseprotocol)
    + [Updatable Protocol](#updatable-protocol)
    + [Saveable Protocol](#saveable-protocol)
  * [Builders](#builders)
    + [Core Data Builder](#core-data-builder)
    + [Realm Builder](#realm-builder)
  * [Use](#use)
    + [Common](#common)
      - [Creation](#creation)
      - [Recover](#recover)
      - [Delete](#delete)
    + [Core Data](#core-data)
      - [Save](#save)
    + [Realm](#realm)
      - [Update](#update)
    + [Custom Code](#custom-code)
- [Migrations](#migrations)
  * [Core Data](#core-data-1)
  * [Realm](#realm-1)

  
# PersistenceFramework
Framework to encapsulate persistence logic using Protocol Oriented Programming. This is an EXAMPLE framework to show how to use:

- Cocopods
- Protocol Oriented Programming
- Dependency injection
- Unit Testing

# Supported databases

- Core Data
- Realm

# Installation
Using Cocoapods, add in your Podfile:

### All databases
```
pod 'PersistenceFramework'
```

### Only Core Data database
```
pod 'PersistenceFramework/CoreData'
```

### Only Realm database
```
pod 'PersistenceFramework/Realm'
```

# How to use
To use this framework, you have to know just a few commons protocols that will be implemented for every database. This makes easy to change from one to another.

## Protocols

### DatabaseProtocol

This is the base protocol that any database must implement. The idea is to provide with the most used functionalities that a database should offer. For any other use, you can recover the database context an implement your custom code.

```swift
public protocol DatabaseProtocol {
	...
    func create<ReturnType: DatabaseObjectTypeProtocol>() -> ReturnType?
    func recover<ReturnType: DatabaseObjectTypeProtocol>(key: String, value: String) -> [ReturnType]?
    func delete(_ object: DatabaseObjectType) -> Bool
    func getContext() -> DatabaseContextType
}
```

### Updatable Protocol

Optional protocol used in Realm.

```swift
public protocol Updatable: DatabaseProtocol {
    func update<T: DatabaseObjectTypeProtocol>(_ object: T) -> Bool
}
```

### Saveable Protocol

Optional protocol used in Core Data.

```swift
public protocol Saveable: DatabaseProtocol {
    func save() throws
}
```

**REMEMBER:** This is just an example. Feel free to fork this repo and make your own framework.

## Builders

To create or recover a database, you have to use the **DatabaseBuilder** struct specific for the desired database. This struct required to be initialized with all the vital information for each case (Core Data need some differents things than Realm)

### Core Data Builder

Instantiate this struct to create a Core Data database. You can have as many as you want, in any bundle that you need. Just be sure to use a different "name" if they are in the same bundle.

The information you need to provide is:

- databaseName: String parameter with the name of the database.
- bundle: Bundle where the NSManagedObjectModel file is located, needed in case of a migration.
- modelURL: URL with the path to the NSManagedObjectModel file.

```swift
public struct CoreDataBuilder: CoreDataBuilderProtocol {
    public let databaseName: String
    public let bundle: Bundle
    public let modelURL: URL
    
    public func initialize<DatabaseTypeProtocol>() throws -> DatabaseTypeProtocol where DatabaseTypeProtocol : DatabaseProtocol {
        ...
    }
}
```

Use example:

```swift
let modelURL = Bundle.main.url(forResource: "Model", withExtension:"momd")
let databaseBuilder = CoreDataBuilder(databaseName: "CoreDataDatabaseName", bundle: Bundle.main, modelURL: modelURL)
let databaseAPI = try? databaseBuilder.initialize() as CoreDataAPI
```


### Realm Builder

Instantiate this struct to create a Realm database. You can have as many as you want, in any bundle that you need. Just be sure to use a different "name" if they are in the same bundle.

The information you need to provide is:

- databaseName: String parameter with the name of the database.
- passphrase: String with the key to encrypt the database. Cannot be an empty String.
- schemaVersion: UInt64 with the current number of version. Default value is 0. (Optional parameter)
- migrationBlock: MigrationBlock needed when the model is changed. Default is nil. (Optional parameter)

```swift
public struct RealmBuilder: RealmBuilderProtocol {
    public let databaseName: String
    public let passphrase: String
    public let schemaVersion: UInt64
    public let migrationBlock: MigrationBlock?
        
    public func initialize<DatabaseTypeProtocol>() throws -> DatabaseTypeProtocol where DatabaseTypeProtocol : DatabaseProtocol {
    	...
    }
}
```

Use example:

```swift
let databaseBuilder = RealmBuilder(databaseName: "RealmDatabaseName", passphrase: "Passphrase")
let databaseAPI = try? databaseBuilder.initialize() as RealmAPI
```

**REMEMBER:** This is just an example. Feel free to fork this repo and make your own framework.

## Use

### Common

#### Creation

Example to create a new _User_ entity:

```swift
let newObject: User? = databaseAPI.create()
```

#### Recover

Example to recover all _User_ entities:

```swift
let recoveredObjects: [User]? = databaseAPI.recover()
```

Example to recover a specific _User_ entity:

```swift
let recoveredObjects: [User]? = databaseAPI.recover(key: "id", value: objectId)
```

#### Delete

Example to delete a specific _User_ entity:

```swift
let result = databaseAPI.delete(objectToDelete)
```

### Core Data

#### Save
Custom Core Data method to save the context:

```swift
try? databaseAPI.save()
```

### Realm

#### Update
Custom Realm method to update a specific _User_ entity:

```swift
let result = databaseAPI.update(newObject)
```

### Custom Code

To make any other use of the databases, you can recover the context to use it:
```swift
let context = databaseAPI.getContext()
```

# Migrations
## Core Data
* **Lightweight migration**: just needs to initialize the database as always and the framework will migrate automatically. 
* **Heavyweight migration**: needs to create, in the same bundle of the database, a _NSMappingModel_ to do it. If needed, in the _NSMappingModel_ you can also setup a class of _NSEntityMigrationPolicy_ type and add custom logic for the migration process.

## Realm
When the model changes, you have to follow the next steps:

* Raise the schema version
* Create the migration block in the Builder struct. You can see some examples below:

```swift
migrationBlock: { migration, oldSchemaVersion in
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
            }
```