# Table of contents
- [PersistenceFramework](#persistenceframework)
- [Supported databases](#supported-databases)
- [Installation](#installation)
  * [All databases](#all-databases)
  * [Only Core Data database](#only-core-data-database)
  * [Only Realm database](#only-realm-database)
- [API](#api)
  * [Core Data](#core-data)
  * [Realm](#realm)
- [Migrations](#migrations)
  * [Core Data](#core-data-1)
  * [Realm](#realm-1)

# PersistenceFramework
Framework to encapsulate persistence logic.

# Supported databases
* Core Data
* Realm

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

# API
## Core Data

> Constructor for Core Data database.

```swift
@available(iOS, message: "This function is only available for iOS.")
public func CoreDataManagerInit(databaseName: String, bundle: Bundle = Bundle.main, modelURL: URL)
```
 
 - Important:
 This method **must** be called once, before attempting to use the database.
 
 - parameters:
    - databaseName: Name to identify the database in the bundle.
    - bundle: The bundle of the database. Optional, default is _Bundle.main_.
    - modelURL: Path URL to the data model.
 
 - throws:
 NSError with the description of the problem.
 
---
> Recover the specific context for the requested database.
 
```swift
@available(iOS, message: "This function is only available for iOS.")
public func CoreDataManager_getContext(databaseName: String, forBundle bundle: Bundle = Bundle.main) -> NSManagedObjectContext? 
```
 - returns:
 Core Data context to use the database. Can be nil.
 
 - parameters:
     - databaseName: Name to identify the database in the bundle.
     - bundle: The bundle of the database. Optional, default is _Bundle.main_.
 

---
> Save the context for the requested database.

```swift
@available(iOS, message: "This function is only available for iOS.")
public func CoreDataManager_saveContext(databaseName: String, forBundle bundle: Bundle = Bundle.main) throws
```
 - parameters:
     - databaseName: Name to identify the database in the bundle.
     - bundle: The bundle of the database. Optional, default is _Bundle.main_.
 
 - throws:
 NSError with the description of the problem.

---
> Remove the context instance generated in the constructor method for the requested database.

```swift
@available(iOS, message: "This function is only available for iOS.")
public func CoreDataManager_cleanUp(databaseName: String, forBundle bundle: Bundle = Bundle.main)
``` 
 - Important:
 Use this method to avoid future uses of the database in the current life cycle of the app.
 
 - parameters:
     - databaseName: Name to identify the database in the bundle.
     - bundle: The bundle of the database. Optional, default is _Bundle.main_.
 
---
> Remove all context instances generated in the constructor method.

```swift
@available(iOS, message: "This function is only available for iOS.")
public func CoreDataManager_cleanUpAll()
```
 - Important:
 Use this method to avoid future uses of any Core Data database in the current life cycle of the app.
 
---
> Delete all databases files from sandbox.

```swift
@available(iOS, message: "This function is only available for iOS.")
public func CoreDataManager_deleteAllCoreData() throws
```
 - Important:
 All databases will be **deleted**. This action cannot be undone.
 
 - throws:
 NSError with the description of the problem.
 

## Realm

> Constructor for Realm database.

```swift
public func RealmManagerInit(databaseName: String, bundle: Bundle, passphrase: String, schemaVersion: UInt64 = 0, migrationBlock: MigrationBlock? = nil) throws 
``` 
 - Important:
 This method **must** be called once, before attempting to use the database.
 
 - parameters:
     - databaseName: Name to identify the database in the bundle.
     - bundle: The bundle of the database. Optional, default is _Bundle.main_.
     - passphrase: Passphrase to encrypt the database. Cannot be an empty String.
     - schemaVersion: Current schema version. Optional, default is 0.
     - migrationBlock: Closure with the logic to migrate the model. Optional, default is _nil_.
 
 - throws:
 NSError with the description of the problem.

---
> Recover the specific context for the requested database.

```swift
public func RealmManager_getRealm(databaseName: String, forBundle bundle: Bundle) -> Realm?
```
 - parameters:
     - databaseName: Name to identify the database in the bundle.
     - bundle: The bundle of the database. Optional, default is _Bundle.main_.
 
 - returns:
 Realm object to use the database. Can be nil.
 
---
> Remove the context instance generated in the constructor method for the requested database.

```swift
public func RealmManager_cleanUp(databaseName: String, forBundle bundle: Bundle) 
``` 
 - Important:
 Use this method to avoid future uses of the database in the current life cycle of the app.
 
 - parameters:
     - databaseName: Name to identify the database in the bundle.
     - bundle: The bundle of the database. Optional, default is _Bundle.main_.
 
---
> Remove all context instances generated in the constructor method.

```swift
public func RealmManager_cleanUpAll()
``` 
 - Important:
 Use this method to avoid future uses of any Core Data database in the current life cycle of the app.
 
---
> Delete all databases files from sandbox.

```swift
public func RealmManager_deleteAllRealm() throws
```
 - Important:
 All databases will be **deleted**. This action cannot be undone.
 
 - throws:
 NSError with the description of the problem.

# Migrations
## Core Data
* **Lightweight migration**: just needs to initialize the database as always and the framework will migrate automatically. 
* **Heavyweight migration**: needs to create, in the same bundle of the database, a _NSMappingModel_ to do it. If needed, in the _NSMappingModel_ you can also setup a class of _NSEntityMigrationPolicy_ type and add custom logic for the migration process.

## Realm
When the model changes, you have to follow the next steps:

* Raise the schema version
* Create the migration block. You can see some examples below:

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