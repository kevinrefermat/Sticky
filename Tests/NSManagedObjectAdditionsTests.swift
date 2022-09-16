// Copyright © 2022 Kevin Refermat. All rights reserved.

import XCTest
import CoreData
@testable import Sticky

class NSManagedObjectAdditionsTests: XCTestCase {
    var nsPersistentContainer: NSPersistentContainer!

    override func setUp() {
        super.setUp()

        nsPersistentContainer = NSPersistentContainer.preloadedInMemoryDouble(name: "NSManagedObjectAdditionsTestsDB", managedObjectModel: .singleEntityModel)
    }

    func testThatInitializerProducesAnObjectThatSavesSuccessfully() {
        let expectedUUIDString = UUID().uuidString
        XCTAssertNoThrow(
            try nsPersistentContainer.viewContext.performAndWait { (context) in
                let newExampleEntity = try ExampleEntity(context)
                try newExampleEntity.setValue(expectedUUIDString, atKeyPath: \ExampleEntity.uuidString)
                try context.save()
            }
        )

        XCTAssertNoThrow(
            try nsPersistentContainer.viewContext.performAndWait { (context) in
                let exampleEntities = try context.fetch(ExampleEntity.self)
                let actual = exampleEntities.compactMap { $0.uuidString }
                XCTAssertEqual([expectedUUIDString], actual)
            }
        )
    }

    func testThatInitializerThrowsErrorWhenContextModelDoesNotClaimEntity() {
        final class OrphanManagedObject: NSManagedObject {}

        XCTAssertThrowsError(
            try nsPersistentContainer.viewContext.performAndWait { (context) in
                try OrphanManagedObject(context)
            }
        )
    }
}
