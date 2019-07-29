// Copyright © 2019 Kevin Refermat. All rights reserved.

import XCTest
import CoreData
@testable import Sticky

class NSManagedObjectContextAdditionsTests: XCTestCase {
    var contextProviderSpy: PersistentContainer.ContextProviderSpy!

    override func setUp() {
        super.setUp()

        let nsPersistentContainer = NSPersistentContainer.preloadedInMemoryDouble(for: self)
        contextProviderSpy = PersistentContainer.ContextProviderSpy(nsPersistentContainer: nsPersistentContainer)
    }

    func testThatPerformAndWaitReturnsSameValueReturnedByBlock() {
        let expected = UUID().uuidString
        let actual = contextProviderSpy.newBackgroundContext().performAndWait { _ in expected }
        XCTAssertEqual(expected, actual)
    }

    func testThatPerformAndWaitThrowsSameErrorThrownByBlock() {
        do {
            try contextProviderSpy.newBackgroundContext().performAndWait { _ in throw TestError() }
        } catch {
            guard error is TestError else { XCTFail(); return }
        }
    }

    func testThatPerformAndWaitContextSuccessfullySaves() {
        let expected = UUID().uuidString
        insertExampleEntity(uuidString: expected)

        XCTAssertNoThrow(
            try contextProviderSpy.newBackgroundContext().performAndWait { (context) in
                let actual = try context.fetch(ExampleEntity.self)
                XCTAssertEqual([expected], actual.compactMap { $0.uuidString })
            }
        )
    }

    func testThatFetchReturnsEmptyArrayWhenNoEntitiesArePersisted() {
        let expected = UUID().uuidString
        insertExampleEntity(uuidString: expected)

        XCTAssertNoThrow(
            try contextProviderSpy.newBackgroundContext().performAndWait { (context) in
                let actual = try context.fetch(ExampleEntity.self)
                XCTAssertEqual(actual.compactMap { $0.uuidString }, [expected])
            }
        )
    }

    func testThatFetchReturnsAllEntitiesWhenSingleEntityIsPersisted() {
        let expected = UUID().uuidString
        insertExampleEntity(uuidString: expected)

        XCTAssertNoThrow(
            try contextProviderSpy.newBackgroundContext().performAndWait { (context) in
                let categories = try context.fetch(ExampleEntity.self)
                XCTAssertEqual(categories.compactMap { $0.uuidString }, [expected])
            }
        )
    }

    func testThatFetchReturnsAllEntitiesWhenMultipleEntitiesArePersisted() {
        let expected = Set([0..<5].map { _ in UUID().uuidString })
        expected.forEach { insertExampleEntity(uuidString: $0) }

        XCTAssertNoThrow(
            try contextProviderSpy.newBackgroundContext().performAndWait { (context) in
                let categories = try context.fetch(ExampleEntity.self)
                XCTAssertEqual(Set(categories.compactMap { $0.uuidString }), expected)
            }
        )
    }

    func testThatFetchReturnsEntitiesSortedByNameWhenFetchRequestCustomizedWithSortDescriptor() {
        let expected = [0..<5].map({ _ in UUID().uuidString }).sorted()
        expected.forEach { insertExampleEntity(uuidString: $0) }

        XCTAssertNoThrow(
            try contextProviderSpy.newBackgroundContext().performAndWait { (context) in
                let categories = try context.fetch(ExampleEntity.self) { (request) in
                    request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
                }
                XCTAssertEqual(categories.compactMap { $0.uuidString }, expected)
            }
        )
    }

    func testThatErrorIsThrownWhenFetchIsCalledBeforePersistentStoreIsSet() {
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)

        XCTAssertThrowsError(
            try context.performAndWait { (context) in
                let _ = try context.fetch(ExampleEntity.self)
            }
        )
    }

    func testThatErrorIsThrownWhenFetchIsCalledOnAnNSManagedObjectThatIsNotAssociatedWithAnEntityInTheContextsModel() {
        final class TestManagedObject: NSManagedObject {}

        XCTAssertThrowsError(
            try contextProviderSpy.newBackgroundContext().performAndWait { (context) in
                let _ = try context.fetch(TestManagedObject.self)
            }
        )
    }

    func testThatCreateProducesAnObjectThatSavesSuccessfully() {
        let expectedUUIDString = UUID().uuidString
        XCTAssertNoThrow(
            try contextProviderSpy.newBackgroundContext().performAndWait { (context) in
                let newExampleEntity = try context.create(ExampleEntity.self)
                newExampleEntity.uuidString = expectedUUIDString
                try context.save()
            }
        )

        XCTAssertNoThrow(
            try contextProviderSpy.newBackgroundContext().performAndWait { (context) in
                let exampleEntities = try context.fetch(ExampleEntity.self)
                let actual = exampleEntities.compactMap { $0.uuidString }
                XCTAssertEqual([expectedUUIDString], actual)
            }
        )
    }

    func testThatCreateThrowsErrorWhenContextModelDoesNotClaimEntity() {
        final class OrphanManagedObject: NSManagedObject {}

        XCTAssertThrowsError(
            try contextProviderSpy.newBackgroundContext().performAndWait { (context) in
                try OrphanManagedObject(context)
            }
        )
    }

    func insertExampleEntity(uuidString: String) {
        XCTAssertNoThrow(
            try contextProviderSpy.newBackgroundContext().performAndWait { (context) in
                let exampleEntity = try ExampleEntity(context)
                exampleEntity.uuidString = uuidString
                try context.save()
            }
        )
    }
}


